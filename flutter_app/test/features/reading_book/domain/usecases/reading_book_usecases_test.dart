import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_app/features/reading_book/domain/entities/book_entity.dart';
import 'package:flutter_app/features/reading_book/domain/entities/book_file_entity.dart';
import 'package:flutter_app/features/reading_book/domain/usecases/scan_device_pdfs.dart';
import 'package:flutter_app/features/reading_book/domain/usecases/get_book_gallery.dart';
import 'package:flutter_app/features/reading_book/domain/usecases/add_book_to_gallery.dart';
import 'package:flutter_app/features/reading_book/domain/usecases/remove_book_from_gallery.dart';
import 'package:flutter_app/features/reading_book/domain/usecases/toggle_book_favorite.dart';
import 'package:flutter_app/features/reading_book/domain/usecases/update_book_progress.dart';
import '../../../../mocks.mocks.dart';

void main() {
  late MockReadingBookRepositoryImpl repo;

  setUp(() => repo = MockReadingBookRepositoryImpl());

  final book = BookEntity(
    id: 1,
    filePath: '/a.pdf',
    title: 'A',
    addedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
  const file = BookFileEntity(path: '/a.pdf', name: 'a.pdf', sizeBytes: 1);

  test('ScanDevicePdfs delegates to repository', () async {
    when(repo.scanDevicePdfs()).thenAnswer((_) async => const Right([file]));
    final result = await ScanDevicePdfs(repo).call();
    expect(result.isRight(), true);
    verify(repo.scanDevicePdfs()).called(1);
  });

  test('GetBookGallery delegates to repository', () async {
    when(repo.getGallery()).thenAnswer((_) async => Right([book]));
    final result = await GetBookGallery(repo).call();
    expect(result.isRight(), true);
    verify(repo.getGallery()).called(1);
  });

  test('AddBookToGallery delegates to repository', () async {
    when(repo.addToGallery(any)).thenAnswer((_) async => Right(book));
    final result = await AddBookToGallery(repo).call(file);
    expect(result.isRight(), true);
    verify(repo.addToGallery(file)).called(1);
  });

  test('RemoveBookFromGallery delegates to repository', () async {
    when(repo.removeFromGallery(any)).thenAnswer((_) async => const Right(unit));
    final result = await RemoveBookFromGallery(repo).call(1);
    expect(result.isRight(), true);
    verify(repo.removeFromGallery(1)).called(1);
  });

  test('ToggleBookFavorite delegates to repository', () async {
    when(repo.toggleFavorite(any, any)).thenAnswer((_) async => const Right(unit));
    final result = await ToggleBookFavorite(repo).call(1, true);
    expect(result.isRight(), true);
    verify(repo.toggleFavorite(1, true)).called(1);
  });

  test('UpdateBookProgress delegates to repository', () async {
    when(repo.updateProgress(any, any)).thenAnswer((_) async => const Right(unit));
    final result = await UpdateBookProgress(repo).call(1, 7);
    expect(result.isRight(), true);
    verify(repo.updateProgress(1, 7)).called(1);
  });
}
