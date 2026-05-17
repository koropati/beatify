import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
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
