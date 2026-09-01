import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/repositories/medication_repository.dart';

void main() {
  late AppDatabase db;
  late MedicationRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = MedicationRepository(db);
  });

  tearDown(() => db.close());

  test(
    'add med, log taken today -> takenToday true; tomorrow -> false',
    () async {
      final id = await repo.add(
        name: 'Prenatal vitamin',
        dose: '1 tablet',
        reminderTime: '08:00',
        startDate: DateTime.utc(2026, 3, 1),
      );

      final takenAt = DateTime.utc(2026, 3, 10, 8, 5);
      await repo.logTaken(id, takenAt);

      // Same local calendar day as the log -> true.
      final today = takenAt.toLocal();
      expect(await repo.takenToday(id, today), isTrue);

      // One day later -> false.
      final tomorrow = today.add(const Duration(days: 1));
      expect(await repo.takenToday(id, tomorrow), isFalse);
    },
  );

  test('watchActiveMeds returns only active meds ordered by name', () async {
    await repo.add(name: 'Zinc', startDate: DateTime.utc(2026, 3, 1));
    final ironId = await repo.add(
      name: 'Iron',
      startDate: DateTime.utc(2026, 3, 1),
    );

    // Deactivate Zinc; only Iron should remain.
    await repo.setActive(ironId, true);
    final beforeDeactivate = await repo.watchActiveMeds().first;
    expect(beforeDeactivate.map((m) => m.name).toList(), ['Iron', 'Zinc']);

    await repo.setActive(
      beforeDeactivate.firstWhere((m) => m.name == 'Zinc').id,
      false,
    );
    final after = await repo.watchActiveMeds().first;
    expect(after.map((m) => m.name).toList(), ['Iron']);
  });

  test('untakeToday removes only today\'s log', () async {
    final id = await repo.add(
      name: 'Folic acid',
      startDate: DateTime.utc(2026, 3, 1),
    );

    final takenAt = DateTime.utc(2026, 3, 10, 8, 0);
    await repo.logTaken(id, takenAt);
    final today = takenAt.toLocal();

    expect(await repo.takenToday(id, today), isTrue);
    await repo.untakeToday(id, today);
    expect(await repo.takenToday(id, today), isFalse);
  });
}
