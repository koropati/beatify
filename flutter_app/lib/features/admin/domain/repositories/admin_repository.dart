import 'package:dartz/dartz.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../music_player/domain/entities/song_entity.dart';

abstract class AdminRepository {
  Future<Either<Exception, List<UserEntity>>> getAllUsers();
  Future<Either<Exception, List<UserEntity>>> getUnverifiedUsers();
  Future<Either<Exception, UserEntity>> verifyUser(int userId);
  Future<Either<Exception, UserEntity>> updateUser(
    int userId, {
    String? username,
    String? email,
    String? role,
    bool? isVerified,
  });
  Future<Either<Exception, List<SongEntity>>> getAllSongs();
  Future<Either<Exception, SongEntity>> updateSong(
    int songId, {
    String? title,
    String? artist,
    String? album,
  });
  Future<Either<Exception, void>> deleteSong(int songId);
}
