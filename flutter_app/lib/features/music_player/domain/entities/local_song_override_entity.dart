class LocalSongOverrideEntity {
  final String songId;
  final String? title;
  final String? artist;
  final String? album;
  final String? coverImagePath;
  final int? backendSongId; // set once the song is uploaded to public

  const LocalSongOverrideEntity({
    required this.songId,
    this.title,
    this.artist,
    this.album,
    this.coverImagePath,
    this.backendSongId,
  });
}
