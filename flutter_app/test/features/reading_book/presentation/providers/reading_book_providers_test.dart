import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_app/features/reading_book/data/datasources/book_file_data_source.dart';
import 'package:flutter_app/features/reading_book/data/datasources/book_library_data_source.dart';
import 'package:flutter_app/features/reading_book/data/repositories/reading_book_repository_impl.dart';
import 'package:flutter_app/features/reading_book/domain/entities/book_entity.dart';
import 'package:flutter_app/features/reading_book/domain/entities/book_file_entity.dart';
import 'package:flutter_app/features/reading_book/domain/repositories/reading_book_repository.dart';
import 'package:flutter_app/features/reading_book/presentation/providers/reading_book_providers.dart';
import '../../../../mocks.mocks.dart';

void main() {
  late MockReadingBookRepositoryImpl repo;

  BookEntity book({int id = 1, bool fav = false}) => BookEntity(
        id: id,
        filePath: '/$id.pdf',
        title: 'Book $id',
        isFavorite: fav,
        addedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  const file = BookFileEntity(path: '/a.pdf', name: 'a.pdf', sizeBytes: 1);

  setUp(() => repo = MockReadingBookRepositoryImpl());

  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        readingBookRepositoryProvider.overrideWithValue(repo),
      ]);

  group('bookGalleryProvider', () {
    test('returns books on success', () async {
      when(repo.getGallery()).thenAnswer((_) async => Right([book()]));
      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(bookGalleryProvider.future);
      expect(result.length, 1);
      expect(result.first.title, 'Book 1');
    });

    test('throws when repository returns Left', () async {
      when(repo.getGallery()).thenAnswer((_) async => Left(Exception('db')));
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(container.read(bookGalleryProvider.future), throwsA(isA<Exception>()));
    });
  });

  group('favoriteBooksProvider', () {
    test('returns only favorite books', () async {
      when(repo.getGallery()).thenAnswer(
        (_) async => Right([book(id: 1, fav: true), book(id: 2), book(id: 3, fav: true)]),
      );
      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(favoriteBooksProvider.future);
      expect(result.map((b) => b.id), [1, 3]);
    });

    test('propagates error from gallery', () async {
      when(repo.getGallery()).thenAnswer((_) async => Left(Exception('db')));
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(container.read(favoriteBooksProvider.future), throwsA(isA<Exception>()));
    });
  });

  group('deviceBookFilesProvider', () {
    test('returns scanned files on success', () async {
      when(repo.scanDevicePdfs()).thenAnswer((_) async => const Right([file]));
      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(deviceBookFilesProvider.future);
      expect(result.length, 1);
      expect(result.first.name, 'a.pdf');
    });

    test('throws when repository returns Left', () async {
      when(repo.scanDevicePdfs()).thenAnswer((_) async => Left(Exception('denied')));
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(container.read(deviceBookFilesProvider.future), throwsA(isA<Exception>()));
    });
  });

  group('provider wiring', () {
    test('default data source & repository providers construct', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(bookFileDataSourceProvider), isA<BookFileDataSourceImpl>());
      expect(container.read(bookLibraryDataSourceProvider), isA<BookLibraryDataSourceImpl>());
      expect(
        container.read(readingBookRepositoryProvider),
        isA<ReadingBookRepositoryImpl>(),
      );
      expect(container.read(readingBookRepositoryProvider), isA<ReadingBookRepository>());
    });
  });

  group('BookGalleryController', () {
    test('addToGallery delegates and invalidates the gallery', () async {
      when(repo.addToGallery(any)).thenAnswer((_) async => Right(book()));
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(bookGalleryControllerProvider).addToGallery(file);
      verify(repo.addToGallery(file)).called(1);
    });

    test('addToGallery throws on Left', () async {
      when(repo.addToGallery(any)).thenAnswer((_) async => Left(Exception('x')));
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(bookGalleryControllerProvider).addToGallery(file),
        throwsA(isA<Exception>()),
      );
    });

    test('removeFromGallery delegates', () async {
      when(repo.removeFromGallery(any)).thenAnswer((_) async => const Right(unit));
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(bookGalleryControllerProvider).removeFromGallery(5);
      verify(repo.removeFromGallery(5)).called(1);
    });

    test('removeFromGallery throws on Left', () async {
      when(repo.removeFromGallery(any)).thenAnswer((_) async => Left(Exception('x')));
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(bookGalleryControllerProvider).removeFromGallery(5),
        throwsA(isA<Exception>()),
      );
    });

    test('toggleFavorite delegates', () async {
      when(repo.toggleFavorite(any, any)).thenAnswer((_) async => const Right(unit));
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(bookGalleryControllerProvider).toggleFavorite(3, true);
      verify(repo.toggleFavorite(3, true)).called(1);
    });

    test('toggleFavorite throws on Left', () async {
      when(repo.toggleFavorite(any, any)).thenAnswer((_) async => Left(Exception('x')));
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(bookGalleryControllerProvider).toggleFavorite(3, true),
        throwsA(isA<Exception>()),
      );
    });

    test('updateProgress delegates', () async {
      when(repo.updateProgress(any, any)).thenAnswer((_) async => const Right(unit));
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(bookGalleryControllerProvider).updateProgress(2, 9);
      verify(repo.updateProgress(2, 9)).called(1);
    });

    test('updateProgress throws on Left', () async {
      when(repo.updateProgress(any, any)).thenAnswer((_) async => Left(Exception('x')));
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(bookGalleryControllerProvider).updateProgress(2, 9),
        throwsA(isA<Exception>()),
      );
    });
  });
}
