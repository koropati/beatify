import 'package:dartz/dartz.dart';
import '../entities/song_entity.dart';
import '../entities/local_song_override_entity.dart';

abstract class MusicRepository {
  Future<Either<Exception, List<SongEntity>>> getOnlineSongs();
  Future<Either<Exception, List<SongEntity>>> getLocalSongs();
  Future<Either<Exception, void>> updateLocalSongMetadata(
    String songId, {
    String? title,
    String? artist,
    String? album,
    String? coverImagePath,
  });
  Future<Either<Exception, SongEntity>> uploadLocalSongToPublic(
    SongEntity song, {
    String? coverImagePath,
  });
  Future<Either<Exception, List<LocalSongOverrideEntity>>> getLocalSongOverrides();
}
