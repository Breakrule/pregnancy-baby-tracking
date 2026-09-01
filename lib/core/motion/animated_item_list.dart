import 'package:flutter/material.dart';

import 'motion_tokens.dart';

/// A stream-backed list that animates insertions and removals as new data
/// arrives. Items are diffed by [itemId]; intended for Drift-backed history
/// lists where items are added or deleted (not reordered — reorder-only
/// diffs render without animation).
///
/// Initial items render without an entrance animation.
class AnimatedItemStream<T> extends StatefulWidget {
  const AnimatedItemStream({
    super.key,
    required this.items,
    required this.itemId,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
  });

  final List<T> items;
  final Object Function(T item) itemId;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final EdgeInsetsGeometry padding;

  @override
  State<AnimatedItemStream<T>> createState() => _AnimatedItemStreamState<T>();
}

class _AnimatedItemStreamState<T> extends State<AnimatedItemStream<T>> {
  final _listKey = GlobalKey<AnimatedListState>();
  late final List<T> _items = List<T>.of(widget.items);

  @override
  void didUpdateWidget(covariant AnimatedItemStream<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyDiff();
  }

  void _applyDiff() {
    final next = widget.items;
    final nextIds = next.map(widget.itemId).toSet();

    // Removals first, highest index first, so indices stay valid.
    for (var i = _items.length - 1; i >= 0; i--) {
      if (!nextIds.contains(widget.itemId(_items[i]))) {
        final removed = _items.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _ListTransition(
            animation: animation,
            curve: MotionTokens.exit,
            child: widget.itemBuilder(context, removed),
          ),
          duration: MotionTokens.normal,
        );
      }
    }

    // Insertions, lowest index first.
    final currentIds = _items.map(widget.itemId).toSet();
    for (var i = 0; i < next.length; i++) {
      final id = widget.itemId(next[i]);
      if (!currentIds.contains(id)) {
        _items.insert(i, next[i]);
        currentIds.add(id);
        _listKey.currentState?.insertItem(i, duration: MotionTokens.normal);
      }
    }

    // Slots where the item changed (content edit) or shifted position
    // (reorder): AnimatedList caches built children at insert time, so swap
    // each such slot with a zero-duration remove+insert to force a rebuild
    // without any visible motion. After the phases above, indices line up
    // 1:1 with [next].
    for (var i = 0; i < next.length && i < _items.length; i++) {
      final sameId = widget.itemId(_items[i]) == widget.itemId(next[i]);
      if (!sameId || _items[i] != next[i]) {
        _items[i] = next[i];
        final state = _listKey.currentState;
        if (state != null) {
          state.removeItem(
            i,
            (context, animation) => const SizedBox.shrink(),
            duration: Duration.zero,
          );
          state.insertItem(i, duration: Duration.zero);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      padding: widget.padding,
      initialItemCount: _items.length,
      itemBuilder: (context, index, animation) => _ListTransition(
        animation: animation,
        curve: MotionTokens.enter,
        child: widget.itemBuilder(context, _items[index]),
      ),
    );
  }
}

/// Collapse + fade used for both insert (forward) and remove (reverse).
class _ListTransition extends StatelessWidget {
  const _ListTransition({
    required this.animation,
    required this.curve,
    required this.child,
  });

  final Animation<double> animation;
  final Curve curve;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: curve);
    return SizeTransition(
      sizeFactor: curved,
      child: FadeTransition(opacity: curved, child: child),
    );
  }
}
