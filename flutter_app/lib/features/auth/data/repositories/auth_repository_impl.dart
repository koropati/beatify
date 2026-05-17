import 'package:dartz/dartz.dart';
import '../../../../core/network/secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorage secureStorage;

  AuthRepositoryImpl({required this.remoteDataSource, required this.secureStorage});

  @override
  Future<Either<Exception, String>> login(String username, String password) async {
    try {
      final token = await remoteDataSource.login(username, password);
      await secureStorage.saveToken(token);
      return Right(token);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, UserEntity>> register(String username, String email, String password) async {
    try {
      return Right(await remoteDataSource.register(username, email, password));
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, UserEntity>> getCurrentUser() async {
    try {
      return Right(await remoteDataSource.getCurrentUser());
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<void> logout() async => secureStorage.deleteToken();

  @override
  Future<Either<Exception, UserEntity>> updateProfile(String username) async {
    try {
      return Right(await remoteDataSource.updateProfile(username));
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, void>> changePassword(String currentPassword, String newPassword) async {
    try {
      await remoteDataSource.changePassword(currentPassword, newPassword);
      return const Right(null);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, String?>> forgotPassword(String email) async {
    try {
      final token = await remoteDataSource.forgotPassword(email);
      return Right(token);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, void>> resetPassword(String token, String newPassword) async {
    try {
      await remoteDataSource.resetPassword(token, newPassword);
      return const Right(null);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }
}
