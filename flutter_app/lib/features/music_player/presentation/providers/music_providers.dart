import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../domain/entities/song_entity.dart';
import '../../data/datasources/music_remote_data_source.dart';
import '../../data/datasources/music_local_data_source.dart';
import '../../data/repositories/music_repository_impl.dart';
import '../../domain/usecases/get_online_songs.dart';
import '../../domain/usecases/get_local_songs.dart';

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
  return dio;
});
final audioPlayerProvider = Provider<AudioPlayer>((ref) => AudioPlayer());

// --- Data Sources ---
final remoteDataSourceProvider = Provider<MusicRemoteDataSource>((ref) {
  return MusicRemoteDataSourceImpl(dio: ref.read(dioProvider));
});

final localDataSourceProvider = Provider<MusicLocalDataSource>((ref) {
  return MusicLocalDataSourceImpl();
});

// --- Repository ---
final musicRepositoryProvider = Provider<MusicRepositoryImpl>((ref) {
  return MusicRepositoryImpl(
    remoteDataSource: ref.read(remoteDataSourceProvider),
    localDataSource: ref.read(localDataSourceProvider),
  );
});

// --- Use Cases ---
final getOnlineSongsUseCaseProvider = Provider<GetOnlineSongs>((ref) {
  return GetOnlineSongs(ref.read(musicRepositoryProvider));
});

final getLocalSongsUseCaseProvider = Provider<GetLocalSongs>((ref) {
  return GetLocalSongs(ref.read(musicRepositoryProvider));
});

// --- State Providers ---

final onlineSongsProvider = FutureProvider<List<SongEntity>>((ref) async {
  final usecase = ref.read(getOnlineSongsUseCaseProvider);
  final result = await usecase.execute();
  return result.fold(
    (failure) => throw failure,
    (songs) => songs,
  );
});

final localSongsProvider = FutureProvider<List<SongEntity>>((ref) async {
  final usecase = ref.read(getLocalSongsUseCaseProvider);
  final result = await usecase.execute();
  return result.fold(
    (failure) => throw failure,
    (songs) => songs,
  );
});

// --- Audio Player State ---
final currentSongProvider = StateProvider<SongEntity?>((ref) => null);
final isPlayingProvider = StateProvider<bool>((ref) => false);

class AudioPlayerController {
  final AudioPlayer _player;
  final Ref _ref;

  AudioPlayerController(this._player, this._ref) {
    _player.playerStateStream.listen((state) {
      _ref.read(isPlayingProvider.notifier).state = state.playing;
    });
  }

  Future<void> playSong(SongEntity song) async {
    try {
      if (song.isLocal) {
        await _player.setFilePath(song.uri);
      } else {
        await _player.setUrl(song.uri);
      }
      _ref.read(currentSongProvider.notifier).state = song;
      await _player.play();
    } catch (e) {
      print("Error playing audio: \$e");
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }
}

final audioPlayerControllerProvider = Provider<AudioPlayerController>((ref) {
  return AudioPlayerController(ref.read(audioPlayerProvider), ref);
});
