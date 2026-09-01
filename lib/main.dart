import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/providers.dart';
import 'features/shared/reminders/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Reminder initialization (timezone lookup, plugin setup, permission
  // request) happens inside the app bootstrap so the splash covers it and
  // failures can never block startup.
  final reminders = ReminderService(FlutterLocalNotificationsPlugin());
  runApp(
    ProviderScope(
      overrides: [reminderServiceProvider.overrideWithValue(reminders)],
      child: const NurtureApp(),
    ),
  );
}
