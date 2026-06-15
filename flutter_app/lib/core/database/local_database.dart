// coverage:ignore-file
// Platform SQLite setup — exercised on device, not in unit tests.
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
      version: 3,
      onCreate: (db, _) async {
        await _createPlaylistTables(db);
        await _createSongOverridesTable(db);
        await _createBooksTable(db);
      },
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) {
          await _createSongOverridesTable(db);
        }
        if (oldVersion < 3) {
          await _createBooksTable(db);
        }
      },
    );
  }

  static Future<void> _createPlaylistTables(Database db) async {
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
  }

  static Future<void> _createSongOverridesTable(Database db) async {
    await db.execute('''
      CREATE TABLE local_song_overrides (
        song_id TEXT PRIMARY KEY,
        title TEXT,
        artist TEXT,
        album TEXT,
        cover_image_path TEXT,
        backend_song_id INTEGER,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _createBooksTable(Database db) async {
    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_path TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        last_page INTEGER NOT NULL DEFAULT 0,
        added_at INTEGER NOT NULL
      )
    ''');
  }
}
