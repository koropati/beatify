class SongEntity {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final int duration;
  final String uri; // Local path or remote URL
  final String? coverImageUrl;
  final bool isLocal;

  SongEntity({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.duration,
    required this.uri,
    this.coverImageUrl,
    required this.isLocal,
  });
}
