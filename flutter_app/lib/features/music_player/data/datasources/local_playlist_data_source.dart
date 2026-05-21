import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/local_database.dart';
import '../models/local_playlist_model.dart';
import '../../domain/entities/song_entity.dart';

abstract class LocalPlaylistDataSource {
  Future<List<LocalPlaylistModel>> getPlaylists();
  Future<LocalPlaylistModel> createPlaylist(String name, {String? coverImagePath});
  Future<void> updatePlaylist(int id, {String? name, String? coverImagePath});
  Future<void> deletePlaylist(int id);
  Future<void> addSong(int playlistId, SongEntity song);
  Future<void> removeSong(int playlistId, String songId);
}

class LocalPlaylistDataSourceImpl implements LocalPlaylistDataSource {
  Future<Database> get _db => LocalDatabase.database;

  @override
  Future<List<LocalPlaylistModel>> getPlaylists() async {
    final db = await _db;
    final rows = await db.query('local_playlists', orderBy: 'created_at DESC');
    final playlists = <LocalPlaylistModel>[];
    for (final row in rows) {
      final songRows = await db.query(
        'local_playlist_songs',
        where: 'playlist_id = ?',
        whereArgs: [row['id']],
        orderBy: 'added_at ASC',
      );
      final songs = songRows
          .map((r) => SongEntity(
                id: r['song_id'] as String,
                title: r['song_title'] as String,
                artist: r['song_artist'] as String,
                album: r['song_album'] as String?,
                duration: r['song_duration'] as int,
                uri: r['song_uri'] as String,
                isLocal: true,
              ))
          .toList();
      playlists.add(LocalPlaylistModel.fromMap(row, songs: songs));
    }
    return playlists;
  }

  @override
  Future<LocalPlaylistModel> createPlaylist(String name, {String? coverImagePath}) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final savedCover = coverImagePath != null ? await _saveCover(coverImagePath) : null;
    final id = await db.insert('local_playlists', {
      'name': name,
      'cover_image_path': savedCover,
      'created_at': now,
    });
    return LocalPlaylistModel(
      id: id,
      name: name,
      coverImagePath: savedCover,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
    );
  }

  @override
  Future<void> updatePlaylist(int id, {String? name, String? coverImagePath}) async {
    final db = await _db;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (coverImagePath != null) {
      final oldRows = await db.query('local_playlists', where: 'id = ?', whereArgs: [id]);
      if (oldRows.isNotEmpty) {
        final oldCover = oldRows.first['cover_image_path'] as String?;
        if (oldCover != null) _deleteCoverFile(oldCover);
      }
      updates['cover_image_path'] = await _saveCover(coverImagePath);
    }
    if (updates.isEmpty) return;
    await db.update('local_playlists', updates, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deletePlaylist(int id) async {
    final db = await _db;
    final rows = await db.query('local_playlists', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      final cover = rows.first['cover_image_path'] as String?;
      if (cover != null) _deleteCoverFile(cover);
    }
    await db.delete('local_playlist_songs', where: 'playlist_id = ?', whereArgs: [id]);
    await db.delete('local_playlists', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> addSong(int playlistId, SongEntity song) async {
    final db = await _db;
    await db.insert(
      'local_playlist_songs',
      {
        'playlist_id': playlistId,
        'song_id': song.id,
        'song_title': song.title,
        'song_artist': song.artist,
        'song_album': song.album,
        'song_duration': song.duration,
        'song_uri': song.uri,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<void> removeSong(int playlistId, String songId) async {
    final db = await _db;
    await db.delete(
      'local_playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );
  }

  Future<String> _saveCover(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory('${appDir.path}/playlist_covers');
    if (!await coversDir.exists()) await coversDir.create(recursive: true);
    final ext = sourcePath.contains('.') ? '.${sourcePath.split('.').last}' : '.jpg';
    final dest = '${coversDir.path}/${DateTime.now().millisecondsSinceEpoch}$ext';
    await File(sourcePath).copy(dest);
    return dest;
  }

  void _deleteCoverFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }
}
