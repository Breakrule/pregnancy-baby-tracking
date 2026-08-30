import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nurture/app.dart';
import 'package:nurture/data/db/app_database.dart';
import 'package:nurture/data/providers.dart';

void main() {
  testWidgets('app boots and shows home shell', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const NurtureApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home (Phase 0)'), findsOneWidget);
    expect(find.text('Track'), findsOneWidget);
  });
}
