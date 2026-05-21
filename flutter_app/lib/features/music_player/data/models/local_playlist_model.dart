import '../../domain/entities/local_playlist_entity.dart';
import '../../domain/entities/song_entity.dart';

class LocalPlaylistModel extends LocalPlaylistEntity {
  const LocalPlaylistModel({
    required super.id,
    required super.name,
    super.coverImagePath,
    required super.createdAt,
    super.songs = const [],
  });

  factory LocalPlaylistModel.fromMap(
    Map<String, dynamic> map, {
    List<SongEntity> songs = const [],
  }) =>
      LocalPlaylistModel(
        id: map['id'] as int,
        name: map['name'] as String,
        coverImagePath: map['cover_image_path'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        songs: songs,
      );

  Map<String, dynamic> toInsertMap() => {
        'name': name,
        'cover_image_path': coverImagePath,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}
