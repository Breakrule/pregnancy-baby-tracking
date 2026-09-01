import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

/// Loads the bundled educational content for a UI locale. Files live in
/// `assets/content/<locale>/`; when a file is missing for the requested
/// locale it falls back to English per file, so partial translations never
/// break the app.
class ContentLoader {
  ContentLoader._();

  static const defaultLocale = 'en';

  static Future<ContentBundle> load([String locale = defaultLocale]) async {
    try {
      final rawWeeks = await _loadString(locale, 'weeks.json');
      final decodedWeeks = jsonDecode(rawWeeks) as Map<String, dynamic>;
      final weeks = (decodedWeeks['weeks'] as List)
          .map((w) => WeekContent.fromJson(w as Map<String, dynamic>))
          .toList();

      final rawFlags = await _loadString(locale, 'red_flags.json');
      final decodedFlags = jsonDecode(rawFlags) as Map<String, dynamic>;
      final redFlags = (decodedFlags['red_flags'] as List)
          .map((f) => RedFlag.fromJson(f as Map<String, dynamic>))
          .toList();

      final rawSymptoms = await _loadString(locale, 'common_symptoms.json');
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

  static Future<String> _loadString(String locale, String file) async {
    try {
      return await rootBundle.loadString('assets/content/$locale/$file');
    } catch (_) {
      if (locale == defaultLocale) rethrow;
      return rootBundle.loadString('assets/content/$defaultLocale/$file');
    }
  }
}
