import 'package:dartz/dartz.dart';
import '../entities/song_entity.dart';
import '../repositories/local_playlist_repository.dart';

class AddSongToLocalPlaylist {
  final LocalPlaylistRepository _repo;
  AddSongToLocalPlaylist(this._repo);
  Future<Either<Exception, Unit>> call(int playlistId, SongEntity song) =>
      _repo.addSong(playlistId, song);
}
