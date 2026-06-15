import 'package:dartz/dartz.dart';
import '../entities/book_entity.dart';
import '../repositories/reading_book_repository.dart';

class GetBookGallery {
  final ReadingBookRepository _repo;
  GetBookGallery(this._repo);
  Future<Either<Exception, List<BookEntity>>> call() => _repo.getGallery();
}
