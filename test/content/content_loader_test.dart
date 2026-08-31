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
  });

  test('weekFor returns null outside authored range', () {
    expect(bundle.weekFor(30), isNull);
  });
}
