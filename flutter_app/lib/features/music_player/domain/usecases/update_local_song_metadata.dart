import 'package:dartz/dartz.dart';
import '../repositories/music_repository.dart';

class UpdateLocalSongMetadata {
  final MusicRepository repository;

  UpdateLocalSongMetadata(this.repository);

  Future<Either<Exception, void>> call(
    String songId, {
    String? title,
    String? artist,
    String? album,
    String? coverImagePath,
  }) {
    return repository.updateLocalSongMetadata(
      songId,
      title: title,
      artist: artist,
      album: album,
      coverImagePath: coverImagePath,
    );
  }
}
