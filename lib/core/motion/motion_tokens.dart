import 'package:flutter/animation.dart';

/// Canonical motion values for the app. Keep animations short and
/// purposeful; nothing loops, and nothing delays user input.
abstract final class MotionTokens {
  /// Press states, toggles.
  static const fast = Duration(milliseconds: 120);

  /// Entrances, list insert/remove, tab switches.
  static const normal = Duration(milliseconds: 220);

  /// Hero cards, large state changes.
  static const slow = Duration(milliseconds: 350);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;

  /// Delay between successive items of a staggered entrance.
  static const staggerStep = Duration(milliseconds: 45);
}
