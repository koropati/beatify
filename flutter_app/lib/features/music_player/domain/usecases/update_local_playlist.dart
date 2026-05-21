import 'package:dartz/dartz.dart';
import '../repositories/local_playlist_repository.dart';

class UpdateLocalPlaylist {
  final LocalPlaylistRepository _repo;
  UpdateLocalPlaylist(this._repo);
  Future<Either<Exception, Unit>> call(int id, {String? name, String? coverImagePath}) =>
      _repo.updatePlaylist(id, name: name, coverImagePath: coverImagePath);
}
