import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Wraps flutter_local_notifications. All scheduling is local —
/// the app never contacts a push service.
class ReminderService {
  ReminderService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channel = AndroidNotificationDetails(
    'medications',
    'Medication reminders',
    channelDescription: 'Daily reminders to take medications',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _appointmentChannel = AndroidNotificationDetails(
    'appointments',
    'Appointment reminders',
    channelDescription: 'Reminders for upcoming appointments',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    final local = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(local.identifier));
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  Future<void> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
  }

  /// Stable notification id derived from the medication id.
  static int medNotificationId(int medicationId) => 100000 + medicationId;
  static int appointmentNotificationId(int appointmentId) =>
      200000 + appointmentId;

  Future<void> scheduleDailyMedication({
    required int medicationId,
    required String name,
    required String dose,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final next = nextOccurrence(now, hour, minute);
    final when = tz.TZDateTime.from(next, tz.local);
    await _plugin.zonedSchedule(
      medNotificationId(medicationId),
      'Time for $name',
      dose.isEmpty ? 'Take your $name' : 'Take $name ($dose)',
      when,
      const NotificationDetails(android: _channel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleAppointment({
    required int appointmentId,
    required String type,
    required DateTime at,
  }) async {
    final reminderAt = at.subtract(const Duration(hours: 24));
    final tzTime = tz.TZDateTime.from(reminderAt, tz.local);
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      appointmentNotificationId(appointmentId),
      'Appointment tomorrow',
      '$type at ${formatTime(at)}',
      tzTime,
      const NotificationDetails(android: _appointmentChannel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelMedication(int medicationId) =>
      _plugin.cancel(medNotificationId(medicationId));

  Future<void> cancelAppointment(int appointmentId) =>
      _plugin.cancel(appointmentNotificationId(appointmentId));

  /// Visible for testing: given [now], returns the next occurrence of
  /// [hour]:[minute]. If the time has already passed today (or is exactly
  /// now), rolls to tomorrow.
  static DateTime nextOccurrence(DateTime now, int hour, int minute) {
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static String formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
