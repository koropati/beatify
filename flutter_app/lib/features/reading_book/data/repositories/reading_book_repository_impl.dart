import 'package:dartz/dartz.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/entities/book_file_entity.dart';
import '../../domain/repositories/reading_book_repository.dart';
import '../datasources/book_file_data_source.dart';
import '../datasources/book_library_data_source.dart';

class ReadingBookRepositoryImpl implements ReadingBookRepository {
  final BookFileDataSource _fileSource;
  final BookLibraryDataSource _librarySource;

  ReadingBookRepositoryImpl(this._fileSource, this._librarySource);

  @override
  Future<Either<Exception, List<BookFileEntity>>> scanDevicePdfs() async {
    try {
      return Right(await _fileSource.scanPdfs());
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, List<BookEntity>>> getGallery() async {
    try {
      return Right(await _librarySource.getAll());
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, BookEntity>> addToGallery(BookFileEntity file) async {
    try {
      final book = await _librarySource.add(
        filePath: file.path,
        title: _deriveTitle(file.name),
      );
      return Right(book);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, Unit>> removeFromGallery(int id) async {
    try {
      await _librarySource.remove(id);
      return const Right(unit);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, Unit>> toggleFavorite(int id, bool isFavorite) async {
    try {
      await _librarySource.setFavorite(id, isFavorite);
      return const Right(unit);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  @override
  Future<Either<Exception, Unit>> updateProgress(int id, int lastPage) async {
    try {
      await _librarySource.setLastPage(id, lastPage);
      return const Right(unit);
    } catch (e) {
      return Left(Exception(e.toString()));
    }
  }

  /// Strips a trailing `.pdf` (case-insensitive) to produce a readable title.
  String _deriveTitle(String fileName) {
    final trimmed = fileName.trim();
    if (trimmed.toLowerCase().endsWith('.pdf')) {
      return trimmed.substring(0, trimmed.length - 4).trim();
    }
    return trimmed;
  }
}
