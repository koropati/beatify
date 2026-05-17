import 'package:dio/dio.dart';
import '../models/song_model.dart';

abstract class MusicRemoteDataSource {
  Future<List<SongModel>> getOnlineSongs();
}

class MusicRemoteDataSourceImpl implements MusicRemoteDataSource {
  final Dio dio;

  // Use 10.0.2.2 for Android emulator to access localhost
  // Use localhost for Web/iOS simulator
  final String baseUrl = "http://localhost:8000/api";

  MusicRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<SongModel>> getOnlineSongs() async {
    try {
      final response = await dio.get('$baseUrl/songs');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => SongModel.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load songs");
      }
    } catch (e) {
      throw Exception("Error fetching online songs: $e");
    }
  }
}
