// coverage:ignore-file
// Wraps permission_handler + dart:io filesystem scan; exercised on device, not unit tests.
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/book_file_model.dart';

abstract class BookFileDataSource {
  Future<List<BookFileModel>> scanPdfs();
}

class BookFileDataSourceImpl implements BookFileDataSource {
  @override
  Future<List<BookFileModel>> scanPdfs() async {
    await _ensurePermission();

    final roots = await _candidateRoots();
    final seen = <String>{};
    final results = <BookFileModel>[];

    for (final root in roots) {
      if (!await root.exists()) continue;
      try {
        await for (final entity in root.list(recursive: true, followLinks: false)) {
          if (entity is! File) continue;
          final path = entity.path;
          if (!path.toLowerCase().endsWith('.pdf')) continue;
          if (!seen.add(path)) continue;
          try {
            results.add(BookFileModel.fromPath(path, await entity.length()));
          } catch (_) {
            // Skip files we cannot stat (permission/transient errors).
          }
        }
      } catch (_) {
        // Skip roots we cannot traverse.
      }
    }

    results.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return results;
  }

  Future<void> _ensurePermission() async {
    if (!Platform.isAndroid) return;
    // Android 11+ needs broad storage access to traverse shared folders.
    if (await Permission.manageExternalStorage.isGranted) return;
    final manage = await Permission.manageExternalStorage.request();
    if (manage.isGranted) return;
    await Permission.storage.request();
  }

  Future<List<Directory>> _candidateRoots() async {
    final dirs = <Directory>[];
    if (Platform.isAndroid) {
      dirs.addAll([
        Directory('/storage/emulated/0/Download'),
        Directory('/storage/emulated/0/Documents'),
        Directory('/storage/emulated/0/Books'),
        Directory('/storage/emulated/0/Download/Telegram'),
        Directory('/storage/emulated/0/WhatsApp/Media/WhatsApp Documents'),
      ]);
    }
    try {
      dirs.add(await getApplicationDocumentsDirectory());
    } catch (_) {}
    try {
      final ext = await getExternalStorageDirectory();
      if (ext != null) dirs.add(ext);
    } catch (_) {}
    return dirs;
  }
}
