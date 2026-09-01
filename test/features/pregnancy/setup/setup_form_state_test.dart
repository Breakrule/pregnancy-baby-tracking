import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/data/db/tables.dart';
import 'package:nurture/features/pregnancy/setup/setup_form_state.dart';

void main() {
  group('validateReferenceDate', () {
    final today = DateTime(2026, 8, 30);

    test('rejects null', () {
      final state = SetupFormState();
      expect(
        state.validateReferenceDate(null, today: today),
        SetupValidationIssue.dateMissing,
      );
    });

    test('rejects future date', () {
      final state = SetupFormState();
      final future = today.add(const Duration(days: 1));
      expect(
        state.validateReferenceDate(future, today: today),
        SetupValidationIssue.dateInFuture,
      );
    });

    test('rejects date more than 45 weeks ago (321 days)', () {
      final state = SetupFormState();
      final old = today.subtract(const Duration(days: 321));
      expect(
        state.validateReferenceDate(old, today: today),
        SetupValidationIssue.dateTooOld,
      );
    });

    test('accepts date 300 days ago', () {
      final state = SetupFormState();
      final ok = today.subtract(const Duration(days: 300));
      expect(state.validateReferenceDate(ok, today: today), isNull);
    });
  });

  group('validateWeight', () {
    test('rejects null', () {
      final state = SetupFormState();
      expect(state.validateWeight(null), SetupValidationIssue.weightMissing);
    });

    test('rejects 500', () {
      final state = SetupFormState();
      expect(state.validateWeight(500), SetupValidationIssue.weightOutOfRange);
    });

    test('rejects 29', () {
      final state = SetupFormState();
      expect(state.validateWeight(29), SetupValidationIssue.weightOutOfRange);
    });

    test('accepts 62', () {
      final state = SetupFormState();
      expect(state.validateWeight(62), isNull);
    });
  });

  group('validateHeight', () {
    test('rejects null', () {
      final state = SetupFormState();
      expect(state.validateHeight(null), SetupValidationIssue.heightMissing);
    });

    test('rejects 100', () {
      final state = SetupFormState();
      expect(state.validateHeight(100), SetupValidationIssue.heightOutOfRange);
    });

    test('rejects 230', () {
      final state = SetupFormState();
      expect(state.validateHeight(230), SetupValidationIssue.heightOutOfRange);
    });

    test('accepts 165', () {
      final state = SetupFormState();
      expect(state.validateHeight(165), isNull);
    });
  });

  group('lmp source computed dates', () {
    test('lmpDate == referenceDate, dueDate == referenceDate + 280', () {
      final ref = DateTime(2026, 1, 1);
      final state = SetupFormState(
        source: ConceptionSource.lmp,
        referenceDate: ref,
      );
      expect(state.lmpDate, ref);
      expect(state.dueDate, ref.add(const Duration(days: 280)));
    });
  });

  group('ultrasound source computed dates', () {
    test('dueDate == referenceDate, lmpDate == referenceDate - 280', () {
      final ref = DateTime(2026, 10, 8);
      final state = SetupFormState(
        source: ConceptionSource.ultrasound,
        referenceDate: ref,
      );
      expect(state.dueDate, ref);
      expect(state.lmpDate, ref.subtract(const Duration(days: 280)));
    });
  });
}
