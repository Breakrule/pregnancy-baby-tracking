import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/features/shared/reminders/reminder_service.dart';

void main() {
  test('schedules today when time not passed', () {
    final now = DateTime(2026, 8, 30, 7, 0);
    final next = ReminderService.nextOccurrence(now, 8, 30);
    expect(next, DateTime(2026, 8, 30, 8, 30));
  });

  test('rolls to tomorrow when time passed', () {
    final now = DateTime(2026, 8, 30, 9, 0);
    final next = ReminderService.nextOccurrence(now, 8, 30);
    expect(next, DateTime(2026, 8, 31, 8, 30));
  });

  test('exact current minute rolls to tomorrow', () {
    final now = DateTime(2026, 8, 30, 8, 30);
    final next = ReminderService.nextOccurrence(now, 8, 30);
    expect(next, DateTime(2026, 8, 31, 8, 30));
  });
}
