/// Pure-Dart gestational math. No Flutter imports.
///
/// Gestational age counts from LMP (or the back-derived LMP when the due
/// date came from ultrasound dating). Trimester boundaries:
/// T1 = week 0 through 13+6, T2 = 14 through 27+6, T3 = 28 onward.
library;

enum Trimester { first, second, third }

class GestationalAge {
  const GestationalAge({required this.weeks, required this.days});

  final int weeks;
  final int days;

  int get totalDays => weeks * 7 + days;

  String get label => 'Week $weeks, Day $days';
}

class GestationalCalculator {
  GestationalCalculator._();

  static const int fullTermDays = 280;

  static DateTime dueDateFromLmp(DateTime lmp) =>
      _dateOnly(lmp).add(const Duration(days: fullTermDays));

  static DateTime lmpFromDueDate(DateTime dueDate) =>
      _dateOnly(dueDate).subtract(const Duration(days: fullTermDays));

  static GestationalAge gestationalAgeAt(DateTime lmp, DateTime on) {
    final days = _dateOnly(on).difference(_dateOnly(lmp)).inDays;
    final clamped = days < 0 ? 0 : days;
    return GestationalAge(weeks: clamped ~/ 7, days: clamped % 7);
  }

  static Trimester trimesterOf(GestationalAge ga) {
    if (ga.totalDays < 14 * 7) return Trimester.first;
    if (ga.totalDays < 28 * 7) return Trimester.second;
    return Trimester.third;
  }

  static int daysUntilDue(DateTime dueDate, DateTime on) =>
      _dateOnly(dueDate).difference(_dateOnly(on)).inDays;

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
