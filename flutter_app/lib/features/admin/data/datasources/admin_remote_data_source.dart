import 'package:dio/dio.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../music_player/domain/entities/song_entity.dart';
import '../../../music_player/data/models/song_model.dart';

abstract class AdminRemoteDataSource {
  Future<List<UserEntity>> getAllUsers();
  Future<List<UserEntity>> getUnverifiedUsers();
  Future<UserEntity> verifyUser(int userId);
  Future<UserEntity> updateUser(
    int userId, {
    String? username,
    String? email,
    String? role,
    bool? isVerified,
  });
  Future<List<SongEntity>> getAllSongs();
  Future<SongEntity> updateSong(
    int songId, {
    String? title,
    String? artist,
    String? album,
  });
  Future<void> deleteSong(int songId);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final Dio dio;

  AdminRemoteDataSourceImpl({required this.dio});

  List<UserEntity> _parseUsers(dynamic data) =>
      (data as List).map((e) => UserEntity.fromJson(e)).toList();

  @override
  Future<List<UserEntity>> getAllUsers() async {
    try {
      final response = await dio.get('/admin/users');
      if (response.statusCode == 200) return _parseUsers(response.data);
      throw Exception("Failed to load users");
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? "Error loading users");
    }
  }

  @override
  Future<List<UserEntity>> getUnverifiedUsers() async {
    try {
      final response = await dio.get('/admin/users/unverified');
      if (response.statusCode == 200) return _parseUsers(response.data);
      throw Exception("Failed to load users");
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? "Error loading users");
    }
  }

  @override
  Future<UserEntity> verifyUser(int userId) async {
    try {
      final response = await dio.put('/admin/users/$userId/verify');
      if (response.statusCode == 200) return UserEntity.fromJson(response.data);
      throw Exception("Failed to verify user");
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? "Error verifying user");
    }
  }

  @override
  Future<UserEntity> updateUser(
    int userId, {
    String? username,
    String? email,
    String? role,
    bool? isVerified,
  }) async {
    try {
      final response = await dio.put('/admin/users/$userId', data: {
        'username': ?username,
        if (email != null && email.isNotEmpty) 'email': email,
        'role': ?role,
        'is_verified': ?isVerified,
      });
      if (response.statusCode == 200) return UserEntity.fromJson(response.data);
      throw Exception("Failed to update user");
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? "Error updating user");
    }
  }

  @override
  Future<List<SongEntity>> getAllSongs() async {
    try {
      final response = await dio.get('/admin/songs');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => SongModel.fromJson(e))
            .toList();
      }
      throw Exception("Failed to load songs");
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? "Error loading songs");
    }
  }

  @override
  Future<SongEntity> updateSong(
    int songId, {
    String? title,
    String? artist,
    String? album,
  }) async {
    try {
      final response = await dio.put('/admin/songs/$songId', data: {
        'title': ?title,
        'artist': ?artist,
        'album': ?album,
      });
      if (response.statusCode == 200) return SongModel.fromJson(response.data);
      throw Exception("Failed to update song");
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? "Error updating song");
    }
  }

  @override
  Future<void> deleteSong(int songId) async {
    try {
      final response = await dio.delete('/admin/songs/$songId');
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) return;
      throw Exception("Failed to delete song");
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? "Error deleting song");
    }
  }
}
