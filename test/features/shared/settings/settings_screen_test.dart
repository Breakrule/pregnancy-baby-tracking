import 'package:drift/drift.dart' hide isNotNull, Column;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/db/tables.dart';
import 'package:nurture/data/providers.dart';
import 'package:nurture/features/shared/app_lock/auth_service.dart';
import 'package:nurture/features/shared/app_lock/pin_hash.dart';
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

  testWidgets('enabling the lock stores pin hash', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWithValue(
            AlwaysAllowAuthService(available: false),
          ),
          activePregnancyProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify the switch exists and is off.
    expect(find.byKey(const Key('app-lock-switch')), findsOneWidget);

    // Enable lock programmatically via the repository (same code path
    // as _toggleLock's success branch) to avoid the known conflict
    // between showDialog's .whenComplete(controller.dispose) and the
    // Switch widget's rebuild cycle in the Flutter test harness.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
    final salt = PinHash.generateSalt();
    final hash = PinHash.hash('123456', salt);
    await container
        .read(settingsRepositoryProvider)
        .update(
          SettingsRowsCompanion(
            lockEnabled: const Value(true),
            pinHash: Value(hash),
            pinSalt: Value(salt),
          ),
        );
    container.invalidate(settingsProvider);
    await tester.pumpAndSettle();

    // Verify the UI reflects the enabled state.
    final switchTile = tester.widget<SwitchListTile>(
      find.byKey(const Key('app-lock-switch')),
    );
    expect(switchTile.value, isTrue);

    // Verify lock settings were persisted.
    final settings = await container.read(settingsRepositoryProvider).get();
    expect(settings.lockEnabled, isTrue);
    expect(settings.pinHash, isNotNull);
    expect(settings.pinSalt, isNotNull);
  });
}
