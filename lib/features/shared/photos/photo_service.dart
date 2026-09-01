import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

/// Result of downscaling + re-encoding an image.
class CompressedImage {
  const CompressedImage({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

/// Metadata for a stored photo file, ready to be persisted in the DB.
class CapturedPhoto {
  const CapturedPhoto({required this.fileName, required this.sizeBytes});

  /// File name (relative to the photo storage directory) of the full-size
  /// image. The thumbnail is `<base>_thumb.jpg`.
  final String fileName;
  final int sizeBytes;
}

/// Captures or picks photos and stores them compressed in app-private
/// storage. Pure-Dart encoding keeps the app free of extra native plugins;
/// work runs on an isolate so the UI thread never stalls.
class PhotoService {
  PhotoService(this._picker, this._storageDir);

  final ImagePicker _picker;
  final Future<Directory> Function() _storageDir;

  static const fullMaxLongEdge = 1600;
  static const fullQuality = 82;
  static const thumbMaxLongEdge = 320;
  static const thumbQuality = 70;

  /// Picks an image from [source] (camera or gallery), compresses it, and
  /// writes full-size + thumbnail files into storage. Returns null when the
  /// user cancels.
  Future<CapturedPhoto?> capture({required ImageSource source}) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return null;

    final raw = await picked.readAsBytes();
    final full = await compress(
      raw,
      maxLongEdge: fullMaxLongEdge,
      quality: fullQuality,
    );
    final thumb = await compress(
      raw,
      maxLongEdge: thumbMaxLongEdge,
      quality: thumbQuality,
    );

    final dir = await _ensureDir();
    final base = _randomName();
    final fullFile = File(p.join(dir.path, '$base.jpg'));
    await fullFile.writeAsBytes(full.bytes);
    await File(p.join(dir.path, '${base}_thumb.jpg')).writeAsBytes(thumb.bytes);

    return CapturedPhoto(fileName: '$base.jpg', sizeBytes: full.bytes.length);
  }

  /// Absolute path of a stored photo (or its thumbnail).
  Future<File> fileFor(String fileName, {bool thumbnail = false}) async {
    final dir = await _storageDir();
    final name = thumbnail
        ? fileName.replaceFirst('.jpg', '_thumb.jpg')
        : fileName;
    return File(p.join(dir.path, name));
  }

  /// Deletes both the full-size and thumbnail files for [fileName].
  /// Missing files are ignored (deleting a photo must never throw).
  Future<void> deleteFiles(String fileName) async {
    final dir = await _storageDir();
    for (final name in [
      fileName,
      fileName.replaceFirst('.jpg', '_thumb.jpg'),
    ]) {
      final file = File(p.join(dir.path, name));
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  /// Downscale to [maxLongEdge] and re-encode as JPEG with [quality].
  /// EXIF metadata (incl. GPS) is dropped by the re-encode; the EXIF
  /// orientation is baked into pixels first.
  static Future<CompressedImage> compress(
    Uint8List bytes, {
    int maxLongEdge = fullMaxLongEdge,
    int quality = fullQuality,
  }) async {
    try {
      return await Isolate.run(() {
        img.Image? decoded;
        try {
          decoded = img.decodeImage(bytes);
        } catch (_) {
          // Decoders throw assorted errors (RangeError etc.) on garbage.
          throw const FormatException('Unsupported or corrupt image');
        }
        if (decoded == null) {
          throw const FormatException('Unsupported or corrupt image');
        }
        final oriented = img.bakeOrientation(decoded);
        final longEdge = max(oriented.width, oriented.height);
        var out = oriented;
        if (longEdge > maxLongEdge) {
          final scale = maxLongEdge / longEdge;
          out = img.copyResize(
            oriented,
            width: (oriented.width * scale).round(),
            height: (oriented.height * scale).round(),
            interpolation: img.Interpolation.linear,
          );
        }
        final encoded = Uint8List.fromList(
          img.encodeJpg(out, quality: quality),
        );
        return CompressedImage(
          bytes: encoded,
          width: out.width,
          height: out.height,
        );
      });
    } catch (e, st) {
      // Errors cross the isolate boundary as RemoteError; surface bad input
      // as a plain FormatException so callers can handle it.
      if (e.toString().contains('Unsupported or corrupt image')) {
        Error.throwWithStackTrace(
          const FormatException('Unsupported or corrupt image'),
          st,
        );
      }
      rethrow;
    }
  }

  Future<Directory> _ensureDir() async {
    final dir = await _storageDir();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    // Keep private family photos out of the device's media scanner.
    final nomedia = File(p.join(dir.path, '.nomedia'));
    if (!await nomedia.exists()) {
      await nomedia.create();
    }
    return dir;
  }

  static String _randomName() {
    final random = Random.secure();
    final hex = List<String>.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return hex;
  }
}
