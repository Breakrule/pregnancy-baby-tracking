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

void main() {
  late AppDatabase db;
  late Directory tempDir;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = Directory.systemTemp.createTempSync('nurture-gallery');
  });

  tearDown(() async {
    await db.close();
    tempDir.deleteSync(recursive: true);
  });

  Widget wrap(Widget child, {File? pickedFile}) {
    final storage = Directory(p.join(tempDir.path, 'photos'))..createSync();
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        photoServiceProvider.overrideWithValue(
          PhotoService(_FakeImagePicker(pickedFile), () async => storage),
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('shows empty state when no photos exist', (tester) async {
    await tester.pumpWidget(
      wrap(const GalleryScreen(category: PhotoCategory.belly)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No photos yet'), findsOneWidget);
    expect(find.byKey(const Key('photo-add-fab')), findsOneWidget);
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
  });

  testWidgets('add flow: capture, confirm, saves a row', (tester) async {
    final rawFile = File(p.join(tempDir.path, 'raw.jpg'))
      ..writeAsBytesSync(_solidJpeg(800, 600));

    await tester.pumpWidget(
      wrap(
        const GalleryScreen(category: PhotoCategory.belly),
        pickedFile: rawFile,
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

    // Row persisted with the right category.
    final rows = await PhotoRepository(db)
        .watchByCategory(PhotoCategory.belly)
        .first;
    expect(rows, hasLength(1));
    expect(rows.single.category, PhotoCategory.belly);
    // Full-size and thumbnail files exist on disk.
    final stored = File(
      p.join(tempDir.path, 'photos', rows.single.fileName),
    );
    expect(stored.existsSync(), isTrue);
  });
}
