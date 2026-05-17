import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../music_player/presentation/providers/music_providers.dart'; // To get dioProvider

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(dio: ref.read(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.read(authRemoteDataSourceProvider),
    secureStorage: ref.read(secureStorageProvider),
  );
});

// StateNotifier to manage authentication state
class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final AuthRepositoryImpl _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = const AsyncValue.loading();
    final result = await _repository.getCurrentUser();
    result.fold(
      (failure) => state = const AsyncValue.data(null), // Not logged in or error
      (user) => state = AsyncValue.data(user),
    );
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    final result = await _repository.login(username, password);
    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        // Reset to null user so we stay on login page but show error
        state = const AsyncValue.data(null); 
      },
      (token) => _checkAuthStatus(), // Refresh user data after getting token
    );
  }

  Future<void> register(String username, String email, String password) async {
    state = const AsyncValue.loading();
    final result = await _repository.register(username, email, password);
    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        state = const AsyncValue.data(null);
      },
      (user) {
        // Automatically log in after registration
        login(username, password);
      },
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
