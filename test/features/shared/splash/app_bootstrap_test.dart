import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/content/models.dart';
import 'package:nurture/content/providers.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/providers.dart';
import 'package:nurture/features/shared/reminders/reminder_service.dart';
import 'package:nurture/features/shared/splash/app_bootstrap.dart';
import 'package:nurture/features/shared/splash/pending_route_provider.dart';

class _NoopReminderService extends ReminderService {
  _NoopReminderService() : super(FlutterLocalNotificationsPlugin());

  bool initializeCalled = false;

  @override
  Future<void> initialize() async {
    initializeCalled = true;
  }

  @override
  String? initialRoute() => null;

  @override
  Future<void> requestPermission() async {}
}

class _ThrowingReminderService extends _NoopReminderService {
  @override
  Future<void> initialize() async {
    throw StateError('no notification plugin on this device');
  }
}

void main() {
  group('remainingSplashDelay', () {
    test('returns remaining time when elapsed is below the minimum', () {
      expect(
        remainingSplashDelay(
          const Duration(milliseconds: 400),
          const Duration(milliseconds: 1400),
        ),
        const Duration(milliseconds: 1000),
      );
    });

    test('returns zero once the minimum has passed', () {
      expect(
        remainingSplashDelay(
          const Duration(milliseconds: 1400),
          const Duration(milliseconds: 1400),
        ),
        Duration.zero,
      );
      expect(
        remainingSplashDelay(
          const Duration(seconds: 3),
          const Duration(milliseconds: 1400),
        ),
        Duration.zero,
      );
    });
  });

  group('bootstrapProvider', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    ProviderContainer makeContainer(ReminderService reminders) {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          reminderServiceProvider.overrideWithValue(reminders),
          splashMinDurationProvider.overrideWithValue(Duration.zero),
          contentProvider.overrideWith((ref) => const ContentBundle(weeks: [])),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('completes ready and initializes reminders', () async {
      final reminders = _NoopReminderService();
      final container = makeContainer(reminders);
      final state = await container.read(bootstrapProvider.future);
      expect(state.ready, isTrue);
      expect(reminders.initializeCalled, isTrue);
    });

    test('never fails boot when notifications are unavailable', () async {
      final container = makeContainer(_ThrowingReminderService());
      final state = await container.read(bootstrapProvider.future);
      expect(state.ready, isTrue);
    });

    test('captures a launch-notification route as pending route', () async {
      final reminders = _PendingRouteReminderService();
      final container = makeContainer(reminders);
      await container.read(bootstrapProvider.future);
      expect(container.read(pendingRouteProvider), '/track/medications');
    });
  });
}

class _PendingRouteReminderService extends _NoopReminderService {
  @override
  String? initialRoute() => '/track/medications';
}
