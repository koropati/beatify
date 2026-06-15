// coverage:ignore-file
// Wraps sqflite (platform plugin); exercised on device, not in unit tests.
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/local_database.dart';
import '../models/local_song_override_model.dart';

abstract class LocalSongOverrideDataSource {
  Future<List<LocalSongOverrideModel>> getAll();
  Future<LocalSongOverrideModel?> getById(String songId);
  Future<void> upsert(
    String songId, {
    String? title,
    String? artist,
    String? album,
    String? coverImagePath,
  });
  Future<void> setBackendSongId(String songId, int backendSongId);
}

class LocalSongOverrideDataSourceImpl implements LocalSongOverrideDataSource {
  Future<Database> get _db => LocalDatabase.database;

  @override
  Future<List<LocalSongOverrideModel>> getAll() async {
    final db = await _db;
    final rows = await db.query('local_song_overrides');
    return rows.map(LocalSongOverrideModel.fromMap).toList();
  }

  @override
  Future<LocalSongOverrideModel?> getById(String songId) async {
    final db = await _db;
    final rows = await db.query(
      'local_song_overrides',
      where: 'song_id = ?',
      whereArgs: [songId],
    );
    if (rows.isEmpty) return null;
    return LocalSongOverrideModel.fromMap(rows.first);
  }

  @override
  Future<void> upsert(
    String songId, {
    String? title,
    String? artist,
    String? album,
    String? coverImagePath,
  }) async {
    final db = await _db;
    final existing = await getById(songId);

    var savedCover = existing?.coverImagePath;
    if (coverImagePath != null) {
      if (existing?.coverImagePath != null) {
        _deleteCoverFile(existing!.coverImagePath!);
      }
      savedCover = await _saveCover(coverImagePath);
    }

    await db.insert(
      'local_song_overrides',
      {
        'song_id': songId,
        'title': title ?? existing?.title,
        'artist': artist ?? existing?.artist,
        'album': album ?? existing?.album,
        'cover_image_path': savedCover,
        'backend_song_id': existing?.backendSongId,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> setBackendSongId(String songId, int backendSongId) async {
    final db = await _db;
    final existing = await getById(songId);
    await db.insert(
      'local_song_overrides',
      {
        'song_id': songId,
        'title': existing?.title,
        'artist': existing?.artist,
        'album': existing?.album,
        'cover_image_path': existing?.coverImagePath,
        'backend_song_id': backendSongId,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String> _saveCover(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/song_covers');
    if (!await dir.exists()) await dir.create(recursive: true);
    final ext = sourcePath.contains('.') ? '.${sourcePath.split('.').last}' : '.jpg';
    final dest = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}$ext';
    await File(sourcePath).copy(dest);
    return dest;
  }

  void _deleteCoverFile(String path) {
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }
}
