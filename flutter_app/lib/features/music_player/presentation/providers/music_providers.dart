import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/entities/local_song_override_entity.dart';
import '../../data/datasources/music_remote_data_source.dart';
import '../../data/datasources/music_local_data_source.dart';
import '../../data/datasources/local_song_override_data_source.dart';
import '../../data/repositories/music_repository_impl.dart';
import '../../domain/usecases/get_online_songs.dart';
import '../../domain/usecases/get_local_songs.dart';
import '../../domain/usecases/get_local_song_overrides.dart';
import '../../domain/usecases/update_local_song_metadata.dart';
import '../../domain/usecases/upload_local_song_to_public.dart';
import '../../domain/usecases/is_local_song_published.dart';

import '../../../../core/network/auth_interceptor.dart';
import '../../../../core/config/app_config.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

// --- Core ---
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));
  dio.interceptors.add(AuthInterceptor(ref.read(secureStorageProvider)));
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  return dio;
});

// coverage:ignore-start
final audioPlayerProvider = Provider<AudioPlayer>((ref) => AudioPlayer());
// coverage:ignore-end

// --- Data Sources ---
final remoteDataSourceProvider = Provider<MusicRemoteDataSource>((ref) {
  return MusicRemoteDataSourceImpl(dio: ref.read(dioProvider));
});

final localDataSourceProvider = Provider<MusicLocalDataSource>((ref) {
  return MusicLocalDataSourceImpl();
});

final localSongOverrideDataSourceProvider =
    Provider<LocalSongOverrideDataSource>((ref) {
  return LocalSongOverrideDataSourceImpl();
});

// --- Repository ---
final musicRepositoryProvider = Provider<MusicRepositoryImpl>((ref) {
  return MusicRepositoryImpl(
    remoteDataSource: ref.read(remoteDataSourceProvider),
    localDataSource: ref.read(localDataSourceProvider),
    overrideDataSource: ref.read(localSongOverrideDataSourceProvider),
  );
});

// --- Use Cases ---
final getOnlineSongsUseCaseProvider = Provider<GetOnlineSongs>((ref) {
  return GetOnlineSongs(ref.read(musicRepositoryProvider));
});

final getLocalSongsUseCaseProvider = Provider<GetLocalSongs>((ref) {
  return GetLocalSongs(ref.read(musicRepositoryProvider));
});

final getLocalSongOverridesUseCaseProvider =
    Provider<GetLocalSongOverrides>((ref) {
  return GetLocalSongOverrides(ref.read(musicRepositoryProvider));
});

final updateLocalSongMetadataUseCaseProvider =
    Provider<UpdateLocalSongMetadata>((ref) {
  return UpdateLocalSongMetadata(ref.read(musicRepositoryProvider));
});

final uploadLocalSongToPublicUseCaseProvider =
    Provider<UploadLocalSongToPublic>((ref) {
  return UploadLocalSongToPublic(ref.read(musicRepositoryProvider));
});

final isLocalSongPublishedProvider = Provider<IsLocalSongPublished>((ref) {
  return IsLocalSongPublished();
});

// --- State Providers ---
final onlineSongsProvider = FutureProvider<List<SongEntity>>((ref) async {
  final result = await ref.read(getOnlineSongsUseCaseProvider).execute();
  return result.fold((failure) => throw failure, (songs) => songs);
});

final localSongsProvider = FutureProvider<List<SongEntity>>((ref) async {
  final result = await ref.read(getLocalSongsUseCaseProvider).execute();
  return result.fold((failure) => throw failure, (songs) => songs);
});

final localSongOverridesProvider =
    FutureProvider<List<LocalSongOverrideEntity>>((ref) async {
  final result = await ref.read(getLocalSongOverridesUseCaseProvider).call();
  return result.fold((failure) => throw failure, (overrides) => overrides);
});

// --- Audio Player State ---
final currentSongProvider = StateProvider<SongEntity?>((ref) => null);
final isPlayingProvider = StateProvider<bool>((ref) => false);
final queueProvider = StateProvider<List<SongEntity>>((ref) => []);
final queueIndexProvider = StateProvider<int>((ref) => 0);
final shuffleModeProvider = StateProvider<bool>((ref) => false);
final repeatModeProvider = StateProvider<LoopMode>((ref) => LoopMode.off);
final playbackErrorProvider = StateProvider<String?>((ref) => null);

// coverage:ignore-start
// Wraps just_audio AudioPlayer (platform plugin) — verified on device.
class AudioPlayerController {
  final AudioPlayer _player;
  final Ref _ref;

  AudioPlayerController(this._player, this._ref) {
    _player.playerStateStream.listen((state) {
      _ref.read(isPlayingProvider.notifier).state = state.playing;
    });
    _player.currentIndexStream.listen((index) {
      if (index == null) return;
      final queue = _ref.read(queueProvider);
      if (index < queue.length) {
        _ref.read(currentSongProvider.notifier).state = queue[index];
        _ref.read(queueIndexProvider.notifier).state = index;
      }
    });
    // Surface playback/streaming errors instead of failing silently.
    _player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) {
        debugPrint("Playback error: $e");
        _ref.read(playbackErrorProvider.notifier).state =
            "Tidak bisa memutar lagu. Periksa koneksi internet.";
      },
    );
  }

  AudioSource _buildSource(SongEntity song) {
    final uri = song.isLocal ? Uri.file(song.uri) : Uri.parse(song.uri);
    return AudioSource.uri(
      uri,
      tag: MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        artUri: song.coverImagePath != null
            ? Uri.file(song.coverImagePath!)
            : (song.coverImageUrl != null
                ? Uri.tryParse(song.coverImageUrl!)
                : null),
      ),
    );
  }

  Future<void> playQueue(List<SongEntity> songs, int startIndex) async {
    if (songs.isEmpty) return;
    try {
      _ref.read(playbackErrorProvider.notifier).state = null;
      _ref.read(queueProvider.notifier).state = songs;
      _ref.read(queueIndexProvider.notifier).state = startIndex;

      await _player.setAudioSources(
        songs.map(_buildSource).toList(),
        initialIndex: startIndex,
      );
      // Only reflect the song as "now playing" once the source actually loaded.
      _ref.read(currentSongProvider.notifier).state = songs[startIndex];
      await _player.setVolume(1.0);
      await _player.play();
    } catch (e) {
      debugPrint("Error playing queue: $e");
      _ref.read(playbackErrorProvider.notifier).state =
          "Tidak bisa memutar lagu. Periksa koneksi internet.";
    }
  }

  Future<void> playSong(SongEntity song) async {
    final queue = _ref.read(queueProvider);
    final idx = queue.indexWhere((s) => s.id == song.id);
    if (idx != -1) {
      await _player.seek(Duration.zero, index: idx);
      await _player.play();
    } else {
      await playQueue([song], 0);
    }
  }

  Future<void> skipNext() async {
    await _player.seekToNext();
  }

  Future<void> skipPrevious() async {
    await _player.seekToPrevious();
  }

  Future<void> toggleShuffle() async {
    final current = _ref.read(shuffleModeProvider);
    await _player.setShuffleModeEnabled(!current);
    _ref.read(shuffleModeProvider.notifier).state = !current;
  }

  Future<void> toggleRepeat() async {
    final current = _ref.read(repeatModeProvider);
    final next = switch (current) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      _ => LoopMode.off,
    };
    await _player.setLoopMode(next);
    _ref.read(repeatModeProvider.notifier).state = next;
  }

  Future<void> pause() async => _player.pause();
  Future<void> resume() async => _player.play();
}

final audioPlayerControllerProvider = Provider<AudioPlayerController>((ref) {
  return AudioPlayerController(ref.read(audioPlayerProvider), ref);
});
// coverage:ignore-end
