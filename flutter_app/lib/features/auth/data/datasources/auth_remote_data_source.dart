import 'package:dio/dio.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthRemoteDataSource {
  Future<String> login(String username, String password);
  Future<UserEntity> register(String username, String email, String password);
  Future<UserEntity> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<String> login(String username, String password) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: FormData.fromMap({
          'username': username,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        return response.data['access_token'];
      } else {
        throw Exception("Login failed");
      }
    } catch (e) {
      throw Exception("Error logging in: $e");
    }
  }

  @override
  Future<UserEntity> register(String username, String email, String password) async {
    try {
      final response = await dio.post(
        '/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );
      if (response.statusCode == 200) {
        return UserEntity.fromJson(response.data);
      } else {
        throw Exception("Registration failed");
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? "Error registering");
    } catch (e) {
      throw Exception("Error registering: $e");
    }
  }

  @override
  Future<UserEntity> getCurrentUser() async {
    try {
      final response = await dio.get('/users/me');
      if (response.statusCode == 200) {
        return UserEntity.fromJson(response.data);
      } else {
        throw Exception("Failed to get current user");
      }
    } catch (e) {
      throw Exception("Error getting current user: $e");
    }
  }
}
