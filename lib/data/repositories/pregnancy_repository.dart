import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../db/tables.dart';

class PregnancyRepository {
  PregnancyRepository(this._db);

  final AppDatabase _db;

  Future<int> create({
    required DateTime lmpDate,
    required DateTime dueDate,
    required ConceptionSource source,
    required double prePregnancyWeightKg,
    required double heightCm,
    String? bloodType,
    String? clinicName,
    String? clinicPhone,
    String? hospitalName,
    String? hospitalAddress,
  }) {
    return _db
        .into(_db.pregnancies)
        .insert(
          PregnanciesCompanion.insert(
            lmpDate: lmpDate,
            dueDate: dueDate,
            conceptionSource: source,
            prePregnancyWeightKg: prePregnancyWeightKg,
            heightCm: heightCm,
            bloodType: Value(bloodType),
            clinicName: Value(clinicName),
            clinicPhone: Value(clinicPhone),
            hospitalName: Value(hospitalName),
            hospitalAddress: Value(hospitalAddress),
          ),
        );
  }

  Future<int> update(PregnanciesCompanion companion) async {
    return (_db.update(
      _db.pregnancies,
    )..where((t) => t.id.equals(companion.id.value))).write(companion);
  }

  /// Emits the most recent pregnancy record, or null.
  Stream<Pregnancy?> watchActive() {
    final query = _db.select(_db.pregnancies)
      ..orderBy([(t) => OrderingTerm.desc(t.id)])
      ..limit(1);
    return query.watchSingleOrNull();
  }
}
