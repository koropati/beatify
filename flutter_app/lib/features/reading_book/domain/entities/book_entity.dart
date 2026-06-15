/// A PDF book the user added to their gallery, readable offline.
class BookEntity {
  final int id;
  final String filePath;
  final String title;
  final bool isFavorite;
  final int lastPage;
  final DateTime addedAt;

  const BookEntity({
    required this.id,
    required this.filePath,
    required this.title,
    this.isFavorite = false,
    this.lastPage = 0,
    required this.addedAt,
  });

  BookEntity copyWith({
    int? id,
    String? filePath,
    String? title,
    bool? isFavorite,
    int? lastPage,
    DateTime? addedAt,
  }) {
    return BookEntity(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      isFavorite: isFavorite ?? this.isFavorite,
      lastPage: lastPage ?? this.lastPage,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
