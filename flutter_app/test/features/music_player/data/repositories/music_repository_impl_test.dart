import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_app/features/music_player/data/models/song_model.dart';
import 'package:flutter_app/features/music_player/data/repositories/music_repository_impl.dart';
import '../../../../mocks.mocks.dart';

void main() {
  late MockMusicRemoteDataSource mockRemote;
  late MockMusicLocalDataSource mockLocal;
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
      duration: 180,
      uri: '/storage/music/local.mp3',
      isLocal: true,
    ),
  ];

  setUp(() {
    mockRemote = MockMusicRemoteDataSource();
    mockLocal = MockMusicLocalDataSource();
    repository = MusicRepositoryImpl(
      remoteDataSource: mockRemote,
      localDataSource: mockLocal,
    );
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
    test('success returns Right(List<SongEntity>)', () async {
      when(mockLocal.getLocalSongs()).thenAnswer((_) async => localSongs);

      final result = await repository.getLocalSongs();

      expect(result.isRight(), true);
      result.fold((_) => fail('expected Right'), (songs) {
        expect(songs.length, 1);
        expect(songs.first.title, 'Local Song');
        expect(songs.first.isLocal, true);
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
}
