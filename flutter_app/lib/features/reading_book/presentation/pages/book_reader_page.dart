import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:page_flip/page_flip.dart';
import 'package:pdfx/pdfx.dart';
import '../../domain/entities/book_entity.dart';

/// Renders a PDF book page-by-page with a realistic paper-curl flip animation.
class BookReaderPage extends StatefulWidget {
  const BookReaderPage({super.key, required this.book});
  final BookEntity book;

  @override
  State<BookReaderPage> createState() => _BookReaderPageState();
}

class _BookReaderPageState extends State<BookReaderPage> {
  static const _paper = Color(0xFFF3ECDD);

  final _flipController = PageFlipController();
  final _cache = <int, Uint8List?>{};
  Future<void> _renderQueue = Future<void>.value();

  PdfDocument? _doc;
  List<Widget> _pages = const [];
  int _pageCount = 0;
  int _currentPage = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.book.lastPage;
    _open();
  }

  Future<void> _open() async {
    try {
      final doc = await PdfDocument.openFile(widget.book.filePath);
      final count = doc.pagesCount;
      final initial = _currentPage.clamp(0, max(0, count - 1)).toInt();
      setState(() {
        _doc = doc;
        _pageCount = count;
        _currentPage = initial;
        _pages = List.generate(count, (i) => _PdfPageView(future: _renderPage(i)));
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Renders [index] (0-based) lazily, serialising renders since the Android
  /// PDF backend does not allow parallel rendering.
  Future<Uint8List?> _renderPage(int index) {
    final completer = Completer<Uint8List?>();
    _renderQueue = _renderQueue.then((_) async {
      if (_cache.containsKey(index)) {
        completer.complete(_cache[index]);
        return;
      }
      try {
        final page = await _doc!.getPage(index + 1);
        final image = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFF',
        );
        await page.close();
        _cache[index] = image?.bytes;
        completer.complete(image?.bytes);
      } catch (_) {
        _cache[index] = null;
        completer.complete(null);
      }
    });
    return completer.future;
  }

  @override
  void dispose() {
    _doc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161310),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161310),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(_currentPage),
        ),
        title: Text(
          widget.book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (!_loading && _error == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_currentPage + 1} / $_pageCount',
                  style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)));
    }
    if (_error != null || _pageCount == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined, size: 64, color: Color(0xFFB3B3B3)),
            const SizedBox(height: 16),
            Text(
              _error != null ? 'Gagal membuka buku' : 'Buku ini kosong',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return PageFlipWidget(
      key: ValueKey(widget.book.id),
      controller: _flipController,
      backgroundColor: _paper,
      initialIndex: _currentPage,
      lastPage: const _LastPage(),
      onPageFlipped: (page) {
        if (page <= _pageCount - 1) setState(() => _currentPage = page);
      },
      children: _pages,
    );
  }
}

class _PdfPageView extends StatelessWidget {
  const _PdfPageView({required this.future});
  final Future<Uint8List?> future;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3ECDD),
      alignment: Alignment.center,
      child: FutureBuilder<Uint8List?>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1DB954)),
            );
          }
          final bytes = snapshot.data;
          if (bytes == null) {
            return const Center(
              child: Icon(Icons.broken_image_outlined, color: Color(0xFF9E9E9E), size: 48),
            );
          }
          return Image.memory(bytes, fit: BoxFit.contain);
        },
      ),
    );
  }
}

class _LastPage extends StatelessWidget {
  const _LastPage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3ECDD),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_stories, size: 56, color: Color(0xFF8D6E63)),
          SizedBox(height: 12),
          Text(
            'Selesai',
            style: TextStyle(
              color: Color(0xFF5D4037),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
