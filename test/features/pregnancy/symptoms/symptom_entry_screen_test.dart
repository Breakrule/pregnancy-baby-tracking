import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/content/models.dart';
import 'package:nurture/content/providers.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/db/tables.dart';
import 'package:nurture/data/providers.dart';
import 'package:nurture/domain/alerts/alert.dart';
import 'package:nurture/domain/alerts/alert_engine.dart';
import 'package:nurture/domain/alerts/symptom_rules.dart';
import 'package:nurture/features/pregnancy/symptoms/symptom_entry_screen.dart';
import 'package:nurture/features/shared/app_lock/auth_service.dart';

import '../../../test_app.dart';

/// Hand-built content bundle to avoid loading real assets in widget tests.
final _testBundle = ContentBundle(
  weeks: const [],
  redFlags: const [
    RedFlag(
      key: 'heavy_bleeding',
      label: 'Heavy vaginal bleeding',
      message:
          'Heavy bleeding in pregnancy needs urgent assessment. Contact your provider now or go to the emergency department.',
    ),
  ],
  symptomPresets: const [
    SymptomPreset(key: 'nausea', label: 'Nausea / morning sickness'),
    SymptomPreset(key: 'heavy_bleeding', label: 'Heavy vaginal bleeding'),
  ],
);

void main() {
  testWidgets('red-flag symptom shows urgent dialog on save', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // Insert a pregnancy record so activePregnancyProvider resolves
    await db
        .into(db.pregnancies)
        .insert(
          PregnanciesCompanion.insert(
            lmpDate: DateTime.utc(2026, 1, 1),
            dueDate: DateTime.utc(2026, 10, 8),
            conceptionSource: ConceptionSource.lmp,
            prePregnancyWeightKg: 62,
            heightCm: 165,
            clinicPhone: Value('555-0100'),
          ),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWithValue(
            AlwaysAllowAuthService(available: false),
          ),
          contentProvider.overrideWith((ref) async => _testBundle),
        ],
        child: localizedApp(const SymptomEntryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the "Heavy vaginal bleeding" chip
    expect(find.text('Heavy vaginal bleeding'), findsOneWidget);
    await tester.tap(find.text('Heavy vaginal bleeding'));
    await tester.pumpAndSettle();

    // Pick severe severity
    await tester.tap(find.text('Severe'));
    await tester.pumpAndSettle();

    // Tap Save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Expect the urgent dialog with "Contact your provider"
    expect(find.text('Contact your provider'), findsOneWidget);
    expect(find.textContaining('urgent assessment'), findsOneWidget);
    expect(find.text('Call provider'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    // Dismiss dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Tear down provider tree for Drift stream timers
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('common symptom saves and pops without dialog', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db
        .into(db.pregnancies)
        .insert(
          PregnanciesCompanion.insert(
            lmpDate: DateTime.utc(2026, 1, 1),
            dueDate: DateTime.utc(2026, 10, 8),
            conceptionSource: ConceptionSource.lmp,
            prePregnancyWeightKg: 62,
            heightCm: 165,
          ),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWithValue(
            AlwaysAllowAuthService(available: false),
          ),
          contentProvider.overrideWith((ref) async => _testBundle),
        ],
        child: MaterialApp(
          localizationsDelegates: testLocalizationDelegates,
          home: Navigator(
            onGenerateRoute: (_) =>
                MaterialPageRoute(builder: (_) => const SymptomEntryScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the "Nausea / morning sickness" chip
    expect(find.text('Nausea / morning sickness'), findsOneWidget);
    await tester.tap(find.text('Nausea / morning sickness'));
    await tester.pumpAndSettle();

    // Tap Save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // No urgent dialog should appear
    expect(find.text('Contact your provider'), findsNothing);

    // Screen should have popped (the entry screen is no longer visible)
    expect(find.text('Log Symptom'), findsNothing);

    // Verify the symptom was actually saved to DB
    final symptoms = await db.select(db.symptoms).get();
    expect(symptoms.length, 1);
    expect(symptoms.first.typeKey, 'nausea');

    // Tear down provider tree for Drift stream timers
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('warning symptom shows amber SnackBar and stays on screen', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db
        .into(db.pregnancies)
        .insert(
          PregnanciesCompanion.insert(
            lmpDate: DateTime.utc(2026, 1, 1),
            dueDate: DateTime.utc(2026, 10, 8),
            conceptionSource: ConceptionSource.lmp,
            prePregnancyWeightKg: 62,
            heightCm: 165,
          ),
        );

    final warningEngine = AlertEngine([
      (event) {
        if (event is! SymptomLogged) return null;
        return const Alert(
          severity: AlertSeverity.warning,
          title: 'Heads up',
          message: 'Consider resting and hydrating.',
        );
      },
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWithValue(
            AlwaysAllowAuthService(available: false),
          ),
          contentProvider.overrideWith((ref) async => _testBundle),
          alertEngineProvider.overrideWithValue(warningEngine),
        ],
        child: localizedApp(const SymptomEntryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the "Nausea / morning sickness" chip
    expect(find.text('Nausea / morning sickness'), findsOneWidget);
    await tester.tap(find.text('Nausea / morning sickness'));
    await tester.pumpAndSettle();

    // Tap Save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Expect the amber SnackBar message
    expect(find.text('Consider resting and hydrating.'), findsOneWidget);

    // Screen should still be visible (not popped)
    expect(find.text('Log Symptom'), findsOneWidget);

    // Save button must be disabled after a warning save (double-submit guard)
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text('Save'),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );

    // Verify the symptom was saved to DB
    final symptoms = await db.select(db.symptoms).get();
    expect(symptoms.length, 1);
    expect(symptoms.first.typeKey, 'nausea');

    // Tear down provider tree for Drift stream timers
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
