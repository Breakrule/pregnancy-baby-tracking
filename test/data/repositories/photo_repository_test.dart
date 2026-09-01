import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/db/tables.dart';
import 'package:nurture/data/repositories/photo_repository.dart';

void main() {
  late AppDatabase db;
  late PhotoRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PhotoRepository(db);
  });

  tearDown(() => db.close());

  test(
    'add and watchByCategory only emit that category, takenAt ascending',
    () async {
      await repo.add(
        category: PhotoCategory.belly,
        takenAt: DateTime.utc(2026, 3, 2),
        fileName: 'b.jpg',
        gestationalDays: 70,
      );
      await repo.add(
        category: PhotoCategory.belly,
        takenAt: DateTime.utc(2026, 2, 1),
        fileName: 'a.jpg',
        gestationalDays: 35,
      );
      await repo.add(
        category: PhotoCategory.ultrasound,
        takenAt: DateTime.utc(2026, 2, 15),
        fileName: 'u.jpg',
        gestationalDays: 49,
      );

      final belly = await repo.watchByCategory(PhotoCategory.belly).first;
      expect(belly.map((p) => p.fileName), ['a.jpg', 'b.jpg']);

      final ultrasound = await repo
          .watchByCategory(PhotoCategory.ultrasound)
          .first;
      expect(ultrasound.single.fileName, 'u.jpg');
    },
  );

  test('delete removes the row', () async {
    final id = await repo.add(
      category: PhotoCategory.baby,
      takenAt: DateTime.utc(2026, 6, 1),
      fileName: 'baby.jpg',
    );

    await repo.delete(id);

    final baby = await repo.watchByCategory(PhotoCategory.baby).first;
    expect(baby, isEmpty);
  });

  test('notes and gestational days round-trip', () async {
    await repo.add(
      category: PhotoCategory.ultrasound,
      takenAt: DateTime.utc(2026, 4, 1),
      fileName: 'scan.jpg',
      gestationalDays: 84,
      notes: '20-week anatomy scan',
    );

    final row =
        (await repo.watchByCategory(PhotoCategory.ultrasound).first).single;
    expect(row.gestationalDays, 84);
    expect(row.notes, '20-week anatomy scan');
  });
}
