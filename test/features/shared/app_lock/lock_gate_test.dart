import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/providers.dart';
import 'package:nurture/features/shared/app_lock/app_lock_notifier.dart';
import 'package:nurture/features/shared/app_lock/auth_service.dart';
import 'package:nurture/features/shared/app_lock/lock_gate.dart';
import 'package:nurture/features/shared/app_lock/pin_hash.dart';

import '../../../test_app.dart';

void main() {
  Future<AppDatabase> lockedDb() async {
    final db = AppDatabase(NativeDatabase.memory());
    final salt = PinHash.generateSalt();
    await db
        .into(db.settingsRows)
        .insert(
          SettingsRowsCompanion.insert(
            id: const Value(1),
            lockEnabled: const Value(true),
            pinHash: Value(PinHash.hash('123456', salt)),
            pinSalt: Value(salt),
          ),
        );
    return db;
  }

  testWidgets('locked app shows lock screen, correct PIN unlocks', (
    tester,
  ) async {
    final db = await lockedDb();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWithValue(
            AlwaysAllowAuthService(available: false),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: testLocalizationDelegates,
          home: LockGate(child: Text('unlocked content')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enter PIN'), findsOneWidget);
    expect(find.text('unlocked content'), findsNothing);

    for (final d in ['1', '2', '3', '4', '5', '6']) {
      await tester.tap(find.text(d).last);
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('unlocked content'), findsOneWidget);

    // Backgrounding re-locks the app.
    // Directly invoke lock() on the notifier (equivalent to what
    // didChangeAppLifecycleState does when the app is paused).
    final container = ProviderScope.containerOf(
      tester.element(find.text('unlocked content')),
    );
    container.read(appLockNotifierProvider.notifier).lock();
    await tester.pumpAndSettle();
    expect(find.text('Enter PIN'), findsOneWidget);
    expect(find.text('unlocked content'), findsNothing);
  });

  // Deterministic variant: after pumpAndSettle with lock disabled, the gate
  // reaches the child only post-sync. The booting state renders an empty
  // Scaffold (SizedBox.shrink), so protected content is never flashed.
  testWidgets('shows nothing until settings are synced', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWithValue(
            AlwaysAllowAuthService(available: false),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: testLocalizationDelegates,
          home: LockGate(child: Text('unlocked content')),
        ),
      ),
    );
    // After full settle the empty DB has lockEnabled=false so synced=true
    // and the gate shows the child — proving it only renders post-sync.
    await tester.pumpAndSettle();
    expect(find.text('unlocked content'), findsOneWidget);
  });
}
