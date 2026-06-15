import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:page_flip/page_flip.dart';
import 'package:pdfx/pdfx.dart';
import '../../domain/entities/book_entity.dart';

/// Renders a PDF book page-by-page with a realistic paper-curl flip animation.
///
/// Only a small window of pages around the current page is rendered to a bitmap
/// at any time; pages outside the window stay as lightweight placeholders and
/// their cached bitmaps are evicted, so memory stays bounded even for very long
/// books.
class BookReaderPage extends StatefulWidget {
  const BookReaderPage({super.key, required this.book});
  final BookEntity book;

  /// Pages on each side of the current page that are rendered to a bitmap.
  static const renderRadius = 2;

  /// Extra pages (beyond the render window) whose bitmaps are kept cached
  /// before being evicted, to make short back-and-forth flips re-render-free.
  static const cacheRadius = renderRadius + 2;

  @override
  State<BookReaderPage> createState() => _BookReaderPageState();
}

class _BookReaderPageState extends State<BookReaderPage> {
  final _flipController = PageFlipController();
  final _cache = <int, Uint8List?>{};
  final _currentPageNotifier = ValueNotifier<int>(0);
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
      _currentPageNotifier.value = initial;
      setState(() {
        _doc = doc;
        _pageCount = count;
        _currentPage = initial;
        _pages = List.generate(
          count,
          (i) => _ReaderPageView(
            index: i,
            currentPage: _currentPageNotifier,
            renderRadius: BookReaderPage.renderRadius,
            isAttempted: _isAttempted,
            peek: _peek,
            ensure: _renderPage,
          ),
        );
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool _isAttempted(int index) => _cache.containsKey(index);

  Uint8List? _peek(int index) => _cache[index];

  /// Renders [index] (0-based) lazily, serialising renders since the Android
  /// PDF backend does not allow parallel rendering. Result is cached.
  Future<Uint8List?> _renderPage(int index) {
    final completer = Completer<Uint8List?>();
    _renderQueue = _renderQueue.then((_) async {
      if (_cache.containsKey(index)) {
        completer.complete(_cache[index]);
        return;
      }
      final doc = _doc;
      if (doc == null) {
        completer.complete(null);
        return;
      }
      try {
        final page = await doc.getPage(index + 1);
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

  /// Drops cached bitmaps further than [BookReaderPage.cacheRadius] from
  /// [center] to keep memory bounded.
  void _evictOutside(int center) {
    _cache.removeWhere(
      (page, _) => (page - center).abs() > BookReaderPage.cacheRadius,
    );
  }

  void _onPageFlipped(int page) {
    _currentPageNotifier.value = page;
    final clamped = page.clamp(0, max(0, _pageCount - 1)).toInt();
    if (clamped != _currentPage) setState(() => _currentPage = clamped);
    _evictOutside(page);
  }

  @override
  void dispose() {
    _currentPageNotifier.dispose();
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
      backgroundColor: _BookReaderColors.paper,
      initialIndex: _currentPage,
      lastPage: const _LastPage(),
      onPageFlipped: _onPageFlipped,
      children: _pages,
    );
  }
}

/// One page of the reader. Renders its PDF bitmap only while it sits inside the
/// render window around the current page; otherwise it shows a cheap placeholder.
class _ReaderPageView extends StatefulWidget {
  const _ReaderPageView({
    required this.index,
    required this.currentPage,
    required this.renderRadius,
    required this.isAttempted,
    required this.peek,
    required this.ensure,
  });

  final int index;
  final ValueListenable<int> currentPage;
  final int renderRadius;
  final bool Function(int index) isAttempted;
  final Uint8List? Function(int index) peek;
  final Future<Uint8List?> Function(int index) ensure;

  @override
  State<_ReaderPageView> createState() => _ReaderPageViewState();
}

class _ReaderPageViewState extends State<_ReaderPageView> {
  @override
  void initState() {
    super.initState();
    widget.currentPage.addListener(_onCurrentPageChanged);
    _maybeRender();
  }

  @override
  void dispose() {
    widget.currentPage.removeListener(_onCurrentPageChanged);
    super.dispose();
  }

  bool get _inWindow =>
      (widget.index - widget.currentPage.value).abs() <= widget.renderRadius;

  void _onCurrentPageChanged() {
    if (_inWindow) {
      _maybeRender();
    } else if (mounted) {
      setState(() {}); // fall back to the lightweight placeholder
    }
  }

  Future<void> _maybeRender() async {
    if (!_inWindow) return;
    if (widget.isAttempted(widget.index)) {
      if (mounted) setState(() {});
      return;
    }
    await widget.ensure(widget.index);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _BookReaderColors.paper,
      alignment: Alignment.center,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (!_inWindow) {
      return const _PagePlaceholder();
    }
    if (!widget.isAttempted(widget.index)) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)));
    }
    final bytes = widget.peek(widget.index);
    if (bytes == null) {
      return const Center(
        child: Icon(Icons.broken_image_outlined, color: Color(0xFF9E9E9E), size: 48),
      );
    }
    return Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true);
  }
}

class _PagePlaceholder extends StatelessWidget {
  const _PagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.menu_book_outlined, color: Color(0xFFD8CFB8), size: 40),
    );
  }
}

class _LastPage extends StatelessWidget {
  const _LastPage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _BookReaderColors.paper,
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

class _BookReaderColors {
  const _BookReaderColors._();
  static const paper = Color(0xFFF3ECDD);
}
