/// Canonical storage units are kg, cm, mg/dL. Conversion happens only
/// at the UI edge, driven by the user's settings.
library;

enum WeightDisplay { kg, lb }

enum LengthDisplay { cm, inch }

class UnitConverter {
  UnitConverter._();

  static const double _kgPerLb = 0.45359237;
  static const double _cmPerIn = 2.54;
  static const double _mmolPerMgDl = 0.0555; // glucose

  static double kgToLb(double kg) => kg / _kgPerLb;
  static double lbToKg(double lb) => lb * _kgPerLb;

  static double cmToIn(double cm) => cm / _cmPerIn;
  static double inToCm(double inch) => inch * _cmPerIn;

  static double mgDlToMmolL(double mgDl) => mgDl * _mmolPerMgDl;
  static double mmolLToMgDl(double mmolL) => mmolL / _mmolPerMgDl;

  static String formatWeight(double kg, WeightDisplay unit) =>
      unit == WeightDisplay.kg
      ? '${kg.toStringAsFixed(1)} kg'
      : '${kgToLb(kg).toStringAsFixed(1)} lb';

  static String formatLength(double cm, LengthDisplay unit) =>
      unit == LengthDisplay.cm
      ? '${cm.toStringAsFixed(1)} cm'
      : '${cmToIn(cm).toStringAsFixed(1)} in';
}
