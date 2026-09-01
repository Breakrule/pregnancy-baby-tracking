import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/data/backup/backup_service.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/db/tables.dart';

void main() {
  Future<AppDatabase> seededDb() async {
    final db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.pregnancies)
        .insert(
          PregnanciesCompanion.insert(
            lmpDate: DateTime.utc(2026, 1, 1),
            dueDate: DateTime.utc(2026, 10, 8),
            conceptionSource: ConceptionSource.lmp,
            prePregnancyWeightKg: 62,
            heightCm: 165,
          ),
        );
    await db
        .into(db.weightEntries)
        .insert(
          WeightEntriesCompanion.insert(
            date: DateTime.utc(2026, 3, 1),
            weightKg: 63.4,
          ),
        );
    await db
        .into(db.settingsRows)
        .insert(
          SettingsRowsCompanion.insert(
            id: const Value(1),
            lockEnabled: const Value(true),
            weightUnit: const Value(WeightUnit.lb),
          ),
        );
    final medId = await db
        .into(db.medications)
        .insert(
          MedicationsCompanion.insert(
            name: 'Folic acid',
            dose: const Value('400 mcg'),
            reminderTime: const Value('08:00'),
            startDate: DateTime.utc(2026, 1, 2),
          ),
        );
    await db
        .into(db.medLogs)
        .insert(
          MedLogsCompanion.insert(
            medicationId: medId,
            takenAt: DateTime.utc(2026, 3, 1, 8, 5),
          ),
        );
    await db
        .into(db.symptoms)
        .insert(
          SymptomsCompanion.insert(
            loggedAt: DateTime.utc(2026, 2, 14, 9),
            typeKey: 'nausea',
            severity: SymptomSeverity.mild,
          ),
        );
    return db;
  }

  test('export then import restores all data', () async {
    final source = await seededDb();
    final service = BackupService();
    final bytes = await service.export(source, passphrase: 's3cret-pass');
    await source.close();

    final target = AppDatabase(NativeDatabase.memory());
    await service.import(target, bytes, passphrase: 's3cret-pass');

    final pregnancies = await target.select(target.pregnancies).get();
    final weights = await target.select(target.weightEntries).get();
    expect(pregnancies.single.prePregnancyWeightKg, 62);
    // Drift reads unix-second storage back as local DateTimes app-wide, so
    // compare instants rather than DateTime equality.
    expect(
      pregnancies.single.lmpDate.isAtSameMomentAs(DateTime.utc(2026, 1, 1)),
      isTrue,
    );
    expect(weights.single.weightKg, 63.4);

    // Settings: enum + bool columns round-trip.
    final settings = await target.select(target.settingsRows).get();
    expect(settings.single.lockEnabled, isTrue);
    expect(settings.single.weightUnit, WeightUnit.lb);

    // Foreign-key pair keeps its ids aligned.
    final meds = await target.select(target.medications).get();
    final logs = await target.select(target.medLogs).get();
    expect(meds.single.name, 'Folic acid');
    expect(meds.single.reminderTime, '08:00');
    expect(meds.single.active, isTrue);
    expect(logs.single.medicationId, meds.single.id);

    final symptoms = await target.select(target.symptoms).get();
    expect(symptoms.single.severity, SymptomSeverity.mild);

    await target.close();
  });

  test('wrong passphrase fails with BackupException', () async {
    final source = await seededDb();
    final service = BackupService();
    final bytes = await service.export(source, passphrase: 'right');
    final target = AppDatabase(NativeDatabase.memory());
    expect(
      () => service.import(target, bytes, passphrase: 'wrong'),
      throwsA(isA<BackupException>()),
    );
    await source.close();
    await target.close();
  });

  test('tampered payload fails checksum', () async {
    final source = await seededDb();
    final service = BackupService();
    final bytes = await service.export(source, passphrase: 's3cret');
    bytes[bytes.length - 10] ^= 0xFF; // flip bits in ciphertext
    final target = AppDatabase(NativeDatabase.memory());
    expect(
      () => service.import(target, bytes, passphrase: 's3cret'),
      throwsA(isA<BackupException>()),
    );
    await source.close();
    await target.close();
  });

  test('newer schema version is rejected', () async {
    final source = await seededDb();
    final service = BackupService(schemaVersionOverride: 999);
    final bytes = await service.export(source, passphrase: 's3cret');
    final normalService = BackupService();
    final target = AppDatabase(NativeDatabase.memory());
    expect(
      () => normalService.import(target, bytes, passphrase: 's3cret'),
      throwsA(isA<BackupException>()),
    );
    await source.close();
    await target.close();
  });
}
