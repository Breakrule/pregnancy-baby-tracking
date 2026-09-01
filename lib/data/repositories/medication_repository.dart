import 'package:drift/drift.dart';

import '../db/app_database.dart';

class MedicationRepository {
  MedicationRepository(this._db);

  final AppDatabase _db;

  /// Inserts a medication. [reminderTime] is "HH:mm" or null for no reminder.
  /// Callers must pass UTC DateTimes for [startDate].
  Future<int> add({
    required String name,
    String? dose,
    String? reminderTime,
    required DateTime startDate,
  }) {
    return _db
        .into(_db.medications)
        .insert(
          MedicationsCompanion.insert(
            name: name,
            dose: Value(dose),
            reminderTime: Value(reminderTime),
            startDate: startDate,
          ),
        );
  }

  Future<void> setActive(int id, bool active) {
    return (_db.update(_db.medications)..where((t) => t.id.equals(id))).write(
      MedicationsCompanion(active: Value(active)),
    );
  }

  /// Records a dose taken at [at] (UTC).
  Future<int> logTaken(int medicationId, DateTime at) {
    return _db
        .into(_db.medLogs)
        .insert(
          MedLogsCompanion.insert(medicationId: medicationId, takenAt: at),
        );
  }

  /// Emits active medications ordered by name.
  Stream<List<Medication>> watchActiveMeds() {
    final query = _db.select(_db.medications)
      ..where((t) => t.active.equals(true))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  /// Emits every medication log entry (used to refresh derived counts).
  Stream<List<MedLog>> watchLogs() {
    final query = _db.select(_db.medLogs)
      ..orderBy([(t) => OrderingTerm.desc(t.takenAt)]);
    return query.watch();
  }

  /// True if [medicationId] has a log on the same local calendar day as
  /// [today].
  Future<bool> takenToday(int medicationId, DateTime today) async {
    final logs = await (_db.select(
      _db.medLogs,
    )..where((t) => t.medicationId.equals(medicationId))).get();
    return logs.any((log) {
      final local = log.takenAt.toLocal();
      return local.year == today.year &&
          local.month == today.month &&
          local.day == today.day;
    });
  }

  /// Removes today's log for [medicationId] so the taken checkbox can be
  /// toggled back off.
  Future<void> untakeToday(int medicationId, DateTime today) async {
    final logs = await (_db.select(
      _db.medLogs,
    )..where((t) => t.medicationId.equals(medicationId))).get();
    for (final log in logs) {
      final local = log.takenAt.toLocal();
      if (local.year == today.year &&
          local.month == today.month &&
          local.day == today.day) {
        await (_db.delete(_db.medLogs)..where((t) => t.id.equals(log.id))).go();
      }
    }
  }
}
