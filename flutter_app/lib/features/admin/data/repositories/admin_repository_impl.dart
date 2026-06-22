import 'package:dartz/dartz.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../music_player/domain/entities/song_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Exception, List<UserEntity>>> getAllUsers() async {
    try {
      return Right(await remoteDataSource.getAllUsers());
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, List<UserEntity>>> getUnverifiedUsers() async {
    try {
      return Right(await remoteDataSource.getUnverifiedUsers());
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, UserEntity>> verifyUser(int userId) async {
    try {
      return Right(await remoteDataSource.verifyUser(userId));
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, UserEntity>> updateUser(
    int userId, {
    String? username,
    String? email,
    String? role,
    bool? isVerified,
  }) async {
    try {
      return Right(await remoteDataSource.updateUser(
        userId,
        username: username,
        email: email,
        role: role,
        isVerified: isVerified,
      ));
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, List<SongEntity>>> getAllSongs() async {
    try {
      return Right(await remoteDataSource.getAllSongs());
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, SongEntity>> updateSong(
    int songId, {
    String? title,
    String? artist,
    String? album,
  }) async {
    try {
      return Right(await remoteDataSource.updateSong(
        songId,
        title: title,
        artist: artist,
        album: album,
      ));
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, void>> deleteSong(int songId) async {
    try {
      await remoteDataSource.deleteSong(songId);
      return const Right(null);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }
}
