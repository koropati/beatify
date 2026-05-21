import 'package:dartz/dartz.dart';
import '../entities/local_playlist_entity.dart';
import '../repositories/local_playlist_repository.dart';

class GetLocalPlaylists {
  final LocalPlaylistRepository _repo;
  GetLocalPlaylists(this._repo);
  Future<Either<Exception, List<LocalPlaylistEntity>>> call() => _repo.getPlaylists();
}
