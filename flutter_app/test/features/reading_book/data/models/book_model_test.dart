import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/reading_book/data/models/book_model.dart';
import 'package:flutter_app/features/reading_book/domain/entities/book_entity.dart';

void main() {
  group('BookModel', () {
    test('is a BookEntity', () {
      final model = BookModel(
        id: 1,
        filePath: '/a.pdf',
        title: 'A',
        addedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(model, isA<BookEntity>());
    });

    test('fromMap maps all fields (favorite = 1)', () {
      final map = {
        'id': 5,
        'file_path': '/books/x.pdf',
        'title': 'X Book',
        'is_favorite': 1,
        'last_page': 12,
        'added_at': 1000,
      };

      final model = BookModel.fromMap(map);

      expect(model.id, 5);
      expect(model.filePath, '/books/x.pdf');
      expect(model.title, 'X Book');
      expect(model.isFavorite, true);
      expect(model.lastPage, 12);
      expect(model.addedAt, DateTime.fromMillisecondsSinceEpoch(1000));
    });

    test('fromMap treats is_favorite = 0 as false', () {
      final model = BookModel.fromMap({
        'id': 1,
        'file_path': '/a.pdf',
        'title': 'A',
        'is_favorite': 0,
        'last_page': 0,
        'added_at': 0,
      });

      expect(model.isFavorite, false);
    });

    test('toMap serializes all fields (favorite true -> 1)', () {
      final model = BookModel(
        id: 7,
        filePath: '/c.pdf',
        title: 'C',
        isFavorite: true,
        lastPage: 3,
        addedAt: DateTime.fromMillisecondsSinceEpoch(2000),
      );

      expect(model.toMap(), {
        'id': 7,
        'file_path': '/c.pdf',
        'title': 'C',
        'is_favorite': 1,
        'last_page': 3,
        'added_at': 2000,
      });
    });

    test('toMap serializes favorite false -> 0', () {
      final model = BookModel(
        id: 8,
        filePath: '/d.pdf',
        title: 'D',
        addedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

      expect(model.toMap()['is_favorite'], 0);
    });

    test('fromMap then toMap round-trips', () {
      final map = {
        'id': 9,
        'file_path': '/e.pdf',
        'title': 'E',
        'is_favorite': 1,
        'last_page': 4,
        'added_at': 3000,
      };

      expect(BookModel.fromMap(map).toMap(), map);
    });
  });
}
