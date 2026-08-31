import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../db/tables.dart';

class SymptomRepository {
  SymptomRepository(this._db);

  final AppDatabase _db;

  /// Inserts a new symptom entry. Callers must pass UTC DateTimes.
  Future<int> add({
    required DateTime loggedAt,
    required String typeKey,
    String? customLabel,
    required SymptomSeverity severity,
    String? notes,
  }) {
    return _db
        .into(_db.symptoms)
        .insert(
          SymptomsCompanion.insert(
            loggedAt: loggedAt,
            typeKey: typeKey,
            customLabel: Value(customLabel),
            severity: severity,
            notes: Value(notes),
          ),
        );
  }

  /// Emits all symptoms ordered by loggedAt descending (newest first).
  Stream<List<Symptom>> watchAll() {
    final query = _db.select(_db.symptoms)
      ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)]);
    return query.watch();
  }

  /// Deletes a symptom entry by id.
  Future<int> delete(int id) {
    return (_db.delete(_db.symptoms)..where((t) => t.id.equals(id))).go();
  }
}
