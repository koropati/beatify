import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_app/features/reading_book/data/models/book_file_model.dart';
import 'package:flutter_app/features/reading_book/data/models/book_model.dart';
import 'package:flutter_app/features/reading_book/data/repositories/reading_book_repository_impl.dart';
import 'package:flutter_app/features/reading_book/domain/entities/book_file_entity.dart';
import '../../../../mocks.mocks.dart';

void main() {
  late MockBookFileDataSource fileSource;
  late MockBookLibraryDataSource librarySource;
  late ReadingBookRepositoryImpl repo;

  setUp(() {
    fileSource = MockBookFileDataSource();
    librarySource = MockBookLibraryDataSource();
    repo = ReadingBookRepositoryImpl(fileSource, librarySource);
  });

  BookModel book({String title = 'A', String path = '/a.pdf'}) => BookModel(
        id: 1,
        filePath: path,
        title: title,
        addedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  group('scanDevicePdfs', () {
    test('returns Right(list) on success', () async {
      when(fileSource.scanPdfs()).thenAnswer(
        (_) async => [const BookFileModel(path: '/a.pdf', name: 'a.pdf', sizeBytes: 1)],
      );

      final result = await repo.scanDevicePdfs();

      expect(result.isRight(), true);
      result.fold((_) => fail('expected Right'), (l) => expect(l.length, 1));
    });

    test('returns Left on error', () async {
      when(fileSource.scanPdfs()).thenThrow(Exception('denied'));
      final result = await repo.scanDevicePdfs();
      expect(result.isLeft(), true);
    });
  });

  group('getGallery', () {
    test('returns Right(list) on success', () async {
      when(librarySource.getAll()).thenAnswer((_) async => [book()]);
      final result = await repo.getGallery();
      expect(result.isRight(), true);
    });

    test('returns Left on error', () async {
      when(librarySource.getAll()).thenThrow(Exception('db'));
      final result = await repo.getGallery();
      expect(result.isLeft(), true);
    });
  });

  group('addToGallery', () {
    test('strips .pdf extension to derive title', () async {
      when(librarySource.add(filePath: anyNamed('filePath'), title: anyNamed('title')))
          .thenAnswer((_) async => book(title: 'My Novel'));

      final result = await repo.addToGallery(
        const BookFileEntity(path: '/x/My Novel.pdf', name: 'My Novel.pdf', sizeBytes: 1),
      );

      expect(result.isRight(), true);
      verify(librarySource.add(filePath: '/x/My Novel.pdf', title: 'My Novel')).called(1);
    });

    test('handles uppercase .PDF and trims whitespace', () async {
      when(librarySource.add(filePath: anyNamed('filePath'), title: anyNamed('title')))
          .thenAnswer((_) async => book());

      await repo.addToGallery(
        const BookFileEntity(path: '/x/  Doc .PDF', name: '  Doc .PDF', sizeBytes: 1),
      );

      verify(librarySource.add(filePath: '/x/  Doc .PDF', title: 'Doc')).called(1);
    });

    test('keeps name as title when no .pdf extension', () async {
      when(librarySource.add(filePath: anyNamed('filePath'), title: anyNamed('title')))
          .thenAnswer((_) async => book());

      await repo.addToGallery(
        const BookFileEntity(path: '/x/readme', name: 'readme', sizeBytes: 1),
      );

      verify(librarySource.add(filePath: '/x/readme', title: 'readme')).called(1);
    });

    test('returns Left on error', () async {
      when(librarySource.add(filePath: anyNamed('filePath'), title: anyNamed('title')))
          .thenThrow(Exception('insert'));

      final result = await repo.addToGallery(
        const BookFileEntity(path: '/a.pdf', name: 'a.pdf', sizeBytes: 1),
      );

      expect(result.isLeft(), true);
    });
  });

  group('removeFromGallery', () {
    test('returns Right(unit) on success', () async {
      when(librarySource.remove(any)).thenAnswer((_) async {});
      final result = await repo.removeFromGallery(1);
      expect(result.isRight(), true);
      verify(librarySource.remove(1)).called(1);
    });

    test('returns Left on error', () async {
      when(librarySource.remove(any)).thenThrow(Exception('x'));
      final result = await repo.removeFromGallery(1);
      expect(result.isLeft(), true);
    });
  });

  group('toggleFavorite', () {
    test('returns Right(unit) on success', () async {
      when(librarySource.setFavorite(any, any)).thenAnswer((_) async {});
      final result = await repo.toggleFavorite(1, true);
      expect(result.isRight(), true);
      verify(librarySource.setFavorite(1, true)).called(1);
    });

    test('returns Left on error', () async {
      when(librarySource.setFavorite(any, any)).thenThrow(Exception('x'));
      final result = await repo.toggleFavorite(1, false);
      expect(result.isLeft(), true);
    });
  });

  group('updateProgress', () {
    test('returns Right(unit) on success', () async {
      when(librarySource.setLastPage(any, any)).thenAnswer((_) async {});
      final result = await repo.updateProgress(1, 10);
      expect(result.isRight(), true);
      verify(librarySource.setLastPage(1, 10)).called(1);
    });

    test('returns Left on error', () async {
      when(librarySource.setLastPage(any, any)).thenThrow(Exception('x'));
      final result = await repo.updateProgress(1, 10);
      expect(result.isLeft(), true);
    });
  });
}
