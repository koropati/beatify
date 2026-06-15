import '../entities/song_entity.dart';

/// Pure check: a local song counts as "already public" when it has been
/// uploaded from this device (backendSongId recorded) OR an online song with
/// the same title+artist (case-insensitive) already exists on the backend.
class IsLocalSongPublished {
  bool call(
    SongEntity song,
    List<SongEntity> onlineSongs, {
    int? backendSongId,
  }) {
    if (backendSongId != null) return true;
    final title = song.title.trim().toLowerCase();
    final artist = song.artist.trim().toLowerCase();
    return onlineSongs.any((s) =>
        s.title.trim().toLowerCase() == title &&
        s.artist.trim().toLowerCase() == artist);
  }
}
