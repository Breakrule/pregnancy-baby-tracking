import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/core/motion/entrance.dart';
import 'package:nurture/core/motion/motion_tokens.dart';

Widget _host(Widget child, {bool disableAnimations = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  );
}

void main() {
  testWidgets('FadeSlideIn fades in and settles fully visible', (tester) async {
    await tester.pumpWidget(_host(const FadeSlideIn(child: Text('hello'))));
    final fade = tester.widget<FadeTransition>(find.byType(FadeTransition));
    expect(fade.opacity.value, 0.0);

    await tester.pumpAndSettle();
    expect(fade.opacity.value, 1.0);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('FadeSlideIn respects a stagger delay', (tester) async {
    await tester.pumpWidget(
      _host(
        const FadeSlideIn(
          delay: Duration(milliseconds: 100),
          child: Text('late'),
        ),
      ),
    );
    final fade = tester.widget<FadeTransition>(find.byType(FadeTransition));
    // Delay not yet elapsed.
    await tester.pump(const Duration(milliseconds: 50));
    expect(fade.opacity.value, 0.0);

    await tester.pumpAndSettle();
    expect(fade.opacity.value, 1.0);
  });

  testWidgets('FadeSlideIn renders instantly under reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const FadeSlideIn(child: Text('static')), disableAnimations: true),
    );
    // A single pump: no settle needed.
    final fade = tester.widget<FadeTransition>(find.byType(FadeTransition));
    expect(fade.opacity.value, 1.0);
  });

  test('staggerChildren assigns increasing delays', () {
    final wrapped = staggerChildren([
      const Text('a'),
      const Text('b'),
      const Text('c'),
    ]).cast<FadeSlideIn>();
    expect(wrapped.length, 3);
    expect(wrapped[0].delay, Duration.zero);
    expect(wrapped[1].delay, MotionTokens.staggerStep);
    expect(wrapped[2].delay, MotionTokens.staggerStep * 2);
  });
}
