import 'package:dio/dio.dart';
import '../models/song_model.dart';

abstract class MusicRemoteDataSource {
  Future<List<SongModel>> getOnlineSongs();
  Future<SongModel> uploadSong({
    required String title,
    required String artist,
    String? album,
    required String filePath,
    String? coverImagePath,
  });
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

  @override
  Future<SongModel> uploadSong({
    required String title,
    required String artist,
    String? album,
    required String filePath,
    String? coverImagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'artist': artist,
        if (album != null && album.isNotEmpty) 'album': album,
        'audio_file': await MultipartFile.fromFile(filePath),
      });
      if (coverImagePath != null) {
        formData.files.add(MapEntry(
          'cover_image',
          await MultipartFile.fromFile(coverImagePath),
        ));
      }

      final response = await dio.post('/songs/upload', data: formData);
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        return SongModel.fromJson(response.data);
      }
      throw Exception("Failed to upload song");
    } catch (e) {
      throw Exception("Error uploading song: $e");
    }
  }
}
