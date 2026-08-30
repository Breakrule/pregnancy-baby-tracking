import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nurture/app.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/db/tables.dart';
import 'package:nurture/data/providers.dart';
import 'package:nurture/features/shared/app_lock/auth_service.dart';

void main() {
  testWidgets('app boots and shows home shell', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    // Seed a pregnancy so the redirect guard allows /home.
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

    // Use a container we can dispose explicitly before the test ends,
    // so Drift stream subscriptions are cancelled before the framework
    // checks for pending timers.
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authServiceProvider.overrideWithValue(
          AlwaysAllowAuthService(available: false),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NurtureApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home (Phase 0)'), findsOneWidget);
    expect(find.text('Track'), findsOneWidget);
  });
}
