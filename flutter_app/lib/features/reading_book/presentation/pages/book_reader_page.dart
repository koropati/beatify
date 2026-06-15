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
  final _thumbCache = <int, Uint8List?>{};
  final _currentPageNotifier = ValueNotifier<int>(0);
  Future<void> _renderQueue = Future<void>.value();

  PdfDocument? _doc;
  List<Widget> _pages = const [];
  int _pageCount = 0;
  int _currentPage = 0;
  bool _loading = true;
  bool _showNavigator = false;
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

  /// Renders a small thumbnail for the page navigator. Cached separately from
  /// the full-resolution page bitmaps.
  Future<Uint8List?> _renderThumb(int index) {
    final completer = Completer<Uint8List?>();
    _renderQueue = _renderQueue.then((_) async {
      if (_thumbCache.containsKey(index)) {
        completer.complete(_thumbCache[index]);
        return;
      }
      final doc = _doc;
      if (doc == null) {
        completer.complete(null);
        return;
      }
      try {
        final page = await doc.getPage(index + 1);
        const width = 140.0;
        final height = page.height * (width / page.width);
        final image = await page.render(
          width: width,
          height: height,
          format: PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFF',
        );
        await page.close();
        _thumbCache[index] = image?.bytes;
        completer.complete(image?.bytes);
      } catch (_) {
        _thumbCache[index] = null;
        completer.complete(null);
      }
    });
    return completer.future;
  }

  /// Jumps directly to [index], e.g. from the page navigator.
  void _goToPage(int index) {
    final clamped = index.clamp(0, max(0, _pageCount - 1)).toInt();
    _flipController.goToPage(clamped);
    _currentPageNotifier.value = clamped;
    if (clamped != _currentPage) setState(() => _currentPage = clamped);
    _evictOutside(clamped);
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
          if (!_loading && _error == null && _pageCount > 0) ...[
            Center(
              child: Text(
                '${_currentPage + 1} / $_pageCount',
                style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
              ),
            ),
            IconButton(
              tooltip: 'Daftar halaman',
              icon: Icon(
                _showNavigator ? Icons.grid_view : Icons.grid_view_outlined,
                color: _showNavigator ? const Color(0xFF1DB954) : Colors.white,
              ),
              onPressed: () => setState(() => _showNavigator = !_showNavigator),
            ),
          ],
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

    return Stack(
      children: [
        PageFlipWidget(
          key: ValueKey(widget.book.id),
          controller: _flipController,
          backgroundColor: _BookReaderColors.paper,
          initialIndex: _currentPage,
          lastPage: const _LastPage(),
          onPageFlipped: _onPageFlipped,
          children: _pages,
        ),
        if (_showNavigator)
          Align(
            alignment: Alignment.bottomCenter,
            child: _PageNavigator(
              pageCount: _pageCount,
              currentPage: _currentPageNotifier,
              onGoTo: _goToPage,
              renderThumb: _renderThumb,
            ),
          ),
      ],
    );
  }
}

/// Bottom panel showing a slider and a scrollable thumbnail strip to jump to any
/// page quickly — handy to resume from a page read on another platform.
class _PageNavigator extends StatelessWidget {
  const _PageNavigator({
    required this.pageCount,
    required this.currentPage,
    required this.onGoTo,
    required this.renderThumb,
  });

  final int pageCount;
  final ValueListenable<int> currentPage;
  final void Function(int index) onGoTo;
  final Future<Uint8List?> Function(int index) renderThumb;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: currentPage,
      builder: (context, value, _) {
        final current = value.clamp(0, max(0, pageCount - 1)).toInt();
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xF21D1A16),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Halaman ${current + 1} dari $pageCount',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              if (pageCount > 1)
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF1DB954),
                    thumbColor: const Color(0xFF1DB954),
                    inactiveTrackColor: const Color(0xFF4A4A4A),
                    overlayColor: const Color(0x331DB954),
                  ),
                  child: Slider(
                    value: current.toDouble(),
                    min: 0,
                    max: (pageCount - 1).toDouble(),
                    divisions: pageCount - 1,
                    label: '${current + 1}',
                    onChanged: (v) => onGoTo(v.round()),
                  ),
                ),
              SizedBox(
                height: 132,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: pageCount,
                  itemBuilder: (context, index) => _ThumbTile(
                    index: index,
                    selected: index == current,
                    render: renderThumb,
                    onTap: () => onGoTo(index),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThumbTile extends StatefulWidget {
  const _ThumbTile({
    required this.index,
    required this.selected,
    required this.render,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final Future<Uint8List?> Function(int index) render;
  final VoidCallback onTap;

  @override
  State<_ThumbTile> createState() => _ThumbTileState();
}

class _ThumbTileState extends State<_ThumbTile> {
  late final Future<Uint8List?> _future = widget.render(widget.index);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _BookReaderColors.paper,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: widget.selected
                        ? const Color(0xFF1DB954)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: FutureBuilder<Uint8List?>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1DB954),
                          ),
                        ),
                      );
                    }
                    final bytes = snapshot.data;
                    if (bytes == null) {
                      return const Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: Color(0xFF9E9E9E), size: 20),
                      );
                    }
                    return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
                  },
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.index + 1}',
              style: TextStyle(
                color: widget.selected ? const Color(0xFF1DB954) : const Color(0xFFB3B3B3),
                fontSize: 12,
                fontWeight: widget.selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
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
