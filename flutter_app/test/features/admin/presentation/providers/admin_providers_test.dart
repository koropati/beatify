import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_app/features/admin/presentation/providers/admin_providers.dart';
import 'package:flutter_app/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_app/features/music_player/domain/entities/song_entity.dart';
import '../../../../mocks.mocks.dart';

void main() {
  late MockAdminRepositoryImpl mockRepo;

  final user = UserEntity(
    id: 1, username: 'u', email: 'u@test.com', role: 'user', isVerified: false,
  );
  final song = SongEntity(
    id: '1', title: 'T', artist: 'A', duration: 100, uri: 'http://x/1', isLocal: false,
  );

  setUp(() {
    mockRepo = MockAdminRepositoryImpl();
  });

  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        adminRepositoryProvider.overrideWithValue(mockRepo),
      ]);

  group('allUsersProvider', () {
    test('returns users on success', () async {
      when(mockRepo.getAllUsers()).thenAnswer((_) async => Right([user]));
      final container = makeContainer();
      addTearDown(container.dispose);
      final result = await container.read(allUsersProvider.future);
      expect(result.single.username, 'u');
    });

    test('throws on failure', () async {
      when(mockRepo.getAllUsers()).thenAnswer((_) async => Left(Exception('boom')));
      final container = makeContainer();
      addTearDown(container.dispose);
      expect(() => container.read(allUsersProvider.future), throwsA(isA<Exception>()));
    });
  });

  group('unverifiedUsersProvider', () {
    test('returns users on success', () async {
      when(mockRepo.getUnverifiedUsers()).thenAnswer((_) async => Right([user]));
      final container = makeContainer();
      addTearDown(container.dispose);
      final result = await container.read(unverifiedUsersProvider.future);
      expect(result.length, 1);
    });

    test('throws on failure', () async {
      when(mockRepo.getUnverifiedUsers()).thenAnswer((_) async => Left(Exception('boom')));
      final container = makeContainer();
      addTearDown(container.dispose);
      expect(() => container.read(unverifiedUsersProvider.future), throwsA(isA<Exception>()));
    });
  });

  group('allSongsAdminProvider', () {
    test('returns songs on success', () async {
      when(mockRepo.getAllSongs()).thenAnswer((_) async => Right([song]));
      final container = makeContainer();
      addTearDown(container.dispose);
      final result = await container.read(allSongsAdminProvider.future);
      expect(result.single.id, '1');
    });

    test('throws on failure', () async {
      when(mockRepo.getAllSongs()).thenAnswer((_) async => Left(Exception('boom')));
      final container = makeContainer();
      addTearDown(container.dispose);
      expect(() => container.read(allSongsAdminProvider.future), throwsA(isA<Exception>()));
    });
  });

  group('provider wiring', () {
    test('data source and repository build', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(adminRemoteDataSourceProvider), isNotNull);
      expect(container.read(adminRepositoryProvider), isNotNull);
    });
  });
}
