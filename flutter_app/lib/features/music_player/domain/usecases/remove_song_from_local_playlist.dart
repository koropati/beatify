import 'package:dartz/dartz.dart';
import '../repositories/local_playlist_repository.dart';

class RemoveSongFromLocalPlaylist {
  final LocalPlaylistRepository _repo;
  RemoveSongFromLocalPlaylist(this._repo);
  Future<Either<Exception, Unit>> call(int playlistId, String songId) =>
      _repo.removeSong(playlistId, songId);
}
