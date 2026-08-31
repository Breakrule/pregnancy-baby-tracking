import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

class ContentLoader {
  ContentLoader._();

  static Future<ContentBundle> load() async {
    try {
      final rawWeeks = await rootBundle.loadString('assets/content/weeks.json');
      final decodedWeeks = jsonDecode(rawWeeks) as Map<String, dynamic>;
      final weeks = (decodedWeeks['weeks'] as List)
          .map((w) => WeekContent.fromJson(w as Map<String, dynamic>))
          .toList();

      final rawFlags = await rootBundle.loadString(
        'assets/content/red_flags.json',
      );
      final decodedFlags = jsonDecode(rawFlags) as Map<String, dynamic>;
      final redFlags = (decodedFlags['red_flags'] as List)
          .map((f) => RedFlag.fromJson(f as Map<String, dynamic>))
          .toList();

      final rawSymptoms = await rootBundle.loadString(
        'assets/content/common_symptoms.json',
      );
      final decodedSymptoms = jsonDecode(rawSymptoms) as Map<String, dynamic>;
      final symptomPresets = (decodedSymptoms['symptoms'] as List)
          .map((s) => SymptomPreset.fromJson(s as Map<String, dynamic>))
          .toList();

      return ContentBundle(
        weeks: weeks,
        redFlags: redFlags,
        symptomPresets: symptomPresets,
      );
    } catch (e) {
      throw StateError('Failed to load bundled week content: $e');
    }
  }
}
