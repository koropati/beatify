import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static Database? _instance;

  static Future<Database> get database async {
    _instance ??= await _open();
    return _instance!;
  }

  static Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'beatify.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE local_playlists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            cover_image_path TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE local_playlist_songs (
            playlist_id INTEGER NOT NULL,
            song_id TEXT NOT NULL,
            song_title TEXT NOT NULL,
            song_artist TEXT NOT NULL,
            song_album TEXT,
            song_duration INTEGER NOT NULL,
            song_uri TEXT NOT NULL,
            added_at INTEGER NOT NULL,
            PRIMARY KEY (playlist_id, song_id),
            FOREIGN KEY (playlist_id) REFERENCES local_playlists(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }
}
