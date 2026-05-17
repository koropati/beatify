import 'package:dartz/dartz.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/repositories/music_repository.dart';
import '../datasources/music_local_data_source.dart';
import '../datasources/music_remote_data_source.dart';

class MusicRepositoryImpl implements MusicRepository {
  final MusicRemoteDataSource remoteDataSource;
  final MusicLocalDataSource localDataSource;

  MusicRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Exception, List<SongEntity>>> getOnlineSongs() async {
    try {
      final remoteSongs = await remoteDataSource.getOnlineSongs();
      return Right(remoteSongs);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, List<SongEntity>>> getLocalSongs() async {
    try {
      final localSongs = await localDataSource.getLocalSongs();
      return Right(localSongs);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }
}
