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

class ContentBundle {
  const ContentBundle({required this.weeks});

  final List<WeekContent> weeks;

  WeekContent? weekFor(int week) {
    for (final w in weeks) {
      if (w.week == week) return w;
    }
    return null;
  }
}
