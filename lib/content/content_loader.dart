import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

class ContentLoader {
  ContentLoader._();

  static Future<ContentBundle> load() async {
    final raw = await rootBundle.loadString('assets/content/weeks.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final weeks = (decoded['weeks'] as List)
        .map((w) => WeekContent.fromJson(w as Map<String, dynamic>))
        .toList();
    return ContentBundle(weeks: weeks);
  }
}
