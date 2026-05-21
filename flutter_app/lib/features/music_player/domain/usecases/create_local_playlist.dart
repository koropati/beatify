import 'package:dartz/dartz.dart';
import '../entities/local_playlist_entity.dart';
import '../repositories/local_playlist_repository.dart';

class CreateLocalPlaylist {
  final LocalPlaylistRepository _repo;
  CreateLocalPlaylist(this._repo);
  Future<Either<Exception, LocalPlaylistEntity>> call(String name, {String? coverImagePath}) =>
      _repo.createPlaylist(name, coverImagePath: coverImagePath);
}
