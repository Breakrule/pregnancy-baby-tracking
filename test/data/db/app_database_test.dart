import 'dart:io';

import 'package:drift/drift.dart' show Value, MigrationStrategy;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/db/tables.dart';
import 'package:path/path.dart' as p;

/// Simulates the app as shipped in Phase 0: schema v1 without the photos
/// table and without the settings `locale` column. Used to verify the
/// migration path.
class _V1Database extends AppDatabase {
  _V1Database(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      for (final table in allTables) {
        if (identical(table, photos)) continue; // didn't exist in v1
        if (identical(table, settingsRows)) {
          // v1 settings had no locale column.
          await m.database.customStatement('''
            CREATE TABLE settings_rows (
              id INTEGER NOT NULL,
              lock_enabled INTEGER NOT NULL DEFAULT 0,
              pin_hash TEXT,
              pin_salt TEXT,
              weight_unit TEXT NOT NULL DEFAULT 'kg',
              length_unit TEXT NOT NULL DEFAULT 'cm',
              glucose_unit TEXT NOT NULL DEFAULT 'mgdl',
              PRIMARY KEY (id)
            );
          ''');
          continue;
        }
        await m.createTable(table);
      }
    },
  );
}

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
    expect(row.lengthUnit, LengthUnit.cm);
    expect(row.glucoseUnit, GlucoseUnit.mgdl);
    expect(row.pinHash, isNull);
    expect(row.pinSalt, isNull);
  });

  test('deleting a medication cascades to its logs', () async {
    final medId = await db
        .into(db.medications)
        .insert(
          MedicationsCompanion.insert(
            name: 'Prenatal vitamin',
            startDate: DateTime.utc(2026, 1, 1),
          ),
        );
    await db
        .into(db.medLogs)
        .insert(
          MedLogsCompanion.insert(
            medicationId: medId,
            takenAt: DateTime.utc(2026, 1, 2),
          ),
        );
    await (db.delete(db.medications)..where((t) => t.id.equals(medId))).go();
    final logs = await db.select(db.medLogs).get();
    expect(logs, isEmpty);
  });

  test('upgrades a v1 install to v2, adding photos and keeping data', () async {
    final dir = Directory.systemTemp.createTempSync('nurture-migration');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, 'nurture.sqlite'));

    // Phase-0 install with one pregnancy row.
    final old = _V1Database(NativeDatabase(file));
    final pregnancyId = await old
        .into(old.pregnancies)
        .insert(
          PregnanciesCompanion.insert(
            lmpDate: DateTime.utc(2026, 1, 1),
            dueDate: DateTime.utc(2026, 10, 8),
            conceptionSource: ConceptionSource.lmp,
            prePregnancyWeightKg: 62,
            heightCm: 165,
          ),
        );
    await old.close();

    // Reopen with the current schema: migration must run transparently.
    final upgraded = AppDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);

    // The photos table exists (queryable, empty).
    expect(await upgraded.select(upgraded.photos).get(), isEmpty);
    // Legacy data survived the upgrade.
    final rows = await upgraded.select(upgraded.pregnancies).get();
    expect(rows.single.id, pregnancyId);
  });
}
