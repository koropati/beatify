import 'package:dartz/dartz.dart';
import '../repositories/reading_book_repository.dart';

class ToggleBookFavorite {
  final ReadingBookRepository _repo;
  ToggleBookFavorite(this._repo);
  Future<Either<Exception, Unit>> call(int id, bool isFavorite) =>
      _repo.toggleFavorite(id, isFavorite);
}
