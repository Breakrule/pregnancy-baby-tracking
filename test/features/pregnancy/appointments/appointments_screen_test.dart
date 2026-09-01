import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/providers.dart';
import 'package:nurture/data/repositories/appointment_repository.dart';
import 'package:nurture/features/pregnancy/appointments/appointments_screen.dart';

import '../../../test_app.dart';

void main() {
  testWidgets('upcoming and past appointments are partitioned', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final repo = AppointmentRepository(db);
    await repo.add(
      at: DateTime.now().add(const Duration(days: 1)),
      type: 'Ultrasound',
      provider: 'Dr. Chen',
      location: 'City Clinic',
    );
    await repo.add(
      at: DateTime.now().subtract(const Duration(days: 7)),
      type: 'Blood test',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: localizedApp(const AppointmentsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Past'), findsOneWidget);
    expect(find.text('Ultrasound'), findsOneWidget);
    expect(find.text('Blood test'), findsOneWidget);

    // Tear down the provider tree to cancel Drift stream timers
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
