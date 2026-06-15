import 'package:dartz/dartz.dart';
import '../entities/book_entity.dart';
import '../entities/book_file_entity.dart';

abstract class ReadingBookRepository {
  /// Scans common device folders for PDF files.
  Future<Either<Exception, List<BookFileEntity>>> scanDevicePdfs();

  /// Books the user has added to their gallery.
  Future<Either<Exception, List<BookEntity>>> getGallery();

  Future<Either<Exception, BookEntity>> addToGallery(BookFileEntity file);

  Future<Either<Exception, Unit>> removeFromGallery(int id);

  Future<Either<Exception, Unit>> toggleFavorite(int id, bool isFavorite);

  Future<Either<Exception, Unit>> updateProgress(int id, int lastPage);
}
