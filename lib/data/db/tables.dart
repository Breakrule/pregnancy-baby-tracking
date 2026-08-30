import 'package:drift/drift.dart';

enum ConceptionSource { lmp, ultrasound }

enum WeightUnit { kg, lb }

enum LengthUnit { cm, inch }

enum GlucoseUnit { mgdl, mmoll }

enum SymptomSeverity { mild, moderate, severe }

enum AppointmentStatus { upcoming, completed, cancelled }

class Pregnancies extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get lmpDate => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get conceptionSource => textEnum<ConceptionSource>()();
  RealColumn get prePregnancyWeightKg => real()();
  RealColumn get heightCm => real()();
  TextColumn get bloodType => text().nullable()();
  BoolColumn get gbsPositive => boolean().withDefault(const Constant(false))();
  TextColumn get clinicName => text().nullable()();
  TextColumn get clinicPhone => text().nullable()();
  TextColumn get hospitalName => text().nullable()();
  TextColumn get hospitalAddress => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class SettingsRows extends Table {
  IntColumn get id => integer()();
  BoolColumn get lockEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get pinHash => text().nullable()();
  TextColumn get pinSalt => text().nullable()();
  TextColumn get weightUnit =>
      textEnum<WeightUnit>().withDefault(const Constant('kg'))();
  TextColumn get lengthUnit =>
      textEnum<LengthUnit>().withDefault(const Constant('cm'))();
  TextColumn get glucoseUnit =>
      textEnum<GlucoseUnit>().withDefault(const Constant('mgdl'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class WeightEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get weightKg => real()();
  TextColumn get notes => text().nullable()();
}

class Symptoms extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get loggedAt => dateTime()();
  TextColumn get typeKey => text()();
  TextColumn get customLabel => text().nullable()();
  TextColumn get severity => textEnum<SymptomSeverity>()();
  TextColumn get notes => text().nullable()();
}

class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get dose => text().nullable()();
  TextColumn get reminderTime =>
      text().nullable()(); // "HH:mm", null = no reminder
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
}

class MedLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get medicationId => integer().references(Medications, #id)();
  DateTimeColumn get takenAt => dateTime()();
}

class Appointments extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get at => dateTime()();
  TextColumn get type => text()(); // "OB visit", "Ultrasound", ...
  TextColumn get provider => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get status =>
      textEnum<AppointmentStatus>().withDefault(const Constant('upcoming'))();
}
