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

  group('cacheUser', () {
    test('saves encoded user json to secure storage', () async {
      when(mockStorage.saveUser(any)).thenAnswer((_) async {});

      await repository.cacheUser(testUser);

      final captured =
          verify(mockStorage.saveUser(captureAny)).captured.single as String;
      expect(captured, contains('"username":"testuser"'));
      expect(captured, contains('"id":1'));
    });
  });

  group('getCachedSession', () {
    test('returns cached user when token and user json exist', () async {
      when(mockStorage.getToken()).thenAnswer((_) async => 'token_abc');
      when(mockStorage.getUser()).thenAnswer((_) async =>
          '{"id":1,"username":"testuser","email":"test@test.com","profile_picture_url":null,"role":"user","is_verified":false}');

      final user = await repository.getCachedSession();

      expect(user, isNotNull);
      expect(user!.username, 'testuser');
      expect(user.id, 1);
    });

    test('returns null when no token', () async {
      when(mockStorage.getToken()).thenAnswer((_) async => null);

      final user = await repository.getCachedSession();

      expect(user, isNull);
      verifyNever(mockStorage.getUser());
    });

    test('returns null when token exists but no cached user', () async {
      when(mockStorage.getToken()).thenAnswer((_) async => 'token_abc');
      when(mockStorage.getUser()).thenAnswer((_) async => null);

      final user = await repository.getCachedSession();

      expect(user, isNull);
    });
  });

  group('logout', () {
    test('clears token and cached user from secure storage', () async {
      when(mockStorage.deleteToken()).thenAnswer((_) async {});
      when(mockStorage.deleteUser()).thenAnswer((_) async {});

      await repository.logout();

      verify(mockStorage.deleteToken()).called(1);
      verify(mockStorage.deleteUser()).called(1);
    });
  });

  group('updateProfile', () {
    test('success returns Right(UserEntity)', () async {
      when(mockRemote.updateProfile(any)).thenAnswer((_) async => testUser);
      final result = await repository.updateProfile('newname');
      expect(result.isRight(), true);
    });

    test('data source throws → returns Left', () async {
      when(mockRemote.updateProfile(any)).thenThrow(Exception('taken'));
      final result = await repository.updateProfile('newname');
      expect(result.isLeft(), true);
    });
  });

  group('changePassword', () {
    test('success returns Right(null)', () async {
      when(mockRemote.changePassword(any, any)).thenAnswer((_) async {});
      final result = await repository.changePassword('old', 'new');
      expect(result.isRight(), true);
    });

    test('data source throws → returns Left', () async {
      when(mockRemote.changePassword(any, any)).thenThrow(Exception('wrong'));
      final result = await repository.changePassword('old', 'new');
      expect(result.isLeft(), true);
    });
  });

  group('forgotPassword', () {
    test('success returns Right(token)', () async {
      when(mockRemote.forgotPassword(any)).thenAnswer((_) async => '123456');
      final result = await repository.forgotPassword('u@test.com');
      expect(result.isRight(), true);
      result.fold((_) => fail('expected Right'), (t) => expect(t, '123456'));
    });

    test('data source throws → returns Left', () async {
      when(mockRemote.forgotPassword(any)).thenThrow(Exception('fail'));
      final result = await repository.forgotPassword('u@test.com');
      expect(result.isLeft(), true);
    });
  });

  group('resetPassword', () {
    test('success returns Right(null)', () async {
      when(mockRemote.resetPassword(any, any)).thenAnswer((_) async {});
      final result = await repository.resetPassword('123456', 'newpass');
      expect(result.isRight(), true);
    });

    test('data source throws → returns Left', () async {
      when(mockRemote.resetPassword(any, any)).thenThrow(Exception('expired'));
      final result = await repository.resetPassword('123456', 'newpass');
      expect(result.isLeft(), true);
    });
  });
}
