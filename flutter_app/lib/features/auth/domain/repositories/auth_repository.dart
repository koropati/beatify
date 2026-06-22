import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Exception, String>> login(String username, String password);
  Future<Either<Exception, UserEntity>> register(String username, String email, String password);
  Future<Either<Exception, UserEntity>> getCurrentUser();
  Future<void> cacheUser(UserEntity user);
  Future<UserEntity?> getCachedSession();
  Future<void> logout();
  Future<Either<Exception, UserEntity>> updateProfile(String username, {String? email});
  Future<Either<Exception, UserEntity>> uploadProfilePicture(String filePath);
  Future<Either<Exception, void>> changePassword(String currentPassword, String newPassword);
  Future<Either<Exception, String?>> forgotPassword(String email);
  Future<Either<Exception, void>> resetPassword(String token, String newPassword);
}
