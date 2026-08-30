import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nurture/core/router.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/providers.dart';
import 'package:nurture/features/shared/app_lock/auth_service.dart';

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
}

class RouterApp extends StatelessWidget {
  const RouterApp({super.key, required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context) =>
      MaterialApp.router(routerConfig: router);
}
