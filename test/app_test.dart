import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nurture/app.dart';

void main() {
  testWidgets('app boots and shows home shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NurtureApp()));
    await tester.pumpAndSettle();
    expect(find.text('Home (Phase 0)'), findsOneWidget);
    expect(find.text('Track'), findsOneWidget);
  });
}
