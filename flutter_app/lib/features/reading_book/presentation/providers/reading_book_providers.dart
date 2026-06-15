import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/entities/book_file_entity.dart';
import '../../domain/repositories/reading_book_repository.dart';
import '../../data/datasources/book_file_data_source.dart';
import '../../data/datasources/book_library_data_source.dart';
import '../../data/repositories/reading_book_repository_impl.dart';
import '../../domain/usecases/scan_device_pdfs.dart';
import '../../domain/usecases/get_book_gallery.dart';
import '../../domain/usecases/add_book_to_gallery.dart';
import '../../domain/usecases/remove_book_from_gallery.dart';
import '../../domain/usecases/toggle_book_favorite.dart';
import '../../domain/usecases/update_book_progress.dart';

final bookFileDataSourceProvider = Provider<BookFileDataSource>(
  (_) => BookFileDataSourceImpl(),
);

final bookLibraryDataSourceProvider = Provider<BookLibraryDataSource>(
  (_) => BookLibraryDataSourceImpl(),
);

final readingBookRepositoryProvider = Provider<ReadingBookRepository>(
  (ref) => ReadingBookRepositoryImpl(
    ref.read(bookFileDataSourceProvider),
    ref.read(bookLibraryDataSourceProvider),
  ),
);

final scanDevicePdfsUseCaseProvider = Provider<ScanDevicePdfs>(
  (ref) => ScanDevicePdfs(ref.read(readingBookRepositoryProvider)),
);

final getBookGalleryUseCaseProvider = Provider<GetBookGallery>(
  (ref) => GetBookGallery(ref.read(readingBookRepositoryProvider)),
);

final addBookToGalleryUseCaseProvider = Provider<AddBookToGallery>(
  (ref) => AddBookToGallery(ref.read(readingBookRepositoryProvider)),
);

final removeBookFromGalleryUseCaseProvider = Provider<RemoveBookFromGallery>(
  (ref) => RemoveBookFromGallery(ref.read(readingBookRepositoryProvider)),
);

final toggleBookFavoriteUseCaseProvider = Provider<ToggleBookFavorite>(
  (ref) => ToggleBookFavorite(ref.read(readingBookRepositoryProvider)),
);

final updateBookProgressUseCaseProvider = Provider<UpdateBookProgress>(
  (ref) => UpdateBookProgress(ref.read(readingBookRepositoryProvider)),
);

/// Books in the user's gallery, readable offline.
final bookGalleryProvider = FutureProvider<List<BookEntity>>((ref) async {
  final result = await ref.read(getBookGalleryUseCaseProvider).call();
  return result.fold((e) => throw e, (books) => books);
});

/// Subset of the gallery marked as favorite.
final favoriteBooksProvider = FutureProvider<List<BookEntity>>((ref) async {
  final books = await ref.watch(bookGalleryProvider.future);
  return books.where((b) => b.isFavorite).toList();
});

/// PDF files discovered on the device (the "file gallery").
final deviceBookFilesProvider = FutureProvider<List<BookFileEntity>>((ref) async {
  final result = await ref.read(scanDevicePdfsUseCaseProvider).call();
  return result.fold((e) => throw e, (files) => files);
});

/// Free-text query used to filter the book and file lists.
final bookSearchQueryProvider = StateProvider<String>((ref) => '');

List<T> _filterByName<T>(List<T> items, String query, String Function(T) name) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return items;
  return items.where((item) => name(item).toLowerCase().contains(q)).toList();
}

/// Gallery filtered by [bookSearchQueryProvider].
final filteredBookGalleryProvider = FutureProvider<List<BookEntity>>((ref) async {
  final books = await ref.watch(bookGalleryProvider.future);
  return _filterByName(books, ref.watch(bookSearchQueryProvider), (b) => b.title);
});

/// Favorites filtered by [bookSearchQueryProvider].
final filteredFavoriteBooksProvider = FutureProvider<List<BookEntity>>((ref) async {
  final books = await ref.watch(favoriteBooksProvider.future);
  return _filterByName(books, ref.watch(bookSearchQueryProvider), (b) => b.title);
});

/// Device PDF files filtered by [bookSearchQueryProvider].
final filteredDeviceBookFilesProvider =
    FutureProvider<List<BookFileEntity>>((ref) async {
  final files = await ref.watch(deviceBookFilesProvider.future);
  return _filterByName(files, ref.watch(bookSearchQueryProvider), (f) => f.name);
});

/// Controller for gallery mutations; refreshes the gallery providers on success.
class BookGalleryController {
  BookGalleryController(this._ref);
  final Ref _ref;

  Future<void> addToGallery(BookFileEntity file) async {
    final result = await _ref.read(addBookToGalleryUseCaseProvider).call(file);
    result.fold((e) => throw e, (_) => _invalidateGallery());
  }

  Future<void> removeFromGallery(int id) async {
    final result = await _ref.read(removeBookFromGalleryUseCaseProvider).call(id);
    result.fold((e) => throw e, (_) => _invalidateGallery());
  }

  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final result =
        await _ref.read(toggleBookFavoriteUseCaseProvider).call(id, isFavorite);
    result.fold((e) => throw e, (_) => _invalidateGallery());
  }

  Future<void> updateProgress(int id, int lastPage) async {
    final result =
        await _ref.read(updateBookProgressUseCaseProvider).call(id, lastPage);
    result.fold((e) => throw e, (_) => _invalidateGallery());
  }

  void _invalidateGallery() => _ref.invalidate(bookGalleryProvider);
}

final bookGalleryControllerProvider = Provider<BookGalleryController>(
  (ref) => BookGalleryController(ref),
);
