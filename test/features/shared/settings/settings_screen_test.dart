import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/db/tables.dart';
import 'package:nurture/data/providers.dart';
import 'package:nurture/features/shared/app_lock/auth_service.dart';
import 'package:nurture/features/shared/settings/settings_screen.dart';

void main() {
  testWidgets('changing weight unit dropdown persists to DB', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWithValue(
            AlwaysAllowAuthService(available: false),
          ),
          // Override the stream provider to avoid drift stream-query timers
          // that cause "Timer is still pending" errors during test disposal.
          activePregnancyProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Find and tap the weight unit dropdown.
    final dropdownFinder = find.byKey(const Key('weight-unit-dropdown'));
    expect(dropdownFinder, findsOneWidget);
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    // Select 'lb' from the menu.
    await tester.tap(find.text('lb').last);
    await tester.pumpAndSettle();

    // Read the repository directly and verify persistence.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
    final settings = await container.read(settingsRepositoryProvider).get();
    expect(settings.weightUnit, WeightUnit.lb);
  });
}
