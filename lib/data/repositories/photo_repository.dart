import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../db/tables.dart';

class PhotoRepository {
  PhotoRepository(this._db);

  final AppDatabase _db;

  /// Inserts a photo record. Callers must pass UTC DateTimes. The image
  /// files themselves are stored by [PhotoService]; only metadata lives here.
  Future<int> add({
    required PhotoCategory category,
    required DateTime takenAt,
    required String fileName,
    int? gestationalDays,
    String? notes,
  }) {
    return _db.into(_db.photos).insert(
      PhotosCompanion.insert(
        category: category,
        takenAt: takenAt,
        fileName: fileName,
        gestationalDays: Value(gestationalDays),
        notes: Value(notes),
      ),
    );
  }

  /// Emits the photos of one category ordered by takenAt ascending
  /// (oldest first — the journal reads chronologically).
  Stream<List<Photo>> watchByCategory(PhotoCategory category) {
    final query = _db.select(_db.photos)
      ..where((t) => t.category.equalsValue(category))
      ..orderBy([(t) => OrderingTerm.asc(t.takenAt)]);
    return query.watch();
  }

  /// Single photo by id, or null when it no longer exists.
  Future<Photo?> byId(int id) async {
    final rows = await (_db.select(_db.photos)
          ..where((t) => t.id.equals(id)))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  /// Deletes a photo record by id. File cleanup is the caller's job.
  Future<int> delete(int id) {
    return (_db.delete(_db.photos)..where((t) => t.id.equals(id))).go();
  }
}
