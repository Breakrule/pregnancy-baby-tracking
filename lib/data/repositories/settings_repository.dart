import 'package:drift/drift.dart';

import '../db/app_database.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Future<SettingsRow> get() async {
    final rows = await _db.select(_db.settingsRows).get();
    if (rows.isEmpty) {
      await _db
          .into(_db.settingsRows)
          .insert(SettingsRowsCompanion.insert(id: const Value(1)));
      return (await _db.select(_db.settingsRows).getSingle());
    }
    return rows.first;
  }

  Future<void> update(SettingsRowsCompanion companion) async {
    await get(); // ensures row exists
    await (_db.update(
      _db.settingsRows,
    )..where((t) => t.id.equals(1))).write(companion);
  }
}
