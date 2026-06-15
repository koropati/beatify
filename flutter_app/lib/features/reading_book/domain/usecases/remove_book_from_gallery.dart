import 'package:dartz/dartz.dart';
import '../repositories/reading_book_repository.dart';

class RemoveBookFromGallery {
  final ReadingBookRepository _repo;
  RemoveBookFromGallery(this._repo);
  Future<Either<Exception, Unit>> call(int id) => _repo.removeFromGallery(id);
}
