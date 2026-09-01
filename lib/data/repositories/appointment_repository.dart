import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../db/tables.dart';

class AppointmentRepository {
  AppointmentRepository(this._db);

  final AppDatabase _db;

  /// Inserts an appointment. Callers must pass a UTC DateTime for [at].
  Future<int> add({
    required DateTime at,
    required String type,
    String? provider,
    String? location,
    String? notes,
  }) {
    return _db
        .into(_db.appointments)
        .insert(
          AppointmentsCompanion.insert(
            at: at,
            type: type,
            provider: Value(provider),
            location: Value(location),
            notes: Value(notes),
          ),
        );
  }

  Future<void> markCompleted(int id) =>
      _setStatus(id, AppointmentStatus.completed);

  Future<void> cancel(int id) => _setStatus(id, AppointmentStatus.cancelled);

  Future<void> _setStatus(int id, AppointmentStatus status) {
    return (_db.update(_db.appointments)..where((t) => t.id.equals(id))).write(
      AppointmentsCompanion(status: Value(status)),
    );
  }

  /// Still-open appointments at or after [now], soonest first.
  Stream<List<Appointment>> watchUpcoming(DateTime now) {
    final query = _db.select(_db.appointments)
      ..where(
        (t) =>
            t.status.equals(AppointmentStatus.upcoming.name) &
            t.at.isBiggerOrEqualValue(now),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.at)]);
    return query.watch();
  }

  /// Everything not shown as upcoming: past open appointments plus
  /// completed/cancelled ones, most recent first.
  Stream<List<Appointment>> watchPast(DateTime now) {
    final query = _db.select(_db.appointments)
      ..where(
        (t) =>
            t.at.isSmallerThanValue(now) |
            t.status.isIn([
              AppointmentStatus.completed.name,
              AppointmentStatus.cancelled.name,
            ]),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.at)]);
    return query.watch();
  }
}
