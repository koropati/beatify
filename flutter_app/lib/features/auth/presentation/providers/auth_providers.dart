import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../music_player/presentation/providers/music_providers.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(dio: ref.read(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.read(authRemoteDataSourceProvider),
    secureStorage: ref.read(secureStorageProvider),
  );
});

class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final AuthRepositoryImpl _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = const AsyncValue.loading();
    final result = await _repository.getCurrentUser();
    result.fold(
      (failure) => state = const AsyncValue.data(null),
      (user) => state = AsyncValue.data(user),
    );
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    final result = await _repository.login(username, password);
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (token) => _checkAuthStatus(),
    );
  }

  Future<void> register(String username, String email, String password) async {
    state = const AsyncValue.loading();
    final result = await _repository.register(username, email, password);
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (user) => login(username, password),
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }

  Future<Either<Exception, void>> updateProfile(String username) async {
    final result = await _repository.updateProfile(username);
    result.fold((_) {}, (user) => state = AsyncValue.data(user));
    return result.map((_) {});
  }

  Future<Either<Exception, void>> changePassword(String currentPassword, String newPassword) {
    return _repository.changePassword(currentPassword, newPassword);
  }

  Future<Either<Exception, String?>> forgotPassword(String email) {
    return _repository.forgotPassword(email);
  }

  Future<Either<Exception, void>> resetPassword(String token, String newPassword) {
    return _repository.resetPassword(token, newPassword);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
