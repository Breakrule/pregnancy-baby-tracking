import 'package:flutter/widgets.dart';

import '../../../core/l10n.dart';

/// Canonical (English) identifiers stored in the database. Display labels
/// are resolved through [appointmentTypeLabel] so stored values stay
/// stable across locales.
const appointmentTypeKeys = [
  'ob_visit',
  'ultrasound',
  'blood_test',
  'midwife_visit',
  'other',
];

/// Localized display label for an appointment type. Understands the current
/// keys as well as the legacy free-text labels written before the key
/// migration; unknown values are shown as-is.
String appointmentTypeLabel(BuildContext context, String key) {
  final l10n = context.l10n;
  return switch (key) {
    'ob_visit' || 'OB visit' => l10n.apptTypeObVisit,
    'ultrasound' || 'Ultrasound' => l10n.apptTypeUltrasound,
    'blood_test' || 'Blood test' => l10n.apptTypeBloodTest,
    'midwife_visit' || 'Midwife visit' => l10n.apptTypeMidwifeVisit,
    'other' || 'Other' => l10n.apptTypeOther,
    _ => key,
  };
}
