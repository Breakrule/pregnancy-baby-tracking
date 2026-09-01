import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/providers.dart';
import 'features/shared/reminders/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final reminders = ReminderService(FlutterLocalNotificationsPlugin());
  await reminders.initialize();
  await reminders.requestPermission();
  runApp(
    ProviderScope(
      overrides: [reminderServiceProvider.overrideWithValue(reminders)],
      child: const NurtureApp(),
    ),
  );
}
