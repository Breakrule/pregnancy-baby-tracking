import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/content/models.dart';
import 'package:nurture/content/providers.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/db/tables.dart';
import 'package:nurture/data/providers.dart';
import 'package:nurture/features/pregnancy/home/home_screen.dart';
import 'package:nurture/features/shared/app_lock/auth_service.dart';

void main() {
  testWidgets('home screen shows gestational age and countdown', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // LMP 66 days before the fixed clock → Week 9, Day 3
    final fixedNow = DateTime.utc(2026, 3, 10);
    final lmp = fixedNow.subtract(const Duration(days: 66));
    final dueDate = lmp.add(const Duration(days: 280));

    await db
        .into(db.pregnancies)
        .insert(
          PregnanciesCompanion.insert(
            lmpDate: lmp,
            dueDate: dueDate,
            conceptionSource: ConceptionSource.lmp,
            prePregnancyWeightKg: 62,
            heightCm: 165,
          ),
        );

    // Build a mock content bundle with week 9 data
    const mockBundle = ContentBundle(
      weeks: [
        WeekContent(
          week: 9,
          sizeObject: 'cherry',
          sizeCm: 2.3,
          development: ['test'],
          bodyChanges: ['test'],
          tips: ['test'],
          checklist: ['test'],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWithValue(
            AlwaysAllowAuthService(available: false),
          ),
          contentProvider.overrideWith((ref) async => mockBundle),
        ],
        child: MaterialApp(home: HomeScreen(now: fixedNow)),
      ),
    );
    await tester.pumpAndSettle();

    // Verify gestational age label
    expect(find.textContaining('Week 9, Day 3'), findsOneWidget);

    // Verify countdown line
    expect(find.text('214 days to go'), findsOneWidget);

    // Verify trimester chip
    expect(find.text('Trimester 1'), findsOneWidget);

    // Verify size line from content bundle
    expect(find.textContaining('cherry'), findsOneWidget);
    expect(find.textContaining('~2.3 cm'), findsOneWidget);

    // Verify quick action buttons exist
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('Symptom'), findsOneWidget);
    expect(find.text('Appt'), findsOneWidget);

    // Verify red-flags button
    expect(find.text('When to call your provider'), findsOneWidget);

    // Verify Today card
    expect(find.text('Today'), findsOneWidget);
    expect(find.textContaining('No upcoming appointments'), findsOneWidget);
    expect(find.text('Medications appear here soon'), findsOneWidget);

    // Tear down the provider tree to cancel Drift stream timers
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
