import 'package:drift/drift.dart';

import '../db/app_database.dart';

class WeightRepository {
  WeightRepository(this._db);

  final AppDatabase _db;

  /// Inserts a new weight entry. Callers must pass UTC DateTimes.
  Future<int> add({
    required DateTime date,
    required double weightKg,
    String? notes,
  }) {
    return _db
        .into(_db.weightEntries)
        .insert(
          WeightEntriesCompanion.insert(
            date: date,
            weightKg: weightKg,
            notes: Value(notes),
          ),
        );
  }

  /// Emits all weight entries ordered by date ascending (oldest first).
  Stream<List<WeightEntry>> watchAll() {
    final query = _db.select(_db.weightEntries)
      ..orderBy([(t) => OrderingTerm.asc(t.date)]);
    return query.watch();
  }

  /// Returns the most recent weight entry, or null if none exist.
  Future<WeightEntry?> latest() async {
    final query = _db.select(_db.weightEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.date)])
      ..limit(1);
    final results = await query.get();
    return results.isEmpty ? null : results.first;
  }

  /// Deletes a weight entry by id.
  Future<int> delete(int id) {
    return (_db.delete(_db.weightEntries)..where((t) => t.id.equals(id))).go();
  }
}
