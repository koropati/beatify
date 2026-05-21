import 'song_entity.dart';

class LocalPlaylistEntity {
  final int id;
  final String name;
  final String? coverImagePath;
  final DateTime createdAt;
  final List<SongEntity> songs;

  const LocalPlaylistEntity({
    required this.id,
    required this.name,
    this.coverImagePath,
    required this.createdAt,
    this.songs = const [],
  });

  LocalPlaylistEntity copyWith({
    int? id,
    String? name,
    String? coverImagePath,
    bool clearCover = false,
    DateTime? createdAt,
    List<SongEntity>? songs,
  }) {
    return LocalPlaylistEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      coverImagePath: clearCover ? null : (coverImagePath ?? this.coverImagePath),
      createdAt: createdAt ?? this.createdAt,
      songs: songs ?? this.songs,
    );
  }
}
