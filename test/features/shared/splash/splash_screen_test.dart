import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/features/shared/settings/locale_provider.dart';
import 'package:nurture/features/shared/splash/splash_screen.dart';

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [localeProvider.overrideWithValue(const Locale('en'))],
      child: child,
    );
  }

  testWidgets('animates the brand mark and shows the app name', (tester) async {
    await tester.pumpWidget(wrap(const SplashScreen()));
    // Mid-animation: the tagline has not fully faded in yet.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Nurture'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Nurture'), findsOneWidget);
  });

  testWidgets('renders statically when animations are disabled', (
    tester,
  ) async {
    tester.view.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(wrap(const SplashScreen()));
    // A single pump (no settle): everything must already be in its final,
    // fully visible state.
    expect(find.text('Nurture'), findsOneWidget);
    final fades = tester
        .widgetList<FadeTransition>(find.byType(FadeTransition))
        .toList();
    expect(fades, isNotEmpty);
    expect(fades.map((w) => w.opacity.value).every((o) => o == 1.0), isTrue);
    final scale = tester.widget<ScaleTransition>(find.byType(ScaleTransition));
    expect(scale.scale.value, 1.0);
  });
}
