import 'package:dartz/dartz.dart';
import '../repositories/reading_book_repository.dart';

class UpdateBookProgress {
  final ReadingBookRepository _repo;
  UpdateBookProgress(this._repo);
  Future<Either<Exception, Unit>> call(int id, int lastPage) =>
      _repo.updateProgress(id, lastPage);
}
