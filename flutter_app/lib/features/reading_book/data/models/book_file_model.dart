import '../../domain/entities/book_file_entity.dart';

class BookFileModel extends BookFileEntity {
  const BookFileModel({
    required super.path,
    required super.name,
    required super.sizeBytes,
  });

  /// Builds a model from a full file [path], deriving the display name from the
  /// last path segment (handles both `/` and `\` separators).
  factory BookFileModel.fromPath(String path, int sizeBytes) {
    final normalized = path.replaceAll('\\', '/');
    final name = normalized.contains('/')
        ? normalized.substring(normalized.lastIndexOf('/') + 1)
        : normalized;
    return BookFileModel(path: path, name: name, sizeBytes: sizeBytes);
  }
}
