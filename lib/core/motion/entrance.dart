import 'package:flutter/widgets.dart';

import 'motion_tokens.dart';
import 'reduced_motion.dart';

/// Fades the child in with a small upward slide. Use for screen-section
/// entrances. Honors [MotionContext.reduceMotion].
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.slide = const Offset(0, 0.05),
  });

  final Widget child;

  /// Delay before the entrance starts (used for staggered entrances).
  final Duration delay;

  /// Starting offset as a fraction of the child's size.
  final Offset slide;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MotionTokens.normal,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: MotionTokens.enter,
  );
  late final Animation<Offset> _position = Tween<Offset>(
    begin: widget.slide,
    end: Offset.zero,
  ).animate(_progress);

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (context.reduceMotion) {
      _controller.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay).then((_) {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _progress,
      child: SlideTransition(position: _position, child: widget.child),
    );
  }
}

/// Wraps each child in a [FadeSlideIn] with an increasing delay so a
/// screen's sections cascade in gently. Layout is not imposed — use the
/// returned list inside any Column.
List<Widget> staggerChildren(List<Widget> children) {
  return [
    for (var i = 0; i < children.length; i++)
      FadeSlideIn(delay: MotionTokens.staggerStep * i, child: children[i]),
  ];
}
