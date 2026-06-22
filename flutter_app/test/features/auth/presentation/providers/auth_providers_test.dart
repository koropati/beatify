import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_app/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_app/features/auth/presentation/providers/auth_providers.dart';
import '../../../../mocks.mocks.dart';

Future<void> pump([int times = 3]) async {
  for (var i = 0; i < times; i++) {
    await Future.delayed(Duration.zero);
  }
}

void main() {
  late MockAuthRepositoryImpl mockRepo;

  final testUser = UserEntity(
    id: 1,
    username: 'testuser',
    email: 'test@test.com',
    role: 'user',
    isVerified: false,
  );

  setUp(() {
    mockRepo = MockAuthRepositoryImpl();
    when(mockRepo.getCurrentUser())
        .thenAnswer((_) async => Left(Exception('No token')));
    when(mockRepo.getCachedSession()).thenAnswer((_) async => null);
    when(mockRepo.cacheUser(any)).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ]);

  group('provider wiring', () {
    test('authRepositoryProvider builds the real dependency chain', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(secureStorageProvider), isNotNull);
      expect(container.read(authRemoteDataSourceProvider), isNotNull);
      expect(container.read(authRepositoryProvider), isNotNull);
    });
  });

  group('AuthNotifier — initial state', () {
    test('starts as loading then resolves to data(null) when no token', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(container.read(authStateProvider), isA<AsyncLoading>());

      await pump();

      final state = container.read(authStateProvider);
      expect(state, isA<AsyncData<UserEntity?>>());
      expect(state.value, isNull);
    });

    test('resolves to data(user) when token exists', () async {
      when(mockRepo.getCurrentUser()).thenAnswer((_) async => Right(testUser));

      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(authStateProvider); // trigger notifier creation (lazy init)
      await pump();

      final state = container.read(authStateProvider);
      expect(state.value?.username, 'testuser');
    });

    test('caches user and clears offline mode on successful online check',
        () async {
      when(mockRepo.getCurrentUser()).thenAnswer((_) async => Right(testUser));

      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(authStateProvider);
      await pump();

      verify(mockRepo.cacheUser(testUser)).called(1);
      expect(container.read(isOfflineModeProvider), isFalse);
    });
  });

  group('AuthNotifier — offline fallback', () {
    test('restores cached session and enables offline mode when server is down',
        () async {
      when(mockRepo.getCurrentUser())
          .thenAnswer((_) async => Left(Exception('Connection refused')));
      when(mockRepo.getCachedSession()).thenAnswer((_) async => testUser);

      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(authStateProvider);
      await pump();

      final state = container.read(authStateProvider);
      expect(state.value?.username, 'testuser');
      expect(container.read(isOfflineModeProvider), isTrue);
    });

    test('stays logged out (offline mode off) when no cached session', () async {
      when(mockRepo.getCurrentUser())
          .thenAnswer((_) async => Left(Exception('Connection refused')));
      when(mockRepo.getCachedSession()).thenAnswer((_) async => null);

      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(authStateProvider);
      await pump();

      expect(container.read(authStateProvider).value, isNull);
      expect(container.read(isOfflineModeProvider), isFalse);
    });

    test('retryConnection re-checks and exits offline mode when back online',
        () async {
      when(mockRepo.getCurrentUser())
          .thenAnswer((_) async => Left(Exception('Connection refused')));
      when(mockRepo.getCachedSession()).thenAnswer((_) async => testUser);

      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(authStateProvider);
      await pump();
      expect(container.read(isOfflineModeProvider), isTrue);

      when(mockRepo.getCurrentUser()).thenAnswer((_) async => Right(testUser));
      await container.read(authStateProvider.notifier).retryConnection();
      await pump();

      expect(container.read(isOfflineModeProvider), isFalse);
      expect(container.read(authStateProvider).value?.username, 'testuser');
    });
  });

  group('AuthNotifier — login', () {
    test('successful login sets state to data(user)', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authStateProvider); // create notifier & settle init
      await pump();

      when(mockRepo.login(any, any)).thenAnswer((_) async => Right('token_abc'));
      when(mockRepo.getCurrentUser()).thenAnswer((_) async => Right(testUser));

      await container.read(authStateProvider.notifier).login('testuser', 'password');
      await pump();

      final state = container.read(authStateProvider);
      expect(state.value?.username, 'testuser');
      expect(state.value?.email, 'test@test.com');
    });

    test('failed login sets state to error', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authStateProvider); // create notifier & settle init
      await pump();

      when(mockRepo.login(any, any))
          .thenAnswer((_) async => Left(Exception('Wrong credentials')));

      await container.read(authStateProvider.notifier).login('user', 'wrongpass');
      await pump();

      final state = container.read(authStateProvider);
      expect(state, isA<AsyncError>());
    });

    test('login calls repository with correct arguments', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authStateProvider); // create notifier & settle init
      await pump();

      when(mockRepo.login(any, any)).thenAnswer((_) async => Right('token'));
      when(mockRepo.getCurrentUser()).thenAnswer((_) async => Right(testUser));

      await container.read(authStateProvider.notifier).login('myuser', 'mypass');
      await pump();

      verify(mockRepo.login('myuser', 'mypass')).called(1);
    });
  });

  group('AuthNotifier — register', () {
    test('successful register triggers auto-login', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authStateProvider); // create notifier & settle init
      await pump();

      when(mockRepo.register(any, any, any))
          .thenAnswer((_) async => Right(testUser));
      when(mockRepo.login(any, any)).thenAnswer((_) async => Right('token'));
      when(mockRepo.getCurrentUser()).thenAnswer((_) async => Right(testUser));

      await container
          .read(authStateProvider.notifier)
          .register('testuser', 'test@test.com', 'password');
      await pump();

      verify(mockRepo.login('testuser', 'password')).called(1);
    });

    test('failed register sets state to error', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authStateProvider); // create notifier & settle init
      await pump();

      when(mockRepo.register(any, any, any))
          .thenAnswer((_) async => Left(Exception('Email taken')));

      await container
          .read(authStateProvider.notifier)
          .register('user', 'dup@test.com', 'pass');
      await pump();

      final state = container.read(authStateProvider);
      expect(state, isA<AsyncError>());
    });
  });

  group('AuthNotifier — updateProfile', () {
    test('success updates state to new user', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authStateProvider); // create notifier & settle init
      await pump();

      final updated = UserEntity(
        id: 1, username: 'renamed', email: 'test@test.com', role: 'user', isVerified: false,
      );
      when(mockRepo.updateProfile(any)).thenAnswer((_) async => Right(updated));

      final result = await container.read(authStateProvider.notifier).updateProfile('renamed');

      expect(result.isRight(), true);
      expect(container.read(authStateProvider).value?.username, 'renamed');
    });

    test('failure returns Left and leaves state unchanged', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authStateProvider); // create notifier & settle init
      await pump();

      when(mockRepo.updateProfile(any)).thenAnswer((_) async => Left(Exception('taken')));

      final result = await container.read(authStateProvider.notifier).updateProfile('x');

      expect(result.isLeft(), true);
    });
  });

  group('AuthNotifier — password flows', () {
    test('changePassword delegates to repository', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authStateProvider); // create notifier & settle init
      await pump();

      when(mockRepo.changePassword(any, any)).thenAnswer((_) async => const Right(null));

      final result = await container.read(authStateProvider.notifier).changePassword('old', 'new');
      expect(result.isRight(), true);
    });

    test('forgotPassword returns token', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authStateProvider); // create notifier & settle init
      await pump();

      when(mockRepo.forgotPassword(any)).thenAnswer((_) async => const Right('123456'));

      final result = await container.read(authStateProvider.notifier).forgotPassword('u@test.com');
      result.fold((_) => fail('expected Right'), (t) => expect(t, '123456'));
    });

    test('resetPassword delegates to repository', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authStateProvider); // create notifier & settle init
      await pump();

      when(mockRepo.resetPassword(any, any)).thenAnswer((_) async => const Right(null));

      final result = await container.read(authStateProvider.notifier).resetPassword('t', 'p');
      expect(result.isRight(), true);
    });
  });

  group('AuthNotifier — logout', () {
    test('logout sets state to data(null)', () async {
      when(mockRepo.getCurrentUser()).thenAnswer((_) async => Right(testUser));
      when(mockRepo.logout()).thenAnswer((_) => Future.value());

      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authStateProvider); // create notifier & settle init
      await pump();

      await container.read(authStateProvider.notifier).logout();

      final state = container.read(authStateProvider);
      expect(state.value, isNull);
      expect(container.read(isOfflineModeProvider), isFalse);
    });

    test('logout calls repository.logout()', () async {
      when(mockRepo.logout()).thenAnswer((_) => Future.value());

      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authStateProvider); // create notifier & settle init
      await pump();

      await container.read(authStateProvider.notifier).logout();

      verify(mockRepo.logout()).called(1);
    });
  });
}
