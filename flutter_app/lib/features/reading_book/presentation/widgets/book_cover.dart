import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

/// Renders the first page of a PDF as a book cover. Results are cached in memory
/// (per file path) and renders are serialised, so each book is rendered once and
/// the heavy PDF backend is never hit in parallel.
class BookCover extends StatefulWidget {
  const BookCover({super.key, required this.filePath, this.fit = BoxFit.cover});

  final String filePath;
  final BoxFit fit;

  @override
  State<BookCover> createState() => _BookCoverState();
}

class _BookCoverState extends State<BookCover> {
  static final _cache = <String, Uint8List?>{};
  static Future<void> _queue = Future<void>.value();

  Uint8List? _bytes;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_cache.containsKey(widget.filePath)) {
      setState(() {
        _bytes = _cache[widget.filePath];
        _done = true;
      });
      return;
    }
    final bytes = await _render(widget.filePath);
    if (mounted) {
      setState(() {
        _bytes = bytes;
        _done = true;
      });
    }
  }

  Future<Uint8List?> _render(String path) {
    final completer = Completer<Uint8List?>();
    _queue = _queue.then((_) async {
      if (_cache.containsKey(path)) {
        completer.complete(_cache[path]);
        return;
      }
      try {
        final doc = await PdfDocument.openFile(path);
        final page = await doc.getPage(1);
        const width = 240.0;
        final height = page.height * (width / page.width);
        final image = await page.render(
          width: width,
          height: height,
          format: PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFF',
        );
        await page.close();
        await doc.close();
        _cache[path] = image?.bytes;
        completer.complete(image?.bytes);
      } catch (_) {
        _cache[path] = null;
        completer.complete(null);
      }
    });
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    if (!_done) {
      return const ColoredBox(
        color: Color(0xFF282828),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1DB954)),
          ),
        ),
      );
    }
    final bytes = _bytes;
    if (bytes == null) {
      return const ColoredBox(
        color: Color(0xFF282828),
        child: Center(child: Icon(Icons.picture_as_pdf, color: Color(0xFFE91E63))),
      );
    }
    return Image.memory(bytes, fit: widget.fit, gaplessPlayback: true);
  }
}
