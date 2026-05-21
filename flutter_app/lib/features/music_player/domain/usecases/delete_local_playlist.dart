import 'package:dartz/dartz.dart';
import '../repositories/local_playlist_repository.dart';

class DeleteLocalPlaylist {
  final LocalPlaylistRepository _repo;
  DeleteLocalPlaylist(this._repo);
  Future<Either<Exception, Unit>> call(int id) => _repo.deletePlaylist(id);
}
