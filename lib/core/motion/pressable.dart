import 'package:flutter/widgets.dart';

import 'motion_tokens.dart';
import 'reduced_motion.dart';

/// Scales the child down slightly while pressed and springs back on
/// release — transform-only, compositor-cheap press feedback. Does not
/// intercept taps; wrap buttons directly. Static under
/// [MotionContext.reduceMotion].
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
  });

  final Widget child;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final duration = context.reduceMotion ? Duration.zero : MotionTokens.fast;
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: duration,
        child: widget.child,
      ),
    );
  }
}
