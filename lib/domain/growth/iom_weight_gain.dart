/// IOM (2009) gestational weight gain guidance for singleton pregnancies.
library;

enum BmiCategory { underweight, normal, overweight, obese }

class GainRange {
  const GainRange(this.minKg, this.maxKg);
  final double minKg;
  final double maxKg;
}

class IomWeightGain {
  IomWeightGain._();

  static BmiCategory bmiCategory(double weightKg, double heightCm) {
    final meters = heightCm / 100;
    final bmi = weightKg / (meters * meters);
    if (bmi < 18.5) return BmiCategory.underweight;
    if (bmi < 25) return BmiCategory.normal;
    if (bmi < 30) return BmiCategory.overweight;
    return BmiCategory.obese;
  }

  static GainRange totalGainRange(BmiCategory category) => switch (category) {
    BmiCategory.underweight => const GainRange(12.5, 18.0),
    BmiCategory.normal => const GainRange(11.5, 16.0),
    BmiCategory.overweight => const GainRange(7.0, 11.5),
    BmiCategory.obese => const GainRange(5.0, 9.0),
  };

  /// Mean weekly rates for trimesters 2–3 (IOM 2009).
  static GainRange weeklyRateRange(BmiCategory category) => switch (category) {
    BmiCategory.underweight => const GainRange(0.44, 0.58),
    BmiCategory.normal => const GainRange(0.35, 0.50),
    BmiCategory.overweight => const GainRange(0.23, 0.33),
    BmiCategory.obese => const GainRange(0.17, 0.27),
  };

  /// Linear interpolation: ~1 kg by week 14, then linear ramp to total at term.
  static GainRange expectedRangeAt(
    BmiCategory category, {
    required int gestationalDay,
  }) {
    const t1EndDay = 98; // 14w0d
    const termDay = 280;
    if (gestationalDay <= 0) return const GainRange(0, 0);

    final total = totalGainRange(category);
    if (gestationalDay <= t1EndDay) {
      const firstTrimesterMax = 1.0;
      final f = gestationalDay / t1EndDay;
      return GainRange(0, firstTrimesterMax * f);
    }

    // Linear segment from (t1EndDay, 0/1.0) to (termDay, total.min/total.max).
    final progress = (gestationalDay - t1EndDay) / (termDay - t1EndDay);
    final min = (total.minKg * progress).clamp(0.0, total.minKg);
    final max = (1.0 + (total.maxKg - 1.0) * progress).clamp(0.0, total.maxKg);
    return GainRange(min, max);
  }
}
