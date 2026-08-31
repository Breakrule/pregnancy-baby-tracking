import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/domain/growth/iom_weight_gain.dart';

void main() {
  group('bmiCategory', () {
    test('classifies boundaries correctly', () {
      // BMI = kg / (m^2)
      expect(
        IomWeightGain.bmiCategory(45, 165),
        BmiCategory.underweight,
      ); // 16.5
      expect(IomWeightGain.bmiCategory(55, 165), BmiCategory.normal); // 20.2
      expect(
        IomWeightGain.bmiCategory(75, 165),
        BmiCategory.overweight,
      ); // 27.5
      expect(IomWeightGain.bmiCategory(90, 165), BmiCategory.obese); // 33.1
    });

    test('edge BMI 18.5 is normal, 25 is overweight, 30 is obese', () {
      expect(
        IomWeightGain.bmiCategory(18.5 * 1.65 * 1.65, 165),
        BmiCategory.normal,
      );
      expect(
        IomWeightGain.bmiCategory(25.0 * 1.65 * 1.65, 165),
        BmiCategory.overweight,
      );
      expect(
        IomWeightGain.bmiCategory(30.0 * 1.65 * 1.65, 165),
        BmiCategory.obese,
      );
    });
  });

  group('totalGainRange', () {
    test('normal BMI: 11.5-16 kg', () {
      final range = IomWeightGain.totalGainRange(BmiCategory.normal);
      expect(range.minKg, 11.5);
      expect(range.maxKg, 16.0);
    });

    test('underweight: 12.5-18 kg', () {
      final range = IomWeightGain.totalGainRange(BmiCategory.underweight);
      expect(range.minKg, 12.5);
      expect(range.maxKg, 18.0);
    });

    test('overweight: 7-11.5 kg', () {
      final range = IomWeightGain.totalGainRange(BmiCategory.overweight);
      expect(range.minKg, 7.0);
      expect(range.maxKg, 11.5);
    });

    test('obese: 5-9 kg', () {
      final range = IomWeightGain.totalGainRange(BmiCategory.obese);
      expect(range.minKg, 5.0);
      expect(range.maxKg, 9.0);
    });
  });

  group('weeklyRateRange', () {
    test('normal BMI: 0.35-0.50 kg/week in T2/T3', () {
      final range = IomWeightGain.weeklyRateRange(BmiCategory.normal);
      expect(range.minKg, 0.35);
      expect(range.maxKg, 0.50);
    });
  });

  group('expectedRangeAt', () {
    test('before week 14 the expected gain is near zero', () {
      final range = IomWeightGain.expectedRangeAt(
        BmiCategory.normal,
        gestationalDay: 70,
      );
      expect(range.minKg, 0.0);
      expect(range.maxKg, closeTo(1.0, 0.5));
    });

    test('at term a normal-BMI pregnancy expects 11.5-16 kg', () {
      final range = IomWeightGain.expectedRangeAt(
        BmiCategory.normal,
        gestationalDay: 280,
      );
      expect(range.minKg, closeTo(11.5, 0.5));
      expect(range.maxKg, closeTo(16.0, 0.5));
    });
  });
}
