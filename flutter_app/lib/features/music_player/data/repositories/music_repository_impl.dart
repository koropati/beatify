import 'package:dartz/dartz.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/entities/local_song_override_entity.dart';
import '../../domain/repositories/music_repository.dart';
import '../datasources/local_song_override_data_source.dart';
import '../datasources/music_local_data_source.dart';
import '../datasources/music_remote_data_source.dart';

class MusicRepositoryImpl implements MusicRepository {
  final MusicRemoteDataSource remoteDataSource;
  final MusicLocalDataSource localDataSource;
  final LocalSongOverrideDataSource overrideDataSource;

  MusicRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.overrideDataSource,
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
      final rawSongs = await localDataSource.getLocalSongs();
      final overrides = await overrideDataSource.getAll();
      final byId = {for (final o in overrides) o.songId: o};

      final merged = rawSongs.map((song) {
        final o = byId[song.id];
        if (o == null) return song;
        return SongEntity(
          id: song.id,
          title: o.title ?? song.title,
          artist: o.artist ?? song.artist,
          album: o.album ?? song.album,
          duration: song.duration,
          uri: song.uri,
          coverImageUrl: song.coverImageUrl,
          coverImagePath: o.coverImagePath ?? song.coverImagePath,
          isLocal: true,
        );
      }).toList();

      return Right(merged);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, void>> updateLocalSongMetadata(
    String songId, {
    String? title,
    String? artist,
    String? album,
    String? coverImagePath,
  }) async {
    try {
      await overrideDataSource.upsert(
        songId,
        title: title,
        artist: artist,
        album: album,
        coverImagePath: coverImagePath,
      );
      return const Right(null);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, SongEntity>> uploadLocalSongToPublic(
    SongEntity song, {
    String? coverImagePath,
  }) async {
    try {
      final uploaded = await remoteDataSource.uploadSong(
        title: song.title,
        artist: song.artist,
        album: song.album,
        filePath: song.uri,
        coverImagePath: coverImagePath ?? song.coverImagePath,
      );
      final backendId = int.tryParse(uploaded.id);
      if (backendId != null) {
        await overrideDataSource.setBackendSongId(song.id, backendId);
      }
      return Right(uploaded);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, List<LocalSongOverrideEntity>>> getLocalSongOverrides() async {
    try {
      final overrides = await overrideDataSource.getAll();
      return Right(overrides);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }
}
