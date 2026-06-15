/// A PDF file discovered on the device that is not yet in the user's gallery.
class BookFileEntity {
  final String path;
  final String name;
  final int sizeBytes;

  const BookFileEntity({
    required this.path,
    required this.name,
    required this.sizeBytes,
  });
}
