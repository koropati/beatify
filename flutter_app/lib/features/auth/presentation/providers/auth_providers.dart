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

/// True ketika sesi dipulihkan dari cache lokal tanpa koneksi ke server.
/// Saat aktif, fitur online dibatasi — hanya musik lokal yang tersedia.
final isOfflineModeProvider = StateProvider<bool>((ref) => false);

class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final Ref _ref;
  final AuthRepositoryImpl _repository;

  AuthNotifier(this._ref, this._repository) : super(const AsyncValue.loading()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = const AsyncValue.loading();
    final result = await _repository.getCurrentUser();
    await result.fold(
      (failure) async {
        // Server tidak terjangkau: pulihkan sesi offline jika token & cache ada.
        // 401 sudah menghapus token via interceptor, jadi sesi kedaluwarsa
        // tidak akan ikut dipulihkan di sini.
        final cached = await _repository.getCachedSession();
        _ref.read(isOfflineModeProvider.notifier).state = cached != null;
        state = AsyncValue.data(cached);
      },
      (user) async {
        _ref.read(isOfflineModeProvider.notifier).state = false;
        await _repository.cacheUser(user);
        state = AsyncValue.data(user);
      },
    );
  }

  /// Coba sambung ulang ke server (mis. dari banner mode offline).
  Future<void> retryConnection() => _checkAuthStatus();

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
    _ref.read(isOfflineModeProvider.notifier).state = false;
    state = const AsyncValue.data(null);
  }

  Future<Either<Exception, void>> updateProfile(String username, {String? email}) async {
    final result = await _repository.updateProfile(username, email: email);
    await result.fold((_) async {}, (user) async {
      await _repository.cacheUser(user);
      state = AsyncValue.data(user);
    });
    return result.map((_) {});
  }

  Future<Either<Exception, void>> uploadProfilePicture(String filePath) async {
    final result = await _repository.uploadProfilePicture(filePath);
    await result.fold((_) async {}, (user) async {
      await _repository.cacheUser(user);
      state = AsyncValue.data(user);
    });
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
  return AuthNotifier(ref, ref.read(authRepositoryProvider));
});
