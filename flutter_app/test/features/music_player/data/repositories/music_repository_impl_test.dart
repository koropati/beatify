import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_app/features/music_player/data/models/song_model.dart';
import 'package:flutter_app/features/music_player/data/models/local_song_override_model.dart';
import 'package:flutter_app/features/music_player/data/repositories/music_repository_impl.dart';
import 'package:flutter_app/features/music_player/domain/entities/song_entity.dart';
import '../../../../mocks.mocks.dart';

void main() {
  late MockMusicRemoteDataSource mockRemote;
  late MockMusicLocalDataSource mockLocal;
  late MockLocalSongOverrideDataSource mockOverride;
  late MusicRepositoryImpl repository;

  final remoteSongs = [
    SongModel(
      id: '1',
      title: 'Online Song',
      artist: 'Artist A',
      duration: 240,
      uri: 'http://localhost:8000/api/songs/stream/1',
      isLocal: false,
    ),
  ];

  final localSongs = [
    SongModel(
      id: '10',
      title: 'Local Song',
      artist: 'Me',
      album: 'Original Album',
      duration: 180,
      uri: '/storage/music/local.mp3',
      isLocal: true,
    ),
  ];

  setUp(() {
    mockRemote = MockMusicRemoteDataSource();
    mockLocal = MockMusicLocalDataSource();
    mockOverride = MockLocalSongOverrideDataSource();
    repository = MusicRepositoryImpl(
      remoteDataSource: mockRemote,
      localDataSource: mockLocal,
      overrideDataSource: mockOverride,
    );
    // Default: no overrides unless a test states otherwise.
    when(mockOverride.getAll()).thenAnswer((_) async => []);
  });

  group('getOnlineSongs', () {
    test('success returns Right(List<SongEntity>)', () async {
      when(mockRemote.getOnlineSongs()).thenAnswer((_) async => remoteSongs);

      final result = await repository.getOnlineSongs();

      expect(result.isRight(), true);
      result.fold((_) => fail('expected Right'), (songs) {
        expect(songs.length, 1);
        expect(songs.first.title, 'Online Song');
        expect(songs.first.isLocal, false);
      });
    });

    test('empty list returns Right([])', () async {
      when(mockRemote.getOnlineSongs()).thenAnswer((_) async => []);

      final result = await repository.getOnlineSongs();

      expect(result.isRight(), true);
      result.fold((_) => fail('expected Right'), (songs) => expect(songs, isEmpty));
    });

    test('data source throws → returns Left(Exception)', () async {
      when(mockRemote.getOnlineSongs()).thenThrow(Exception('Network error'));

      final result = await repository.getOnlineSongs();

      expect(result.isLeft(), true);
    });
  });

  group('getLocalSongs', () {
    test('no override returns raw song unchanged', () async {
      when(mockLocal.getLocalSongs()).thenAnswer((_) async => localSongs);

      final result = await repository.getLocalSongs();

      expect(result.isRight(), true);
      result.fold((_) => fail('expected Right'), (songs) {
        expect(songs.length, 1);
        expect(songs.first.title, 'Local Song');
        expect(songs.first.artist, 'Me');
        expect(songs.first.album, 'Original Album');
        expect(songs.first.isLocal, true);
      });
    });

    test('applies override fields over raw song', () async {
      when(mockLocal.getLocalSongs()).thenAnswer((_) async => localSongs);
      when(mockOverride.getAll()).thenAnswer((_) async => [
            const LocalSongOverrideModel(
              songId: '10',
              title: 'Edited Title',
              artist: 'Edited Artist',
              album: 'Edited Album',
              coverImagePath: '/data/song_covers/1.jpg',
            ),
          ]);

      final result = await repository.getLocalSongs();

      result.fold((_) => fail('expected Right'), (songs) {
        expect(songs.first.title, 'Edited Title');
        expect(songs.first.artist, 'Edited Artist');
        expect(songs.first.album, 'Edited Album');
        expect(songs.first.coverImagePath, '/data/song_covers/1.jpg');
      });
    });

    test('override with null fields falls back to raw values', () async {
      when(mockLocal.getLocalSongs()).thenAnswer((_) async => localSongs);
      when(mockOverride.getAll()).thenAnswer((_) async => [
            const LocalSongOverrideModel(songId: '10', backendSongId: 5),
          ]);

      final result = await repository.getLocalSongs();

      result.fold((_) => fail('expected Right'), (songs) {
        expect(songs.first.title, 'Local Song');
        expect(songs.first.artist, 'Me');
        expect(songs.first.album, 'Original Album');
        expect(songs.first.coverImagePath, isNull);
      });
    });

    test('permission denied → returns Left(Exception)', () async {
      when(mockLocal.getLocalSongs()).thenThrow(Exception('Permission denied'));

      final result = await repository.getLocalSongs();

      expect(result.isLeft(), true);
    });

    test('empty library returns Right([])', () async {
      when(mockLocal.getLocalSongs()).thenAnswer((_) async => []);

      final result = await repository.getLocalSongs();

      expect(result.isRight(), true);
      result.fold((_) => fail('expected Right'), (songs) => expect(songs, isEmpty));
    });
  });

  group('updateLocalSongMetadata', () {
    test('success returns Right(null) and calls upsert', () async {
      when(mockOverride.upsert('10',
              title: anyNamed('title'),
              artist: anyNamed('artist'),
              album: anyNamed('album'),
              coverImagePath: anyNamed('coverImagePath')))
          .thenAnswer((_) async {});

      final result = await repository.updateLocalSongMetadata(
        '10',
        title: 'New',
        artist: 'New Artist',
      );

      expect(result.isRight(), true);
      verify(mockOverride.upsert('10',
              title: 'New',
              artist: 'New Artist',
              album: null,
              coverImagePath: null))
          .called(1);
    });

    test('data source throws → returns Left(Exception)', () async {
      when(mockOverride.upsert(any,
              title: anyNamed('title'),
              artist: anyNamed('artist'),
              album: anyNamed('album'),
              coverImagePath: anyNamed('coverImagePath')))
          .thenThrow(Exception('db error'));

      final result = await repository.updateLocalSongMetadata('10', title: 'X');

      expect(result.isLeft(), true);
    });
  });

  group('uploadLocalSongToPublic', () {
    final localSong = SongEntity(
      id: '10',
      title: 'Local Song',
      artist: 'Me',
      album: 'Album',
      duration: 180,
      uri: '/storage/music/local.mp3',
      coverImagePath: '/data/song_covers/1.jpg',
      isLocal: true,
    );

    final uploaded = SongModel(
      id: '42',
      title: 'Local Song',
      artist: 'Me',
      duration: 180,
      uri: 'http://localhost:8000/api/songs/stream/42',
      isLocal: false,
    );

    test('success records backend id and returns Right(song)', () async {
      when(mockRemote.uploadSong(
        title: anyNamed('title'),
        artist: anyNamed('artist'),
        album: anyNamed('album'),
        filePath: anyNamed('filePath'),
        coverImagePath: anyNamed('coverImagePath'),
      )).thenAnswer((_) async => uploaded);
      when(mockOverride.setBackendSongId('10', 42)).thenAnswer((_) async {});

      final result = await repository.uploadLocalSongToPublic(localSong);

      expect(result.isRight(), true);
      result.fold((_) => fail('expected Right'), (s) => expect(s.id, '42'));
      verify(mockOverride.setBackendSongId('10', 42)).called(1);
      // Falls back to the song's own cover path when none is provided.
      verify(mockRemote.uploadSong(
        title: 'Local Song',
        artist: 'Me',
        album: 'Album',
        filePath: '/storage/music/local.mp3',
        coverImagePath: '/data/song_covers/1.jpg',
      )).called(1);
    });

    test('explicit coverImagePath overrides the song cover', () async {
      when(mockRemote.uploadSong(
        title: anyNamed('title'),
        artist: anyNamed('artist'),
        album: anyNamed('album'),
        filePath: anyNamed('filePath'),
        coverImagePath: anyNamed('coverImagePath'),
      )).thenAnswer((_) async => uploaded);
      when(mockOverride.setBackendSongId(any, any)).thenAnswer((_) async {});

      await repository.uploadLocalSongToPublic(localSong,
          coverImagePath: '/tmp/new.jpg');

      verify(mockRemote.uploadSong(
        title: anyNamed('title'),
        artist: anyNamed('artist'),
        album: anyNamed('album'),
        filePath: anyNamed('filePath'),
        coverImagePath: '/tmp/new.jpg',
      )).called(1);
    });

    test('non-numeric backend id skips setBackendSongId', () async {
      final weird = SongModel(
        id: 'not-a-number',
        title: 'X',
        artist: 'Y',
        duration: 1,
        uri: 'http://x/1',
        isLocal: false,
      );
      when(mockRemote.uploadSong(
        title: anyNamed('title'),
        artist: anyNamed('artist'),
        album: anyNamed('album'),
        filePath: anyNamed('filePath'),
        coverImagePath: anyNamed('coverImagePath'),
      )).thenAnswer((_) async => weird);

      final result = await repository.uploadLocalSongToPublic(localSong);

      expect(result.isRight(), true);
      verifyNever(mockOverride.setBackendSongId(any, any));
    });

    test('remote throws → returns Left(Exception)', () async {
      when(mockRemote.uploadSong(
        title: anyNamed('title'),
        artist: anyNamed('artist'),
        album: anyNamed('album'),
        filePath: anyNamed('filePath'),
        coverImagePath: anyNamed('coverImagePath'),
      )).thenThrow(Exception('upload failed'));

      final result = await repository.uploadLocalSongToPublic(localSong);

      expect(result.isLeft(), true);
    });
  });

  group('getLocalSongOverrides', () {
    test('success returns Right(list)', () async {
      when(mockOverride.getAll()).thenAnswer((_) async => [
            const LocalSongOverrideModel(songId: '10', title: 'T'),
          ]);

      final result = await repository.getLocalSongOverrides();

      expect(result.isRight(), true);
      result.fold((_) => fail('expected Right'), (list) {
        expect(list.length, 1);
        expect(list.first.songId, '10');
      });
    });

    test('data source throws → returns Left(Exception)', () async {
      when(mockOverride.getAll()).thenThrow(Exception('db error'));

      final result = await repository.getLocalSongOverrides();

      expect(result.isLeft(), true);
    });
  });
}
