import 'package:dio/dio.dart';
import '../models/song_model.dart';

abstract class MusicRemoteDataSource {
  Future<List<SongModel>> getOnlineSongs();
}

class MusicRemoteDataSourceImpl implements MusicRemoteDataSource {
  final Dio dio;

  MusicRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<SongModel>> getOnlineSongs() async {
    try {
      final response = await dio.get('/songs');
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
