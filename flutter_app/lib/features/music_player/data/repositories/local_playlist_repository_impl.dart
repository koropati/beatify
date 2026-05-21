import 'package:dartz/dartz.dart';
import '../../domain/entities/local_playlist_entity.dart';
import '../../domain/entities/song_entity.dart';
import '../../domain/repositories/local_playlist_repository.dart';
import '../datasources/local_playlist_data_source.dart';

class LocalPlaylistRepositoryImpl implements LocalPlaylistRepository {
  final LocalPlaylistDataSource _source;
  LocalPlaylistRepositoryImpl(this._source);

  @override
  Future<Either<Exception, List<LocalPlaylistEntity>>> getPlaylists() async {
    try {
      return Right(await _source.getPlaylists());
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, LocalPlaylistEntity>> createPlaylist(
    String name, {
    String? coverImagePath,
  }) async {
    try {
      return Right(await _source.createPlaylist(name, coverImagePath: coverImagePath));
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, Unit>> updatePlaylist(
    int id, {
    String? name,
    String? coverImagePath,
  }) async {
    try {
      await _source.updatePlaylist(id, name: name, coverImagePath: coverImagePath);
      return const Right(unit);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, Unit>> deletePlaylist(int id) async {
    try {
      await _source.deletePlaylist(id);
      return const Right(unit);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, Unit>> addSong(int playlistId, SongEntity song) async {
    try {
      await _source.addSong(playlistId, song);
      return const Right(unit);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, Unit>> removeSong(int playlistId, String songId) async {
    try {
      await _source.removeSong(playlistId, songId);
      return const Right(unit);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }
}
