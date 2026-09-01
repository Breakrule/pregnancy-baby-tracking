import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/core/motion/animated_item_list.dart';

class _Item {
  const _Item(this.id, this.label);

  final int id;
  final String label;
}

class _Host extends StatefulWidget {
  const _Host({required this.items});

  final List<_Item> items;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AnimatedItemStream<_Item>(
        items: widget.items,
        itemId: (item) => item.id,
        itemBuilder: (context, item) => Text(item.label),
      ),
    );
  }
}

void main() {
  testWidgets('renders initial items without animation', (tester) async {
    await tester.pumpWidget(
      const _Host(items: [_Item(1, 'one'), _Item(2, 'two')]),
    );
    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsOneWidget);
  });

  testWidgets('animates an inserted item in', (tester) async {
    await tester.pumpWidget(const _Host(items: [_Item(1, 'one')]));

    await tester.pumpWidget(
      const _Host(items: [_Item(3, 'three'), _Item(1, 'one')]),
    );
    // Mid-insertion: present but still transitioning.
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('three'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('three'), findsOneWidget);
    expect(find.text('one'), findsOneWidget);
  });

  testWidgets('animates a removed item out', (tester) async {
    await tester.pumpWidget(
      const _Host(items: [_Item(1, 'one'), _Item(2, 'two')]),
    );

    await tester.pumpWidget(const _Host(items: [_Item(2, 'two')]));
    await tester.pumpAndSettle();
    expect(find.text('one'), findsNothing);
    expect(find.text('two'), findsOneWidget);
  });

  testWidgets('content changes for existing ids re-render in place', (
    tester,
  ) async {
    await tester.pumpWidget(const _Host(items: [_Item(1, 'before')]));
    await tester.pumpWidget(const _Host(items: [_Item(1, 'after')]));
    await tester.pump();
    expect(find.text('after'), findsOneWidget);
    expect(find.text('before'), findsNothing);
  });
}
