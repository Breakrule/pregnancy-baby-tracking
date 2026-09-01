import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nurture/main.dart' as app;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// On-device MVP golden path: setup wizard → home dashboard → symptom
/// journal (common + red flag) → weight entry.
///
/// Run with a connected device/emulator:
///   flutter test integration_test
///
/// On Android 13+ a first install may prompt for notification permission
/// before the UI is usable; grant it once or pre-grant with:
///   adb shell pm grant com.family.nurture android.permission.POST_NOTIFICATIONS
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 0 MVP golden path', () {
    setUpAll(() async {
      // Start from an empty database so the setup wizard runs even when the
      // app has been used manually on this device.
      final dir = await getApplicationDocumentsDirectory();
      for (final entity in dir.listSync()) {
        if (entity is File &&
            p.basename(entity.path).startsWith('nurture.sqlite')) {
          entity.deleteSync();
        }
      }
    });

    testWidgets('setup, dashboard, symptom journal, red flag, weight', (
      tester,
    ) async {
      await app.main();
      await tester.pumpAndSettle();

      // 1. Empty DB → setup wizard appears.
      expect(find.text('Step 1 of 3'), findsOneWidget);

      // Dating step: accept the picker's preselected date (90 days ago).
      await tester.tap(find.text('Choose a date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // 2. About you: pre-pregnancy weight and height.
      expect(find.text('About you'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), '62');
      await tester.enterText(find.byType(TextFormField).at(1), '165');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // 3. Care team step is optional — finish setup.
      expect(find.text('Care team'), findsOneWidget);
      await tester.tap(find.text('Start tracking'));
      await tester.pumpAndSettle();

      // 4. Home dashboard shows the gestational-age hero for an LMP that
      //    is 90 days back: week 12, day 6, trimester 1.
      expect(find.widgetWithText(AppBar, 'Home'), findsOneWidget);
      expect(find.text('Week 12, Day 6'), findsOneWidget);
      expect(find.text('Trimester 1'), findsOneWidget);

      // 5. Common symptom: saves silently and lands on the history.
      await tester.tap(find.text('Symptom'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Log Symptom'), findsOneWidget);
      await tester.tap(find.text('Nausea / morning sickness'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Contact your provider'), findsNothing);
      expect(find.widgetWithText(AppBar, 'Symptom History'), findsOneWidget);
      expect(find.text('nausea'), findsOneWidget);

      // 6. Red-flag symptom: urgent, non-dismissable dialog.
      await tester.tap(_navLabel('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Symptom'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Heavy vaginal bleeding'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Contact your provider'), findsOneWidget);
      expect(find.textContaining('urgent assessment'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Symptom History'), findsOneWidget);

      // 7. Weight entry appears in the weight history.
      await tester.tap(_navLabel('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weight'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Log Weight'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('weight-field')), '64.2');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Weight History'), findsOneWidget);
      expect(find.text('64.2 kg'), findsOneWidget);
    });
  });
}

/// NavigationBar labels can render more than one Text; scope to the bar and
/// take the first match.
Finder _navLabel(String label) => find
    .descendant(of: find.byType(NavigationBar), matching: find.text(label))
    .first;
