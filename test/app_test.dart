import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nurture/app.dart';
import 'package:nurture/content/models.dart';
import 'package:nurture/content/providers.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/db/tables.dart';
import 'package:nurture/data/providers.dart';
import 'package:nurture/features/shared/app_lock/auth_service.dart';
import 'package:nurture/features/shared/reminders/reminder_service.dart';
import 'package:nurture/features/shared/splash/app_bootstrap.dart';

class _NoopReminderService extends ReminderService {
  _NoopReminderService() : super(FlutterLocalNotificationsPlugin());

  @override
  Future<void> initialize() async {}

  @override
  String? initialRoute() => null;

  @override
  Future<void> requestPermission() async {}
}

void main() {
  testWidgets('app boots through the splash and shows home shell', (
    tester,
  ) async {
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
        reminderServiceProvider.overrideWithValue(_NoopReminderService()),
        // Skip the splash's minimum display duration in tests.
        splashMinDurationProvider.overrideWithValue(Duration.zero),
        contentProvider.overrideWith((ref) => const ContentBundle(weeks: [])),
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
    // Splash is visible while the bootstrap runs.
    expect(find.text('Nurture'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Home'), findsOneWidget);
    expect(find.text('Track'), findsOneWidget);

    // Tear down provider tree to cancel Drift stream timers
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
