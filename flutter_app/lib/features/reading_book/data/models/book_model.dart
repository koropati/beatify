import '../../domain/entities/book_entity.dart';

class BookModel extends BookEntity {
  const BookModel({
    required super.id,
    required super.filePath,
    required super.title,
    super.isFavorite,
    super.lastPage,
    required super.addedAt,
  });

  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      id: map['id'] as int,
      filePath: map['file_path'] as String,
      title: map['title'] as String,
      isFavorite: (map['is_favorite'] as int) == 1,
      lastPage: map['last_page'] as int,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['added_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_path': filePath,
      'title': title,
      'is_favorite': isFavorite ? 1 : 0,
      'last_page': lastPage,
      'added_at': addedAt.millisecondsSinceEpoch,
    };
  }
}
