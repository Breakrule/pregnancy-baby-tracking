import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/core/units.dart';

void main() {
  test('kg to lb and back', () {
    expect(UnitConverter.kgToLb(60), closeTo(132.277, 0.01));
    expect(UnitConverter.lbToKg(UnitConverter.kgToLb(60)), closeTo(60, 0.001));
  });

  test('cm to in and back', () {
    expect(UnitConverter.cmToIn(165), closeTo(64.96, 0.01));
    expect(
      UnitConverter.inToCm(UnitConverter.cmToIn(165)),
      closeTo(165, 0.001),
    );
  });

  test('glucose mg/dL to mmol/L', () {
    expect(UnitConverter.mgDlToMmolL(90), closeTo(4.995, 0.01));
    expect(UnitConverter.mmolLToMgDl(5.0), closeTo(90.09, 0.1));
  });

  test('formatWeight respects unit', () {
    expect(UnitConverter.formatWeight(60.0, WeightDisplay.kg), '60.0 kg');
    expect(UnitConverter.formatWeight(60.0, WeightDisplay.lb), '132.3 lb');
  });
}
