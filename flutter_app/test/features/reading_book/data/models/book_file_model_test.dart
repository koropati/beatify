import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/reading_book/data/models/book_file_model.dart';
import 'package:flutter_app/features/reading_book/domain/entities/book_file_entity.dart';

void main() {
  group('BookFileModel', () {
    test('is a BookFileEntity', () {
      const model = BookFileModel(path: '/a.pdf', name: 'a.pdf', sizeBytes: 1);
      expect(model, isA<BookFileEntity>());
    });

    test('fromPath derives name from a unix path', () {
      final model = BookFileModel.fromPath('/storage/emulated/0/Download/book.pdf', 2048);
      expect(model.path, '/storage/emulated/0/Download/book.pdf');
      expect(model.name, 'book.pdf');
      expect(model.sizeBytes, 2048);
    });

    test('fromPath derives name from a windows path', () {
      final model = BookFileModel.fromPath(r'C:\Users\me\Documents\novel.pdf', 100);
      expect(model.name, 'novel.pdf');
    });

    test('fromPath uses whole string when there is no separator', () {
      final model = BookFileModel.fromPath('lonely.pdf', 0);
      expect(model.name, 'lonely.pdf');
    });
  });
}
