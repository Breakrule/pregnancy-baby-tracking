import '../../../data/db/tables.dart';
import '../../../domain/gestational/gestational_calculator.dart';

/// Locale-neutral validation outcomes; the UI maps them to localized
/// strings so this class stays free of display copy.
enum SetupValidationIssue {
  dateMissing,
  dateInFuture,
  dateTooOld,
  weightMissing,
  weightOutOfRange,
  heightMissing,
  heightOutOfRange,
}

class SetupFormState {
  SetupFormState({
    this.source = ConceptionSource.lmp,
    this.referenceDate,
    this.prePregnancyWeightKg,
    this.heightCm,
    this.bloodType,
    this.clinicName,
    this.clinicPhone,
    this.hospitalName,
    this.hospitalAddress,
  });

  ConceptionSource source;

  /// LMP date when [source] == lmp, otherwise the ultrasound-given due date.
  DateTime? referenceDate;
  double? prePregnancyWeightKg;
  double? heightCm;
  String? bloodType;
  String? clinicName;
  String? clinicPhone;
  String? hospitalName;
  String? hospitalAddress;

  DateTime? get lmpDate => switch (source) {
    ConceptionSource.lmp => referenceDate,
    ConceptionSource.ultrasound =>
      referenceDate == null
          ? null
          : GestationalCalculator.lmpFromDueDate(referenceDate!),
  };

  DateTime? get dueDate => switch (source) {
    ConceptionSource.lmp =>
      referenceDate == null
          ? null
          : GestationalCalculator.dueDateFromLmp(referenceDate!),
    ConceptionSource.ultrasound => referenceDate,
  };

  /// [today] should be a local-time date (DateTime.now()); comparisons are date-only.
  SetupValidationIssue? validateReferenceDate(
    DateTime? value, {
    required DateTime today,
  }) {
    if (value == null) return SetupValidationIssue.dateMissing;
    final dateOnly = DateTime(value.year, value.month, value.day);
    if (dateOnly.isAfter(today)) return SetupValidationIssue.dateInFuture;
    final earliest = today.subtract(const Duration(days: 320));
    if (dateOnly.isBefore(earliest)) return SetupValidationIssue.dateTooOld;
    return null;
  }

  SetupValidationIssue? validateWeight(double? kg) {
    if (kg == null) return SetupValidationIssue.weightMissing;
    if (kg < 30 || kg > 250) return SetupValidationIssue.weightOutOfRange;
    return null;
  }

  SetupValidationIssue? validateHeight(double? cm) {
    if (cm == null) return SetupValidationIssue.heightMissing;
    if (cm < 120 || cm > 220) return SetupValidationIssue.heightOutOfRange;
    return null;
  }
}
