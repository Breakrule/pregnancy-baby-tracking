import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:nurture/features/shared/photos/photo_service.dart';
import 'package:path/path.dart' as p;

class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker(this.fileToReturn);

  final File? fileToReturn;
  ImageSource? lastSource;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = false,
  }) {
    lastSource = source;
    if (fileToReturn == null) return Future.value(null);
    return Future.value(XFile(fileToReturn!.path));
  }
}

Uint8List encodeSolidImage(int width, int height) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgba8(200, 100, 50, 255));
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}

void main() {
  group('PhotoService.compress', () {
    test('downscales to the max long edge and reports dimensions', () async {
      final bytes = encodeSolidImage(3200, 2400);

      final result = await PhotoService.compress(bytes, maxLongEdge: 1600);

      expect(result.width, 1600);
      expect(result.height, 1200);
      expect(result.bytes, isNotEmpty);
      // Re-encoded JPEG must be decodable.
      final decoded = img.decodeImage(result.bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, 1600);
      expect(decoded.height, 1200);
    });

    test('keeps portrait orientation edges correct', () async {
      final bytes = encodeSolidImage(1000, 2000);

      final result = await PhotoService.compress(bytes, maxLongEdge: 800);

      expect(result.width, 400);
      expect(result.height, 800);
    });

    test('leaves small images untouched in size', () async {
      final bytes = encodeSolidImage(640, 480);

      final result = await PhotoService.compress(bytes, maxLongEdge: 1600);

      expect(result.width, 640);
      expect(result.height, 480);
    });

    test('rejects undecodable bytes', () async {
      expect(
        PhotoService.compress(Uint8List.fromList([1, 2, 3])),
        throwsFormatException,
      );
    });
  });

  group('PhotoService.capture', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('nurture-photos');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('writes full-size and thumbnail files into storage', () async {
      final sourceFile = File(p.join(tempDir.path, 'raw.jpg'))
        ..writeAsBytesSync(encodeSolidImage(2000, 1500));
      final storage = Directory(p.join(tempDir.path, 'store'))..createSync();
      final service = PhotoService(
        _FakeImagePicker(sourceFile),
        () async => storage,
      );

      final captured = await service.capture(source: ImageSource.camera);

      expect(captured, isNotNull);
      expect(captured!.sizeBytes, greaterThan(0));
      final full = File(p.join(storage.path, captured.fileName));
      final thumb = File(
        p.join(storage.path, captured.fileName.replaceFirst('.jpg', '_thumb.jpg')),
      );
      expect(full.existsSync(), isTrue);
      expect(thumb.existsSync(), isTrue);
      // Thumbnail is small.
      final thumbDecoded = img.decodeImage(thumb.readAsBytesSync())!;
      expect(max(thumbDecoded.width, thumbDecoded.height), lessThanOrEqualTo(320));
      // Storage dir is hidden from the media scanner.
      expect(File(p.join(storage.path, '.nomedia')).existsSync(), isTrue);
    });

    test('returns null when the user cancels', () async {
      final storage = Directory(p.join(tempDir.path, 'store2'))..createSync();
      final picker = _FakeImagePicker(null);
      final service = PhotoService(picker, () async => storage);

      final captured = await service.capture(source: ImageSource.gallery);

      expect(captured, isNull);
      expect(picker.lastSource, ImageSource.gallery);
    });
  });
}
