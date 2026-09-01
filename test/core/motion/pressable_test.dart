import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/core/motion/pressable.dart';

void main() {
  testWidgets('scales down while pressed and back on release', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PressableScale(
          child: GestureDetector(
            onTap: () => taps++,
            child: const ColoredBox(
              color: Color(0xFF000000),
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      ),
    );

    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.scale, 1.0);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PressableScale)),
    );
    await tester.pump();
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      0.97,
    );

    await gesture.up();
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1.0);

    // The wrapper must not swallow taps.
    expect(taps, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('stays static under reduced motion', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: PressableScale(child: SizedBox(width: 50, height: 50)),
        ),
      ),
    );
    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.duration, Duration.zero);
  });
}
