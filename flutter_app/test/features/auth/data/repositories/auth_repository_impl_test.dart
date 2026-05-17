import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_app/features/auth/domain/entities/user_entity.dart';
import '../../../../mocks.mocks.dart';

void main() {
  late MockAuthRemoteDataSource mockRemote;
  late MockSecureStorage mockStorage;
  late AuthRepositoryImpl repository;

  final testUser = UserEntity(
    id: 1,
    username: 'testuser',
    email: 'test@test.com',
    role: 'user',
    isVerified: false,
  );

  setUp(() {
    mockRemote = MockAuthRemoteDataSource();
    mockStorage = MockSecureStorage();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemote,
      secureStorage: mockStorage,
    );
  });

  group('login', () {
    test('success returns Right(token) and saves token to storage', () async {
      when(mockRemote.login(any, any)).thenAnswer((_) async => 'access_token_123');
      when(mockStorage.saveToken(any)).thenAnswer((_) async {});

      final result = await repository.login('testuser', 'password');

      expect(result.isRight(), true);
      result.fold((_) => fail('expected Right'), (t) => expect(t, 'access_token_123'));
      verify(mockStorage.saveToken('access_token_123')).called(1);
    });

    test('data source throws → returns Left(Exception)', () async {
      when(mockRemote.login(any, any)).thenThrow(Exception('Network error'));

      final result = await repository.login('testuser', 'wrong');

      expect(result.isLeft(), true);
    });

    test('does not save token when data source throws', () async {
      when(mockRemote.login(any, any)).thenThrow(Exception('fail'));

      await repository.login('testuser', 'wrong');

      verifyNever(mockStorage.saveToken(any));
    });
  });

  group('register', () {
    test('success returns Right(UserEntity)', () async {
      when(mockRemote.register(any, any, any)).thenAnswer((_) async => testUser);

      final result = await repository.register('testuser', 'test@test.com', 'password');

      expect(result.isRight(), true);
      result.fold((_) => fail('expected Right'), (u) {
        expect(u.username, 'testuser');
        expect(u.email, 'test@test.com');
      });
    });

    test('data source throws → returns Left(Exception)', () async {
      when(mockRemote.register(any, any, any))
          .thenThrow(Exception('Email already registered'));

      final result = await repository.register('testuser', 'dup@test.com', 'password');

      expect(result.isLeft(), true);
    });
  });

  group('getCurrentUser', () {
    test('success returns Right(UserEntity)', () async {
      when(mockRemote.getCurrentUser()).thenAnswer((_) async => testUser);

      final result = await repository.getCurrentUser();

      expect(result.isRight(), true);
      result.fold((_) => fail('expected Right'), (u) => expect(u.id, 1));
    });

    test('data source throws → returns Left(Exception)', () async {
      when(mockRemote.getCurrentUser()).thenThrow(Exception('Unauthorized'));

      final result = await repository.getCurrentUser();

      expect(result.isLeft(), true);
    });
  });

  group('logout', () {
    test('calls deleteToken on secure storage', () async {
      when(mockStorage.deleteToken()).thenAnswer((_) async {});

      await repository.logout();

      verify(mockStorage.deleteToken()).called(1);
    });
  });
}
