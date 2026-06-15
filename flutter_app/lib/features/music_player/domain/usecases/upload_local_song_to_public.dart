import 'package:dartz/dartz.dart';
import '../entities/song_entity.dart';
import '../repositories/music_repository.dart';

class UploadLocalSongToPublic {
  final MusicRepository repository;

  UploadLocalSongToPublic(this.repository);

  Future<Either<Exception, SongEntity>> call(
    SongEntity song, {
    String? coverImagePath,
  }) {
    return repository.uploadLocalSongToPublic(song, coverImagePath: coverImagePath);
  }
}
