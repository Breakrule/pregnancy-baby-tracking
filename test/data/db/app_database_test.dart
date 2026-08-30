import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/db/tables.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('creates schema and stores a pregnancy row', () async {
    final id = await db
        .into(db.pregnancies)
        .insert(
          PregnanciesCompanion.insert(
            lmpDate: DateTime.utc(2026, 1, 1),
            dueDate: DateTime.utc(2026, 10, 8),
            conceptionSource: ConceptionSource.lmp,
            prePregnancyWeightKg: 62.0,
            heightCm: 165.0,
          ),
        );
    final row = await (db.select(
      db.pregnancies,
    )..where((t) => t.id.equals(id))).getSingle();
    expect(row.prePregnancyWeightKg, 62.0);
    expect(row.conceptionSource, ConceptionSource.lmp);
  });

  test('settings row has secure defaults', () async {
    await db
        .into(db.settingsRows)
        .insert(SettingsRowsCompanion.insert(id: Value(1)));
    final row = await db.select(db.settingsRows).getSingle();
    expect(row.lockEnabled, isFalse);
    expect(row.weightUnit, WeightUnit.kg);
  });
}
