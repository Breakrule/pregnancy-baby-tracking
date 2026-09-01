import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/db/tables.dart';
import 'package:nurture/data/repositories/appointment_repository.dart';

void main() {
  late AppDatabase db;
  late AppointmentRepository repo;
  final now = DateTime.utc(2026, 9, 1, 12);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = AppointmentRepository(db);
  });

  tearDown(() => db.close());

  test('partitions past vs upcoming and orders correctly', () async {
    await repo.add(
      at: now.subtract(const Duration(days: 7)),
      type: 'Blood test',
    );
    final tomorrowId = await repo.add(
      at: now.add(const Duration(days: 1)),
      type: 'Ultrasound',
      provider: 'Dr. Chen',
      location: 'City Clinic',
    );
    await repo.add(at: now.add(const Duration(days: 14)), type: 'OB visit');

    final upcoming = await repo.watchUpcoming(now).first;
    expect(upcoming.map((a) => a.type), ['Ultrasound', 'OB visit']);
    expect(upcoming.first.provider, 'Dr. Chen');
    expect(upcoming.first.location, 'City Clinic');

    final past = await repo.watchPast(now).first;
    expect(past.single.type, 'Blood test');

    // Completing a future appointment moves it out of upcoming.
    await repo.markCompleted(tomorrowId);
    final upcomingAfter = await repo.watchUpcoming(now).first;
    expect(upcomingAfter.single.type, 'OB visit');
    final pastAfter = await repo.watchPast(now).first;
    expect(pastAfter.map((a) => a.type), ['Ultrasound', 'Blood test']);
  });

  test(
    'cancel marks the appointment cancelled and hides it from upcoming',
    () async {
      final id = await repo.add(
        at: now.add(const Duration(days: 3)),
        type: 'Midwife visit',
      );
      await repo.cancel(id);

      final upcoming = await repo.watchUpcoming(now).first;
      expect(upcoming, isEmpty);
      final past = await repo.watchPast(now).first;
      expect(past.single.status, AppointmentStatus.cancelled);
    },
  );

  test('appointment exactly at now still counts as upcoming', () async {
    await repo.add(at: now, type: 'OB visit');

    final upcoming = await repo.watchUpcoming(now).first;
    expect(upcoming, hasLength(1));
  });
}
