import 'dart:typed_data';

/// A named blob stored alongside the database in backups (photo files).
class StoredFile {
  const StoredFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// File-level access to the app's photo storage. Injected into the backup
/// service so export/import can run against in-memory fakes in tests.
abstract class PhotoStore {
  /// All stored files (full-size images and thumbnails).
  Future<List<StoredFile>> readAll();

  /// Removes every stored file.
  Future<void> clear();

  /// Writes one file. Implementations must reject names that could escape
  /// the storage directory.
  Future<void> write(String name, Uint8List bytes);
}
