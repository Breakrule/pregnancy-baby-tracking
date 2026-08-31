import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/repositories/weight_repository.dart';

void main() {
  late AppDatabase db;
  late WeightRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WeightRepository(db);
  });

  tearDown(() => db.close());

  test(
    'add three out-of-order dates, watchAll returns ascending order',
    () async {
      await repo.add(date: DateTime.utc(2026, 3, 15), weightKg: 65.0);
      await repo.add(
        date: DateTime.utc(2026, 3, 1),
        weightKg: 63.5,
        notes: 'Morning weigh-in',
      );
      await repo.add(date: DateTime.utc(2026, 3, 22), weightKg: 66.2);

      final list = await repo.watchAll().first;
      expect(list.length, 3);
      // Ascending by date
      expect(list[0].weightKg, 63.5);
      expect(list[1].weightKg, 65.0);
      expect(list[2].weightKg, 66.2);
      expect(list[0].date.isAtSameMomentAs(DateTime.utc(2026, 3, 1)), isTrue);
      expect(list[0].notes, 'Morning weigh-in');
    },
  );

  test('latest returns the most recent entry', () async {
    await repo.add(date: DateTime.utc(2026, 3, 15), weightKg: 65.0);
    await repo.add(date: DateTime.utc(2026, 3, 22), weightKg: 66.2);
    await repo.add(date: DateTime.utc(2026, 3, 1), weightKg: 63.5);

    final latest = await repo.latest();
    expect(latest, isNotNull);
    expect(latest!.weightKg, 66.2);
    expect(latest.date.isAtSameMomentAs(DateTime.utc(2026, 3, 22)), isTrue);
  });

  test('latest returns null when no entries exist', () async {
    final latest = await repo.latest();
    expect(latest, isNull);
  });

  test('delete removes a weight entry', () async {
    final id = await repo.add(date: DateTime.utc(2026, 3, 1), weightKg: 63.5);
    await repo.delete(id);

    final list = await repo.watchAll().first;
    expect(list, isEmpty);
  });
}
