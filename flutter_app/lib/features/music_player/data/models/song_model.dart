import '../../domain/entities/song_entity.dart';

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
      uri: json['file_url'],
      coverImageUrl: json['cover_image_url'],
      isLocal: false,
    );
  }
}
