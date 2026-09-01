import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../../data/backup/photo_store.dart';

/// [PhotoStore] backed by the app-private photos directory. Files are
/// named `<hex>.jpg` / `<hex>_thumb.jpg` and never include path segments,
/// but names coming from backups are untrusted — writes are validated.
class DirectoryPhotoStore implements PhotoStore {
  DirectoryPhotoStore(this._dirProvider);

  final Future<Directory> Function() _dirProvider;

  @override
  Future<List<StoredFile>> readAll() async {
    final dir = await _dirProvider();
    if (!await dir.exists()) return const [];
    final files = <StoredFile>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (name == '.nomedia') continue;
      files.add(StoredFile(name: name, bytes: await entity.readAsBytes()));
    }
    return files;
  }

  @override
  Future<void> clear() async {
    final dir = await _dirProvider();
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is File && p.basename(entity.path) != '.nomedia') {
        await entity.delete();
      }
    }
  }

  @override
  Future<void> write(String name, Uint8List bytes) async {
    if (!_isValidName(name)) {
      throw ArgumentError.value(name, 'name', 'unsafe file name');
    }
    final dir = await _dirProvider();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    await File(p.join(dir.path, name)).writeAsBytes(bytes);
  }

  static bool _isValidName(String name) {
    if (name.isEmpty) return false;
    if (name.contains('..')) return false;
    if (name.contains('/') || name.contains('\\')) return false;
    if (name.startsWith('.')) return false;
    return true;
  }
}
