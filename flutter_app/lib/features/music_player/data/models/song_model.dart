import '../../domain/entities/song_entity.dart';
import '../../../../core/config/app_config.dart';

class SongModel extends SongEntity {
  SongModel({
    required super.id,
    required super.title,
    required super.artist,
    super.album,
    required super.duration,
    required super.uri,
    super.coverImageUrl,
    required super.isLocal,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'].toString(),
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      duration: json['duration'],
      uri: AppConfig.fixUrl(json['file_url']),
      coverImageUrl: json['cover_image_url'] != null
          ? AppConfig.fixUrl(json['cover_image_url'])
          : null,
      isLocal: false,
    );
  }
}
