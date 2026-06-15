import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/reading_book/domain/entities/book_entity.dart';
import 'package:flutter_app/features/reading_book/domain/entities/book_file_entity.dart';

void main() {
  group('BookEntity', () {
    final base = BookEntity(
      id: 1,
      filePath: '/a.pdf',
      title: 'A',
      isFavorite: false,
      lastPage: 0,
      addedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );

    test('defaults isFavorite=false and lastPage=0', () {
      final b = BookEntity(
        id: 2,
        filePath: '/b.pdf',
        title: 'B',
        addedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(b.isFavorite, false);
      expect(b.lastPage, 0);
    });

    test('copyWith overrides given fields', () {
      final updated = base.copyWith(
        id: 9,
        filePath: '/z.pdf',
        title: 'Z',
        isFavorite: true,
        lastPage: 5,
        addedAt: DateTime.fromMillisecondsSinceEpoch(1000),
      );

      expect(updated.id, 9);
      expect(updated.filePath, '/z.pdf');
      expect(updated.title, 'Z');
      expect(updated.isFavorite, true);
      expect(updated.lastPage, 5);
      expect(updated.addedAt, DateTime.fromMillisecondsSinceEpoch(1000));
    });

    test('copyWith keeps original fields when omitted', () {
      final same = base.copyWith();
      expect(same.id, base.id);
      expect(same.filePath, base.filePath);
      expect(same.title, base.title);
      expect(same.isFavorite, base.isFavorite);
      expect(same.lastPage, base.lastPage);
      expect(same.addedAt, base.addedAt);
    });
  });

  group('BookFileEntity', () {
    test('holds path, name and size', () {
      const f = BookFileEntity(path: '/a.pdf', name: 'a.pdf', sizeBytes: 10);
      expect(f.path, '/a.pdf');
      expect(f.name, 'a.pdf');
      expect(f.sizeBytes, 10);
    });
  });
}
