import '../../../data/db/tables.dart';
import '../../../domain/gestational/gestational_calculator.dart';

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

  String? validateReferenceDate(DateTime? value, {required DateTime today}) {
    if (value == null) return 'Choose a date';
    final dateOnly = DateTime(value.year, value.month, value.day);
    if (dateOnly.isAfter(today)) return 'Date must be in the past';
    final earliest = today.subtract(const Duration(days: 320));
    if (dateOnly.isBefore(earliest)) return 'Date is more than 45 weeks ago';
    return null;
  }

  String? validateWeight(double? kg) {
    if (kg == null) return 'Enter your pre-pregnancy weight';
    if (kg < 30 || kg > 250) return 'Weight must be between 30 and 250 kg';
    return null;
  }

  String? validateHeight(double? cm) {
    if (cm == null) return 'Enter your height';
    if (cm < 120 || cm > 220) return 'Height must be between 120 and 220 cm';
    return null;
  }
}
