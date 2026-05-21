import 'package:dartz/dartz.dart';
import '../entities/local_playlist_entity.dart';
import '../entities/song_entity.dart';

abstract class LocalPlaylistRepository {
  Future<Either<Exception, List<LocalPlaylistEntity>>> getPlaylists();
  Future<Either<Exception, LocalPlaylistEntity>> createPlaylist(String name, {String? coverImagePath});
  Future<Either<Exception, Unit>> updatePlaylist(int id, {String? name, String? coverImagePath});
  Future<Either<Exception, Unit>> deletePlaylist(int id);
  Future<Either<Exception, Unit>> addSong(int playlistId, SongEntity song);
  Future<Either<Exception, Unit>> removeSong(int playlistId, String songId);
}
