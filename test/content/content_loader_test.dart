import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/content/content_loader.dart';
import 'package:nurture/content/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late final ContentBundle bundle;

  setUpAll(() async {
    bundle = await ContentLoader.load();
  });

  test('weeks.json parses with weeks 3 through 16 complete', () {
    expect(bundle.weeks.length, 14);
    expect(
      bundle.weeks.map((w) => w.week).toList(),
      List.generate(14, (i) => i + 3),
    );

    final week9 = bundle.weekFor(9)!;
    expect(week9.sizeObject, 'cherry');
    expect(week9.development, isNotEmpty);
    expect(week9.bodyChanges, isNotEmpty);
    expect(week9.tips, isNotEmpty);

    // Red flags loaded from red_flags.json
    expect(bundle.redFlags.length, 9);
    expect(bundle.redFlags.first.key, 'heavy_bleeding');
    expect(bundle.redFlags.first.label, 'Heavy vaginal bleeding');

    // Symptom presets loaded from common_symptoms.json
    expect(bundle.symptomPresets.length, 16);
    expect(bundle.symptomPresets.first.key, 'nausea');
    expect(bundle.symptomPresets.first.label, 'Nausea / morning sickness');
  });

  test('weekFor returns null outside authored range', () {
    expect(bundle.weekFor(30), isNull);
  });

  test('Indonesian content exists and has parity with English', () async {
    final id = await ContentLoader.load('id');

    // Same weeks, same structure.
    expect(id.weeks.map((w) => w.week).toList(), bundle.weeks.map((w) => w.week).toList());
    for (var i = 0; i < id.weeks.length; i++) {
      expect(id.weeks[i].development.length, bundle.weeks[i].development.length);
      expect(id.weeks[i].bodyChanges.length, bundle.weeks[i].bodyChanges.length);
      expect(id.weeks[i].tips.length, bundle.weeks[i].tips.length);
      expect(id.weeks[i].checklist.length, bundle.weeks[i].checklist.length);
      expect(id.weeks[i].sizeCm, bundle.weeks[i].sizeCm);
    }

    // Same red-flag keys.
    expect(
      id.redFlags.map((f) => f.key).toList(),
      bundle.redFlags.map((f) => f.key).toList(),
    );

    // Same symptom preset keys.
    expect(
      id.symptomPresets.map((s) => s.key).toList(),
      bundle.symptomPresets.map((s) => s.key).toList(),
    );
  });

  test('unknown locale falls back to English per file', () async {
    final fallback = await ContentLoader.load('xx');
    expect(fallback.weeks.length, bundle.weeks.length);
    expect(fallback.redFlags.first.label, bundle.redFlags.first.label);
  });
}
