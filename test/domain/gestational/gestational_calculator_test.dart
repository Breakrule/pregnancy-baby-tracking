import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/domain/gestational/gestational_calculator.dart';

void main() {
  group('dueDateFromLmp', () {
    test('adds 280 days', () {
      expect(
        GestationalCalculator.dueDateFromLmp(DateTime(2026, 1, 1)),
        DateTime(2026, 10, 8),
      );
    });

    test('handles leap-year February', () {
      expect(
        GestationalCalculator.dueDateFromLmp(DateTime(2027, 12, 1)),
        DateTime(2028, 9, 6),
      );
    });
  });

  group('lmpFromDueDate', () {
    test('is the inverse of dueDateFromLmp', () {
      final lmp = DateTime(2026, 2, 15);
      expect(
        GestationalCalculator.lmpFromDueDate(
          GestationalCalculator.dueDateFromLmp(lmp),
        ),
        lmp,
      );
    });
  });

  group('gestationalAgeAt', () {
    final lmp = DateTime(2026, 1, 1);

    test('day zero is 0w0d', () {
      final ga = GestationalCalculator.gestationalAgeAt(lmp, lmp);
      expect(ga.weeks, 0);
      expect(ga.days, 0);
      expect(ga.label, 'Week 0, Day 0');
    });

    test('day 66 is 9w3d', () {
      final ga = GestationalCalculator.gestationalAgeAt(
        lmp,
        DateTime(2026, 3, 8),
      );
      expect(ga.weeks, 9);
      expect(ga.days, 3);
      expect(ga.label, 'Week 9, Day 3');
    });

    test('past week 42 keeps counting', () {
      final ga = GestationalCalculator.gestationalAgeAt(
        lmp,
        lmp.add(const Duration(days: 294)),
      );
      expect(ga.weeks, 42);
      expect(ga.days, 0);
    });
  });

  group('trimesterAt', () {
    final lmp = DateTime(2026, 1, 1);

    GestationalAge gaAt(int days) => GestationalCalculator.gestationalAgeAt(
      lmp,
      lmp.add(Duration(days: days)),
    );

    test('day 97 (13w6d) is trimester 1', () {
      expect(GestationalCalculator.trimesterOf(gaAt(97)), Trimester.first);
    });

    test('day 98 (14w0d) is trimester 2', () {
      expect(GestationalCalculator.trimesterOf(gaAt(98)), Trimester.second);
    });

    test('day 195 (27w6d) is trimester 2', () {
      expect(GestationalCalculator.trimesterOf(gaAt(195)), Trimester.second);
    });

    test('day 196 (28w0d) is trimester 3', () {
      expect(GestationalCalculator.trimesterOf(gaAt(196)), Trimester.third);
    });
  });

  group('daysUntilDue', () {
    test('positive before due date', () {
      expect(
        GestationalCalculator.daysUntilDue(
          DateTime(2026, 10, 8),
          DateTime(2026, 9, 28),
        ),
        10,
      );
    });

    test('negative after due date', () {
      expect(
        GestationalCalculator.daysUntilDue(
          DateTime(2026, 10, 8),
          DateTime(2026, 10, 11),
        ),
        -3,
      );
    });
  });
}
