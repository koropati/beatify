import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/entities/book_file_entity.dart';
import '../providers/reading_book_providers.dart';
import 'book_reader_page.dart';

class ReadingBookPage extends ConsumerStatefulWidget {
  const ReadingBookPage({super.key});

  @override
  ConsumerState<ReadingBookPage> createState() => _ReadingBookPageState();
}

class _ReadingBookPageState extends ConsumerState<ReadingBookPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Reading',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1DB954),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFB3B3B3),
          tabs: const [
            Tab(text: 'Galeri Buku'),
            Tab(text: 'Favorit'),
            Tab(text: 'Galeri File'),
          ],
        ),
      ),
      body: Column(
        children: [
          const _SearchField(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _GalleryTab(),
                _FavoritesTab(),
                _FileGalleryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(bookSearchQueryProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        onChanged: (v) => ref.read(bookSearchQueryProvider.notifier).state = v,
        decoration: InputDecoration(
          hintText: 'Cari buku atau file...',
          hintStyle: const TextStyle(color: Color(0xFF727272)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFB3B3B3)),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFFB3B3B3)),
                  onPressed: () {
                    _controller.clear();
                    ref.read(bookSearchQueryProvider.notifier).state = '';
                  },
                ),
          filled: true,
          fillColor: const Color(0xFF1A1A2E),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

Future<void> _openBook(BuildContext context, WidgetRef ref, BookEntity book) async {
  final lastPage = await Navigator.of(context).push<int>(
    MaterialPageRoute(builder: (_) => BookReaderPage(book: book)),
  );
  if (lastPage != null && lastPage != book.lastPage) {
    await ref.read(bookGalleryControllerProvider).updateProgress(book.id, lastPage);
  }
}

class _GalleryTab extends ConsumerWidget {
  const _GalleryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(filteredBookGalleryProvider);
    final searching = ref.watch(bookSearchQueryProvider).trim().isNotEmpty;
    return booksAsync.when(
      data: (books) {
        if (books.isEmpty) {
          return _EmptyState(
            icon: searching ? Icons.search_off : Icons.menu_book_outlined,
            message: searching ? 'Tidak ada buku cocok' : 'Belum ada buku di galeri',
            hint: searching
                ? 'Coba kata kunci lain'
                : 'Tambahkan PDF dari tab Galeri File',
          );
        }
        return RefreshIndicator(
          color: const Color(0xFF1DB954),
          onRefresh: () async => ref.invalidate(bookGalleryProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            itemBuilder: (_, i) => _BookTile(book: books[i]),
          ),
        );
      },
      loading: () => const _Loading(),
      error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(bookGalleryProvider)),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(filteredFavoriteBooksProvider);
    final searching = ref.watch(bookSearchQueryProvider).trim().isNotEmpty;
    return favoritesAsync.when(
      data: (books) {
        if (books.isEmpty) {
          return _EmptyState(
            icon: searching ? Icons.search_off : Icons.favorite_border,
            message: searching ? 'Tidak ada favorit cocok' : 'Belum ada buku favorit',
            hint: searching ? 'Coba kata kunci lain' : 'Tandai buku dengan ikon hati',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: books.length,
          itemBuilder: (_, i) => _BookTile(book: books[i]),
        );
      },
      loading: () => const _Loading(),
      error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(bookGalleryProvider)),
    );
  }
}

class _FileGalleryTab extends ConsumerWidget {
  const _FileGalleryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(filteredDeviceBookFilesProvider);
    final galleryAsync = ref.watch(bookGalleryProvider);
    final searching = ref.watch(bookSearchQueryProvider).trim().isNotEmpty;
    final existingPaths = {
      for (final b in (galleryAsync.value ?? const <BookEntity>[])) b.filePath,
    };

    return filesAsync.when(
      data: (files) {
        if (files.isEmpty) {
          return _EmptyState(
            icon: searching ? Icons.search_off : Icons.folder_open,
            message: searching ? 'Tidak ada file cocok' : 'Tidak ada PDF ditemukan',
            hint: searching
                ? 'Coba kata kunci lain'
                : 'Tarik ke bawah untuk memindai ulang',
            onRefresh: () => ref.invalidate(deviceBookFilesProvider),
          );
        }
        return RefreshIndicator(
          color: const Color(0xFF1DB954),
          onRefresh: () async => ref.invalidate(deviceBookFilesProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: files.length,
            itemBuilder: (_, i) => _FileTile(
              file: files[i],
              alreadyAdded: existingPaths.contains(files[i].path),
            ),
          ),
        );
      },
      loading: () => const _Loading(),
      error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(deviceBookFilesProvider)),
    );
  }
}

class _BookTile extends ConsumerWidget {
  const _BookTile({required this.book});
  final BookEntity book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(bookGalleryControllerProvider);
    return Card(
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 44,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF282828),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.picture_as_pdf, color: Color(0xFFE91E63)),
        ),
        title: Text(
          book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          book.lastPage > 0 ? 'Halaman ${book.lastPage + 1}' : 'Belum dibaca',
          style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
        ),
        onTap: () => _openBook(context, ref, book),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                book.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: book.isFavorite ? const Color(0xFFE91E63) : const Color(0xFFB3B3B3),
              ),
              onPressed: () => controller.toggleFavorite(book.id, !book.isFavorite),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFB3B3B3)),
              onPressed: () => controller.removeFromGallery(book.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileTile extends ConsumerWidget {
  const _FileTile({required this.file, required this.alreadyAdded});
  final BookFileEntity file;
  final bool alreadyAdded;

  String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFE91E63)),
        title: Text(
          file.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        subtitle: Text(
          _size(file.sizeBytes),
          style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
        ),
        trailing: alreadyAdded
            ? const Icon(Icons.check_circle, color: Color(0xFF1DB954))
            : IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1DB954)),
                tooltip: 'Tambah ke Galeri Buku',
                onPressed: () async {
                  await ref.read(bookGalleryControllerProvider).addToGallery(file);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ditambahkan ke Galeri Buku')),
                    );
                  }
                },
              ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.hint,
    this.onRefresh,
  });
  final IconData icon;
  final String message;
  final String hint;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: const Color(0xFFB3B3B3)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 16)),
          const SizedBox(height: 8),
          Text(hint, style: const TextStyle(color: Color(0xFF727272), fontSize: 13)),
        ],
      ),
    );
    if (onRefresh == null) return content;
    return RefreshIndicator(
      color: const Color(0xFF1DB954),
      onRefresh: () async => onRefresh!(),
      child: ListView(children: [SizedBox(height: 240, child: content)]),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB3B3B3), size: 48),
          const SizedBox(height: 12),
          const Text('Terjadi kesalahan', style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba lagi', style: TextStyle(color: Color(0xFF1DB954))),
          ),
        ],
      ),
    );
  }
}
