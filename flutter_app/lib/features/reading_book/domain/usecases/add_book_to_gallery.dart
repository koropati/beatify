import 'package:dartz/dartz.dart';
import '../entities/book_entity.dart';
import '../entities/book_file_entity.dart';
import '../repositories/reading_book_repository.dart';

class AddBookToGallery {
  final ReadingBookRepository _repo;
  AddBookToGallery(this._repo);
  Future<Either<Exception, BookEntity>> call(BookFileEntity file) =>
      _repo.addToGallery(file);
}
