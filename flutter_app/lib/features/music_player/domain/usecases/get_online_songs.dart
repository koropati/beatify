import 'package:dartz/dartz.dart';
import '../entities/song_entity.dart';
import '../repositories/music_repository.dart';

class GetOnlineSongs {
  final MusicRepository repository;

  GetOnlineSongs(this.repository);

  Future<Either<Exception, List<SongEntity>>> execute() {
    return repository.getOnlineSongs();
  }
}
