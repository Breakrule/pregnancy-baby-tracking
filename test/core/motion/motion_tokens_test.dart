import 'package:flutter_test/flutter_test.dart';
import 'package:nurture/core/motion/motion_tokens.dart';

void main() {
  test('durations are short and ordered', () {
    expect(MotionTokens.fast.inMilliseconds, lessThan(200));
    expect(MotionTokens.normal.inMilliseconds, lessThan(400));
    expect(MotionTokens.slow.inMilliseconds, lessThan(500));
    expect(MotionTokens.fast < MotionTokens.normal, isTrue);
    expect(MotionTokens.normal < MotionTokens.slow, isTrue);
  });

  test('stagger step is small enough to feel simultaneous, not sequential', () {
    expect(MotionTokens.staggerStep.inMilliseconds, lessThanOrEqualTo(60));
  });
}
