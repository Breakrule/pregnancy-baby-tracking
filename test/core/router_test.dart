import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/core/router.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/db/tables.dart';
import 'package:nurture/data/providers.dart';
import 'package:nurture/features/shared/app_lock/auth_service.dart';

void main() {
  testWidgets(
    'malformed /learn/week/:w redirects to /learn instead of crashing',
    (tester) async {
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

      final router = buildRouter(hasPregnancy: () async => true);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            authServiceProvider.overrideWithValue(
              AlwaysAllowAuthService(available: false),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to a malformed deep link
      router.go('/learn/week/abc');
      await tester.pumpAndSettle();

      // Should NOT crash and should show the Learn screen (redirected to /learn).
      // Scoped to the AppBar because the NavigationBar destination label also
      // renders the text 'Learn'.
      expect(find.widgetWithText(AppBar, 'Learn'), findsOneWidget);
      expect(find.text('All Weeks'), findsOneWidget);

      // Tear down the provider tree inside the test body: disposing the
      // StreamProvider cancels a Drift watch stream, which schedules a
      // zero-duration close timer. Doing it here (and advancing fake time)
      // lets that timer fire before the binding asserts no timers remain.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 10));
    },
  );
}
