import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_app/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:flutter_app/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_app/features/music_player/domain/entities/song_entity.dart';
import '../../../../mocks.mocks.dart';

void main() {
  late MockAdminRemoteDataSource mockRemote;
  late AdminRepositoryImpl repo;

  final user = UserEntity(
    id: 1, username: 'u', email: 'u@test.com', role: 'user', isVerified: false,
  );
  final song = SongEntity(
    id: '1', title: 'T', artist: 'A', duration: 100, uri: 'http://x/1', isLocal: false,
  );

  setUp(() {
    mockRemote = MockAdminRemoteDataSource();
    repo = AdminRepositoryImpl(remoteDataSource: mockRemote);
  });

  group('getAllUsers', () {
    test('Right on success', () async {
      when(mockRemote.getAllUsers()).thenAnswer((_) async => [user]);
      expect((await repo.getAllUsers()).isRight(), true);
    });
    test('Left on error', () async {
      when(mockRemote.getAllUsers()).thenThrow(Exception('x'));
      expect((await repo.getAllUsers()).isLeft(), true);
    });
  });

  group('getUnverifiedUsers', () {
    test('Right on success', () async {
      when(mockRemote.getUnverifiedUsers()).thenAnswer((_) async => [user]);
      expect((await repo.getUnverifiedUsers()).isRight(), true);
    });
    test('Left on error', () async {
      when(mockRemote.getUnverifiedUsers()).thenThrow(Exception('x'));
      expect((await repo.getUnverifiedUsers()).isLeft(), true);
    });
  });

  group('verifyUser', () {
    test('Right on success', () async {
      when(mockRemote.verifyUser(any)).thenAnswer((_) async => user);
      expect((await repo.verifyUser(1)).isRight(), true);
    });
    test('Left on error', () async {
      when(mockRemote.verifyUser(any)).thenThrow(Exception('x'));
      expect((await repo.verifyUser(1)).isLeft(), true);
    });
  });

  group('updateUser', () {
    test('Right on success and forwards args', () async {
      when(mockRemote.updateUser(any,
              username: anyNamed('username'),
              email: anyNamed('email'),
              role: anyNamed('role'),
              isVerified: anyNamed('isVerified')))
          .thenAnswer((_) async => user);
      final result = await repo.updateUser(1, username: 'n', email: 'e@t.com', role: 'admin', isVerified: true);
      expect(result.isRight(), true);
      verify(mockRemote.updateUser(1, username: 'n', email: 'e@t.com', role: 'admin', isVerified: true)).called(1);
    });
    test('Left on error', () async {
      when(mockRemote.updateUser(any,
              username: anyNamed('username'),
              email: anyNamed('email'),
              role: anyNamed('role'),
              isVerified: anyNamed('isVerified')))
          .thenThrow(Exception('x'));
      expect((await repo.updateUser(1, username: 'n')).isLeft(), true);
    });
  });

  group('getAllSongs', () {
    test('Right on success', () async {
      when(mockRemote.getAllSongs()).thenAnswer((_) async => [song]);
      expect((await repo.getAllSongs()).isRight(), true);
    });
    test('Left on error', () async {
      when(mockRemote.getAllSongs()).thenThrow(Exception('x'));
      expect((await repo.getAllSongs()).isLeft(), true);
    });
  });

  group('updateSong', () {
    test('Right on success and forwards args', () async {
      when(mockRemote.updateSong(any,
              title: anyNamed('title'),
              artist: anyNamed('artist'),
              album: anyNamed('album')))
          .thenAnswer((_) async => song);
      final result = await repo.updateSong(1, title: 'T', artist: 'A', album: 'Al');
      expect(result.isRight(), true);
      verify(mockRemote.updateSong(1, title: 'T', artist: 'A', album: 'Al')).called(1);
    });
    test('Left on error', () async {
      when(mockRemote.updateSong(any,
              title: anyNamed('title'),
              artist: anyNamed('artist'),
              album: anyNamed('album')))
          .thenThrow(Exception('x'));
      expect((await repo.updateSong(1, title: 'T')).isLeft(), true);
    });
  });

  group('deleteSong', () {
    test('Right on success', () async {
      when(mockRemote.deleteSong(any)).thenAnswer((_) async {});
      expect((await repo.deleteSong(1)).isRight(), true);
    });
    test('Left on error', () async {
      when(mockRemote.deleteSong(any)).thenThrow(Exception('x'));
      expect((await repo.deleteSong(1)).isLeft(), true);
    });
  });
}
