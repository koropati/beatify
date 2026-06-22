import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;
import 'package:mockito/mockito.dart';
import 'package:flutter_app/features/music_player/domain/entities/local_song_override_entity.dart';
import 'package:flutter_app/features/music_player/domain/entities/song_entity.dart';
import 'package:flutter_app/features/music_player/presentation/providers/music_providers.dart';
import '../../../../mocks.mocks.dart';

void main() {
  late MockMusicRepositoryImpl mockRepo;

  final onlineSongs = [
    SongEntity(
      id: '1',
      title: 'Online Song',
      artist: 'Artist A',
      duration: 240,
      uri: 'http://localhost:8000/api/songs/stream/1',
      isLocal: false,
    ),
    SongEntity(
      id: '2',
      title: 'Another Song',
      artist: 'Artist B',
      duration: 180,
      uri: 'http://localhost:8000/api/songs/stream/2',
      isLocal: false,
    ),
  ];

  final localSongs = [
    SongEntity(
      id: '10',
      title: 'Local Track',
      artist: 'Me',
      duration: 200,
      uri: '/storage/emulated/0/Music/local.mp3',
      isLocal: true,
    ),
  ];

  setUp(() {
    mockRepo = MockMusicRepositoryImpl();
  });

  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        musicRepositoryProvider.overrideWithValue(mockRepo),
      ]);

  group('onlineSongsProvider', () {
    test('returns list of songs on success', () async {
      when(mockRepo.getOnlineSongs()).thenAnswer((_) async => Right(onlineSongs));

      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(onlineSongsProvider.future);

      expect(result.length, 2);
      expect(result.first.title, 'Online Song');
      expect(result.first.isLocal, false);
    });

    test('returns empty list when no songs', () async {
      when(mockRepo.getOnlineSongs()).thenAnswer((_) async => Right([]));

      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(onlineSongsProvider.future);

      expect(result, isEmpty);
    });

    test('throws exception when repository returns Left', () async {
      when(mockRepo.getOnlineSongs())
          .thenAnswer((_) async => Left(Exception('Network error')));

      final container = makeContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(onlineSongsProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('provider state is AsyncLoading initially', () {
      when(mockRepo.getOnlineSongs()).thenAnswer((_) async => Right(onlineSongs));

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(onlineSongsProvider);
      expect(state, isA<AsyncLoading>());
    });

    test('provider state is AsyncData after fetch', () async {
      when(mockRepo.getOnlineSongs()).thenAnswer((_) async => Right(onlineSongs));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(onlineSongsProvider.future);

      final state = container.read(onlineSongsProvider);
      expect(state, isA<AsyncData<List<SongEntity>>>());
    });
  });

  group('localSongsProvider', () {
    test('returns list of local songs on success', () async {
      when(mockRepo.getLocalSongs()).thenAnswer((_) async => Right(localSongs));

      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(localSongsProvider.future);

      expect(result.length, 1);
      expect(result.first.isLocal, true);
      expect(result.first.uri, contains('/storage'));
    });

    test('throws exception on permission denied', () async {
      when(mockRepo.getLocalSongs())
          .thenAnswer((_) async => Left(Exception('Permission denied')));

      final container = makeContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(localSongsProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('localSongOverridesProvider', () {
    test('returns overrides on success', () async {
      when(mockRepo.getLocalSongOverrides()).thenAnswer(
          (_) async => const Right([LocalSongOverrideEntity(songId: '10', title: 'T')]));

      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(localSongOverridesProvider.future);

      expect(result.length, 1);
      expect(result.first.songId, '10');
    });

    test('throws when repository returns Left', () async {
      when(mockRepo.getLocalSongOverrides())
          .thenAnswer((_) async => Left(Exception('db error')));

      final container = makeContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(localSongOverridesProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('knownArtistsProvider', () {
    test('returns empty list while songs not loaded yet', () {
      when(mockRepo.getLocalSongs()).thenAnswer((_) async => Right(localSongs));
      when(mockRepo.getOnlineSongs()).thenAnswer((_) async => Right(onlineSongs));

      final container = makeContainer();
      addTearDown(container.dispose);

      // Belum di-await: kedua FutureProvider masih loading → daftar kosong.
      expect(container.read(knownArtistsProvider), isEmpty);
    });

    test('merges local & online artists, deduped case-insensitively & sorted',
        () async {
      when(mockRepo.getLocalSongs()).thenAnswer((_) async => Right([
            SongEntity(
                id: '10',
                title: 'L1',
                artist: 'Tulus',
                duration: 1,
                uri: 'a',
                isLocal: true),
            SongEntity(
                id: '11',
                title: 'L2',
                artist: 'tulus', // duplikat beda kapital
                duration: 1,
                uri: 'b',
                isLocal: true),
            SongEntity(
                id: '12',
                title: 'L3',
                artist: '   ', // kosong → diabaikan
                duration: 1,
                uri: 'c',
                isLocal: true),
          ]));
      when(mockRepo.getOnlineSongs()).thenAnswer((_) async => Right([
            SongEntity(
                id: '1',
                title: 'O1',
                artist: 'Adele',
                duration: 1,
                uri: 'd',
                isLocal: false),
            SongEntity(
                id: '2',
                title: 'O2',
                artist: 'Tulus', // duplikat dengan lokal
                duration: 1,
                uri: 'e',
                isLocal: false),
          ]));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(localSongsProvider.future);
      await container.read(onlineSongsProvider.future);

      final artists = container.read(knownArtistsProvider);

      expect(artists, ['Adele', 'Tulus']);
    });

    test('falls back to local artists when online songs fail to load', () async {
      when(mockRepo.getLocalSongs()).thenAnswer((_) async => Right(localSongs));
      when(mockRepo.getOnlineSongs())
          .thenAnswer((_) async => Left(Exception('offline')));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(localSongsProvider.future);
      await expectLater(
        container.read(onlineSongsProvider.future),
        throwsA(isA<Exception>()),
      );

      expect(container.read(knownArtistsProvider), ['Me']);
    });
  });

  group('applySongMetadataUpdateProvider', () {
    SongEntity makeSong(String id, String title) => SongEntity(
          id: id,
          title: title,
          artist: 'Old Artist',
          duration: 100,
          uri: '/x/$id.mp3',
          isLocal: true,
        );

    test('updates current song when ids match', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(currentSongProvider.notifier).state = makeSong('10', 'Old');

      final updated = makeSong('10', 'New Title');
      container.read(applySongMetadataUpdateProvider)(updated);

      expect(container.read(currentSongProvider)?.title, 'New Title');
    });

    test('leaves current song untouched when ids differ', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(currentSongProvider.notifier).state = makeSong('10', 'Old');

      container.read(applySongMetadataUpdateProvider)(makeSong('99', 'Other'));

      expect(container.read(currentSongProvider)?.title, 'Old');
    });

    test('replaces matching entry in the queue', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(queueProvider.notifier).state = [
        makeSong('10', 'Old'),
        makeSong('11', 'Keep'),
      ];

      container.read(applySongMetadataUpdateProvider)(makeSong('10', 'New'));

      final queue = container.read(queueProvider);
      expect(queue[0].title, 'New');
      expect(queue[1].title, 'Keep');
    });

    test('does not touch queue when no entry matches', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final original = [makeSong('10', 'Old')];
      container.read(queueProvider.notifier).state = original;

      container.read(applySongMetadataUpdateProvider)(makeSong('99', 'X'));

      expect(identical(container.read(queueProvider), original), true);
    });
  });

  group('currentSongProvider', () {
    test('initial state is null', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(container.read(currentSongProvider), isNull);
    });

    test('can be updated to a song', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final song = onlineSongs.first;
      container.read(currentSongProvider.notifier).state = song;

      expect(container.read(currentSongProvider)?.title, 'Online Song');
    });

    test('can be reset to null', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(currentSongProvider.notifier).state = onlineSongs.first;
      container.read(currentSongProvider.notifier).state = null;

      expect(container.read(currentSongProvider), isNull);
    });
  });

  group('provider wiring & state providers', () {
    test('core providers can be constructed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(dioProvider), isNotNull);
      expect(container.read(remoteDataSourceProvider), isNotNull);
      expect(container.read(localDataSourceProvider), isNotNull);
      expect(container.read(localSongOverrideDataSourceProvider), isNotNull);
      expect(container.read(musicRepositoryProvider), isNotNull);
      expect(container.read(getOnlineSongsUseCaseProvider), isNotNull);
      expect(container.read(getLocalSongsUseCaseProvider), isNotNull);
      expect(container.read(getLocalSongOverridesUseCaseProvider), isNotNull);
      expect(container.read(updateLocalSongMetadataUseCaseProvider), isNotNull);
      expect(container.read(uploadLocalSongToPublicUseCaseProvider), isNotNull);
      expect(container.read(isLocalSongPublishedProvider), isNotNull);
    });

    test('state providers expose defaults and can update', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(queueProvider), isEmpty);
      expect(container.read(queueIndexProvider), 0);
      expect(container.read(shuffleModeProvider), false);
      expect(container.read(repeatModeProvider), LoopMode.off);
      expect(container.read(playbackErrorProvider), isNull);

      container.read(queueProvider.notifier).state = onlineSongs;
      container.read(queueIndexProvider.notifier).state = 1;
      container.read(shuffleModeProvider.notifier).state = true;
      container.read(repeatModeProvider.notifier).state = LoopMode.all;
      container.read(playbackErrorProvider.notifier).state = 'err';

      expect(container.read(queueProvider).length, 2);
      expect(container.read(queueIndexProvider), 1);
      expect(container.read(shuffleModeProvider), true);
      expect(container.read(repeatModeProvider), LoopMode.all);
      expect(container.read(playbackErrorProvider), 'err');
    });
  });

  group('isPlayingProvider', () {
    test('initial state is false', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(container.read(isPlayingProvider), false);
    });

    test('can be set to true', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(isPlayingProvider.notifier).state = true;

      expect(container.read(isPlayingProvider), true);
    });

    test('can be toggled back to false', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(isPlayingProvider.notifier).state = true;
      container.read(isPlayingProvider.notifier).state = false;

      expect(container.read(isPlayingProvider), false);
    });
  });
}
