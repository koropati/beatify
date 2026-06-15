// coverage:ignore-file
// Wraps sqflite (platform plugin); exercised on device, not in unit tests.
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/local_database.dart';
import '../models/book_model.dart';

abstract class BookLibraryDataSource {
  Future<List<BookModel>> getAll();
  Future<BookModel> add({required String filePath, required String title});
  Future<void> remove(int id);
  Future<void> setFavorite(int id, bool isFavorite);
  Future<void> setLastPage(int id, int lastPage);
}

class BookLibraryDataSourceImpl implements BookLibraryDataSource {
  Future<Database> get _db => LocalDatabase.database;

  @override
  Future<List<BookModel>> getAll() async {
    final db = await _db;
    final rows = await db.query('books', orderBy: 'added_at DESC');
    return rows.map(BookModel.fromMap).toList();
  }

  @override
  Future<BookModel> add({required String filePath, required String title}) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await db.insert(
      'books',
      {
        'file_path': filePath,
        'title': title,
        'is_favorite': 0,
        'last_page': 0,
        'added_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    if (id == 0) {
      // Already present (UNIQUE file_path) — return the existing row.
      final rows = await db.query('books', where: 'file_path = ?', whereArgs: [filePath]);
      return BookModel.fromMap(rows.first);
    }
    return BookModel(
      id: id,
      filePath: filePath,
      title: title,
      addedAt: DateTime.fromMillisecondsSinceEpoch(now),
    );
  }

  @override
  Future<void> remove(int id) async {
    final db = await _db;
    await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> setFavorite(int id, bool isFavorite) async {
    final db = await _db;
    await db.update(
      'books',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> setLastPage(int id, int lastPage) async {
    final db = await _db;
    await db.update(
      'books',
      {'last_page': lastPage},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
