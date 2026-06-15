import '../../domain/entities/local_song_override_entity.dart';

class LocalSongOverrideModel extends LocalSongOverrideEntity {
  const LocalSongOverrideModel({
    required super.songId,
    super.title,
    super.artist,
    super.album,
    super.coverImagePath,
    super.backendSongId,
  });

  factory LocalSongOverrideModel.fromMap(Map<String, dynamic> map) {
    return LocalSongOverrideModel(
      songId: map['song_id'] as String,
      title: map['title'] as String?,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      coverImagePath: map['cover_image_path'] as String?,
      backendSongId: map['backend_song_id'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'song_id': songId,
      'title': title,
      'artist': artist,
      'album': album,
      'cover_image_path': coverImagePath,
      'backend_song_id': backendSongId,
    };
  }
}
