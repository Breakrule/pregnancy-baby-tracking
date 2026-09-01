import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nurture/core/router.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/db/tables.dart';
import 'package:nurture/data/providers.dart';
import 'package:nurture/features/shared/app_lock/auth_service.dart';

import '../../../test_app.dart';

void main() {
  testWidgets('setup redirect: no pregnancy sends user to /setup', (
    tester,
  ) async {
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
        child: RouterApp(router: buildRouter(hasPregnancy: () async => false)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Nurture'), findsOneWidget);
  });

  testWidgets('pregnancy exists: /setup redirects to home', (tester) async {
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
        child: RouterApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    router.go('/setup');
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Nurture'), findsNothing);
    expect(find.widgetWithText(AppBar, 'Home'), findsOneWidget);

    // Tear down provider tree to cancel Drift stream timers
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });
}

class RouterApp extends StatelessWidget {
  const RouterApp({super.key, required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: testLocalizationDelegates,
  );
}
