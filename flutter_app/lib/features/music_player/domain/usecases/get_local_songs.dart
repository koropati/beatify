import 'package:dartz/dartz.dart';
import '../entities/song_entity.dart';
import '../repositories/music_repository.dart';

class GetLocalSongs {
  final MusicRepository repository;

  GetLocalSongs(this.repository);

  Future<Either<Exception, List<SongEntity>>> execute() {
    return repository.getLocalSongs();
  }
}
