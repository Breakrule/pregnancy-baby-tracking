import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Pregnancies,
    SettingsRows,
    WeightEntries,
    Symptoms,
    Medications,
    MedLogs,
    Appointments,
    Photos,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? _defaultExecutor());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2: photo journal (belly, ultrasound, baby).
        await m.createTable(photos);
      }
      if (from < 3) {
        // v3: UI language preference.
        await m.addColumn(settingsRows, settingsRows.locale);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
    // After first public release, add versioned onUpgrade migrations.
  );

  static QueryExecutor _defaultExecutor() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'nurture.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
