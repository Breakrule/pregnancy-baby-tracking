import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/providers.dart';
import 'features/shared/reminders/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final reminders = ReminderService(FlutterLocalNotificationsPlugin());
  try {
    await reminders.initialize();
  } catch (e) {
    // Notifications are non-critical: some emulators/devices cannot
    // initialize the plugin (e.g. no Google Play). The app must still boot.
    debugPrint('Notification initialization failed: $e');
  }
  // Requested without awaiting so a system permission dialog can never block
  // startup; reminders keep working once permission is granted.
  unawaited(
    reminders.requestPermission().catchError((Object e) {
      debugPrint('Notification permission request failed: $e');
    }),
  );
  runApp(
    ProviderScope(
      overrides: [reminderServiceProvider.overrideWithValue(reminders)],
      child: const NurtureApp(),
    ),
  );
}
