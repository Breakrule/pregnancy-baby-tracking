import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/db/tables.dart';
import 'package:nurture/data/providers.dart';
import 'package:nurture/data/repositories/photo_repository.dart';
import 'package:nurture/features/shared/photos/gallery_screen.dart';
import 'package:nurture/features/shared/photos/photo_service.dart';
import 'package:path/path.dart' as p;

import '../../../test_app.dart';

class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker(this.fileToReturn);

  final File? fileToReturn;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = false,
  }) {
    if (fileToReturn == null) return Future.value(null);
    return Future.value(XFile(fileToReturn!.path));
  }
}

Uint8List _solidJpeg(int width, int height) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgba8(10, 120, 200, 255));
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}

/// Capture seam for the flow test: writes real (small) files synchronously
/// instead of running isolate compression, which does not play well with
/// FakeAsync. Compression itself is covered in photo_service_test.dart.
class _InstantPhotoService extends PhotoService {
  _InstantPhotoService(this._dir) : super(ImagePicker(), () async => _dir);

  final Directory _dir;

  @override
  Future<CapturedPhoto?> capture({required ImageSource source}) async {
    const name = 'test.jpg';
    final bytes = _solidJpeg(40, 30);
    // Sync writes: real async I/O never completes under FakeAsync.
    File(p.join(_dir.path, name)).writeAsBytesSync(bytes);
    File(p.join(_dir.path, 'test_thumb.jpg')).writeAsBytesSync(bytes);
    return const CapturedPhoto(fileName: name, sizeBytes: 3);
  }
}

void main() {
  late AppDatabase db;
  late Directory tempDir;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = Directory.systemTemp.createTempSync('nurture-gallery');
  });

  tearDown(() async {
    await db.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {
      // Background isolate work may still hold a file briefly; ignore.
    }
  });

  Widget wrap(Widget child, {File? pickedFile, PhotoService? service}) {
    final storage = Directory(p.join(tempDir.path, 'photos'))..createSync();
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        photoServiceProvider.overrideWithValue(
          service ??
              PhotoService(_FakeImagePicker(pickedFile), () async => storage),
        ),
      ],
      child: localizedApp(child),
    );
  }

  testWidgets('shows empty state when no photos exist', (tester) async {
    await tester.pumpWidget(
      wrap(const GalleryScreen(category: PhotoCategory.belly)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No photos yet'), findsOneWidget);
    expect(find.byKey(const Key('photo-add-fab')), findsOneWidget);

    // Tear down the provider tree to cancel Drift stream timers.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('renders a tile per stored photo', (tester) async {
    await PhotoRepository(db).add(
      category: PhotoCategory.belly,
      takenAt: DateTime.utc(2026, 3, 1),
      fileName: 'x.jpg',
      gestationalDays: 70,
    );

    await tester.pumpWidget(
      wrap(const GalleryScreen(category: PhotoCategory.belly)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('photo-1')), findsOneWidget);
    // Gestational badge + missing-file placeholder.
    expect(find.text('Week 10'), findsOneWidget);
    expect(find.byIcon(Icons.image_not_supported), findsOneWidget);

    // Tear down the provider tree to cancel Drift stream timers.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('add flow: capture, confirm, saves a row', (tester) async {
    final storageDir = Directory(p.join(tempDir.path, 'photos'));

    await tester.pumpWidget(
      wrap(
        const GalleryScreen(category: PhotoCategory.belly),
        service: _InstantPhotoService(storageDir),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('photo-add-fab')));
    await tester.pumpAndSettle();

    // Step 1: pick a source.
    expect(find.byKey(const Key('photo-source-camera')), findsOneWidget);
    await tester.tap(find.byKey(const Key('photo-source-camera')));
    await tester.pumpAndSettle();

    // Step 2: details with save button.
    expect(find.byKey(const Key('photo-save-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('photo-save-button')));
    await tester.pumpAndSettle();

    // Row persisted with the right category (one-shot select: Drift watch
    // streams do not deliver under FakeAsync).
    final rows = await db.select(db.photos).get();
    expect(rows, hasLength(1));
    expect(rows.single.category, PhotoCategory.belly);
    // Full-size and thumbnail files exist on disk.
    final stored = File(p.join(tempDir.path, 'photos', rows.single.fileName));
    expect(stored.existsSync(), isTrue);

    // Tear down the provider tree to cancel Drift stream timers.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
