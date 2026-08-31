import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/db/tables.dart';
import 'package:nurture/data/repositories/symptom_repository.dart';

void main() {
  late AppDatabase db;
  late SymptomRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = SymptomRepository(db);
  });

  tearDown(() => db.close());

  test('insert two symptoms and watchAll returns them newest first', () async {
    await repo.add(
      loggedAt: DateTime.utc(2026, 3, 1, 8),
      typeKey: 'nausea',
      severity: SymptomSeverity.mild,
    );
    await repo.add(
      loggedAt: DateTime.utc(2026, 3, 1, 10),
      typeKey: 'fatigue',
      severity: SymptomSeverity.moderate,
      notes: 'After lunch',
    );

    final list = await repo.watchAll().first;
    expect(list.length, 2);
    // Newest first
    expect(list[0].typeKey, 'fatigue');
    expect(list[1].typeKey, 'nausea');
    expect(
      list[0].loggedAt.isAtSameMomentAs(DateTime.utc(2026, 3, 1, 10)),
      isTrue,
    );
    expect(list[0].notes, 'After lunch');
  });

  test('delete removes a symptom', () async {
    final id = await repo.add(
      loggedAt: DateTime.utc(2026, 3, 1, 8),
      typeKey: 'nausea',
      severity: SymptomSeverity.mild,
    );
    await repo.delete(id);

    final list = await repo.watchAll().first;
    expect(list, isEmpty);
  });

  test('custom label is stored and retrieved', () async {
    await repo.add(
      loggedAt: DateTime.utc(2026, 3, 1, 8),
      typeKey: '_custom_',
      customLabel: 'Weird tingling',
      severity: SymptomSeverity.severe,
    );

    final list = await repo.watchAll().first;
    expect(list.single.customLabel, 'Weird tingling');
    expect(list.single.severity, SymptomSeverity.severe);
  });
}
