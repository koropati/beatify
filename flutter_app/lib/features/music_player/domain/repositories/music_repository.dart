import 'package:dartz/dartz.dart';
import '../entities/song_entity.dart';

abstract class MusicRepository {
  Future<Either<Exception, List<SongEntity>>> getOnlineSongs();
  Future<Either<Exception, List<SongEntity>>> getLocalSongs();
}
