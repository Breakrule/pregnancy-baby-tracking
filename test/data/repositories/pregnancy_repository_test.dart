import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/db/tables.dart';
import 'package:nurture/data/repositories/pregnancy_repository.dart';

void main() {
  late AppDatabase db;
  late PregnancyRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PregnancyRepository(db);
  });

  tearDown(() => db.close());

  test('create stores record and watchActive emits it', () async {
    await repo.create(
      lmpDate: DateTime.utc(2026, 1, 1),
      dueDate: DateTime.utc(2026, 10, 8),
      source: ConceptionSource.lmp,
      prePregnancyWeightKg: 62,
      heightCm: 165,
    );
    final active = await repo.watchActive().first;
    expect(active, isNotNull);
    expect(active!.dueDate.isAtSameMomentAs(DateTime.utc(2026, 10, 8)), isTrue);
  });

  test('update changes the due date', () async {
    await repo.create(
      lmpDate: DateTime.utc(2026, 1, 1),
      dueDate: DateTime.utc(2026, 10, 8),
      source: ConceptionSource.lmp,
      prePregnancyWeightKg: 62,
      heightCm: 165,
    );
    final active = (await repo.watchActive().first)!;
    await repo.update(
      PregnanciesCompanion(
        id: Value(active.id),
        dueDate: Value(DateTime.utc(2026, 10, 15)),
      ),
    );
    final updated = (await repo.watchActive().first)!;
    expect(
      updated.dueDate.isAtSameMomentAs(DateTime.utc(2026, 10, 15)),
      isTrue,
    );
  });

  test('watchActive emits null when no record exists', () async {
    expect(await repo.watchActive().first, isNull);
  });
}
