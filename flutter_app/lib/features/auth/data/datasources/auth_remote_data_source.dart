import 'package:dio/dio.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthRemoteDataSource {
  Future<String> login(String username, String password);
  Future<UserEntity> register(String username, String email, String password);
  Future<UserEntity> getCurrentUser();
  Future<UserEntity> updateProfile(String username);
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<String?> forgotPassword(String email);
  Future<void> resetPassword(String token, String newPassword);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<String> login(String username, String password) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: FormData.fromMap({'username': username, 'password': password}),
      );
      if (response.statusCode == 200) return response.data['access_token'];
      throw Exception("Login failed");
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? "Error logging in");
    }
  }

  @override
  Future<UserEntity> register(String username, String email, String password) async {
    try {
      final response = await dio.post(
        '/auth/register',
        data: {'username': username, 'email': email, 'password': password},
      );
      if (response.statusCode == 200) return UserEntity.fromJson(response.data);
      throw Exception("Registration failed");
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? "Error registering");
    }
  }

  @override
  Future<UserEntity> getCurrentUser() async {
    try {
      final response = await dio.get('/users/me');
      if (response.statusCode == 200) return UserEntity.fromJson(response.data);
      throw Exception("Failed to get current user");
    } catch (e) {
      throw Exception("Error getting current user: $e");
    }
  }

  @override
  Future<UserEntity> updateProfile(String username) async {
    try {
      final response = await dio.put('/users/me', data: {'username': username});
      if (response.statusCode == 200) return UserEntity.fromJson(response.data);
      throw Exception("Failed to update profile");
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? "Error updating profile");
    }
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await dio.put('/users/me/password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      if (response.statusCode != 200) throw Exception("Failed to change password");
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? "Error changing password");
    }
  }

  @override
  Future<String?> forgotPassword(String email) async {
    try {
      final response = await dio.post('/auth/forgot-password', data: {'email': email});
      if (response.statusCode == 200) return response.data['token'] as String?;
      throw Exception("Failed to request password reset");
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? "Error requesting password reset");
    }
  }

  @override
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await dio.post('/auth/reset-password', data: {
        'token': token,
        'new_password': newPassword,
      });
      if (response.statusCode != 200) throw Exception("Failed to reset password");
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? "Error resetting password");
    }
  }
}
