import 'package:dartz/dartz.dart';
import '../entities/local_song_override_entity.dart';
import '../repositories/music_repository.dart';

class GetLocalSongOverrides {
  final MusicRepository repository;

  GetLocalSongOverrides(this.repository);

  Future<Either<Exception, List<LocalSongOverrideEntity>>> call() {
    return repository.getLocalSongOverrides();
  }
}
