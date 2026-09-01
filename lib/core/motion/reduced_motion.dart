import 'package:flutter/widgets.dart';

extension MotionContext on BuildContext {
  /// True when the platform asks us to minimize motion (Android's
  /// "Remove animations" accessibility setting). Decorative animation must
  /// be skipped entirely in that case — render final states immediately.
  bool get reduceMotion => MediaQuery.maybeOf(this)?.disableAnimations ?? false;
}
