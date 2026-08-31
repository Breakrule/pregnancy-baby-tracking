class WeekContent {
  const WeekContent({
    required this.week,
    required this.sizeObject,
    required this.sizeCm,
    required this.development,
    required this.bodyChanges,
    required this.tips,
    required this.checklist,
  });

  factory WeekContent.fromJson(Map<String, dynamic> json) => WeekContent(
    week: json['week'] as int,
    sizeObject: json['size_object'] as String,
    sizeCm: (json['size_cm'] as num).toDouble(),
    development: (json['development'] as List).cast<String>(),
    bodyChanges: (json['body_changes'] as List).cast<String>(),
    tips: (json['tips'] as List).cast<String>(),
    checklist: (json['checklist'] as List).cast<String>(),
  );

  final int week;
  final String sizeObject;
  final double sizeCm;
  final List<String> development;
  final List<String> bodyChanges;
  final List<String> tips;
  final List<String> checklist;
}

class RedFlag {
  const RedFlag({
    required this.key,
    required this.label,
    required this.message,
  });

  factory RedFlag.fromJson(Map<String, dynamic> json) => RedFlag(
    key: json['key'] as String,
    label: json['label'] as String,
    message: json['message'] as String,
  );

  final String key;
  final String label;
  final String message;
}

class SymptomPreset {
  const SymptomPreset({required this.key, required this.label});

  factory SymptomPreset.fromJson(Map<String, dynamic> json) =>
      SymptomPreset(key: json['key'] as String, label: json['label'] as String);

  final String key;
  final String label;
}

class ContentBundle {
  const ContentBundle({
    required this.weeks,
    this.redFlags = const [],
    this.symptomPresets = const [],
  });

  final List<WeekContent> weeks;
  final List<RedFlag> redFlags;
  final List<SymptomPreset> symptomPresets;

  WeekContent? weekFor(int week) {
    for (final w in weeks) {
      if (w.week == week) return w;
    }
    return null;
  }
}
