import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Exception, String>> login(String username, String password);
  Future<Either<Exception, UserEntity>> register(String username, String email, String password);
  Future<Either<Exception, UserEntity>> getCurrentUser();
  Future<void> logout();
}
