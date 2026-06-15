import 'package:dartz/dartz.dart';
import '../entities/book_file_entity.dart';
import '../repositories/reading_book_repository.dart';

class ScanDevicePdfs {
  final ReadingBookRepository _repo;
  ScanDevicePdfs(this._repo);
  Future<Either<Exception, List<BookFileEntity>>> call() => _repo.scanDevicePdfs();
}
