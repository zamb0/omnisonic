import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/animation_manager.dart';

void main() {
  group('AnimationManager', () {
    test('provides the full duration ladder', () {
      expect(
        AnimationManager.fastDuration,
        equals(const Duration(milliseconds: 150)),
      );
      expect(
        AnimationManager.quickDuration,
        equals(const Duration(milliseconds: 200)),
      );
      expect(
        AnimationManager.normalDuration,
        equals(const Duration(milliseconds: 300)),
      );
      expect(
        AnimationManager.emphasisDuration,
        equals(const Duration(milliseconds: 450)),
      );
      expect(
        AnimationManager.tintDuration,
        equals(const Duration(milliseconds: 600)),
      );
      expect(
        AnimationManager.loadingDuration,
        equals(const Duration(milliseconds: 1500)),
      );
    });

    test('provides a curve per motion role', () {
      expect(AnimationManager.standardCurve, equals(Curves.easeInOutCubic));
      expect(AnimationManager.fastCurve, equals(Curves.easeOutQuart));
      expect(AnimationManager.slowCurve, equals(Curves.easeInOutQuint));
      expect(AnimationManager.dialogCurve, equals(Curves.easeOutCubic));
      expect(AnimationManager.sheetCurve, equals(Curves.easeOutQuart));
      expect(AnimationManager.loadingCurve, equals(Curves.easeInOut));
    });

    // The ladder only works as a ladder if it stays ordered — a "fast"
    // duration longer than "normal" would be a silent authoring mistake.
    test('durations increase monotonically', () {
      const ladder = [
        AnimationManager.instantDuration,
        AnimationManager.fastDuration,
        AnimationManager.quickDuration,
        AnimationManager.normalDuration,
        AnimationManager.emphasisDuration,
        AnimationManager.tintDuration,
        AnimationManager.loadingDuration,
      ];

      for (var i = 1; i < ladder.length; i++) {
        expect(
          ladder[i],
          greaterThan(ladder[i - 1]),
          reason: 'rung $i is not longer than the one before it',
        );
      }
    });

    // Micro-interactions should land in the 150-300ms band that both
    // Material and the HIG call for; anything slower reads as sluggish.
    test('interaction durations stay under 300ms', () {
      expect(
        AnimationManager.fastDuration.inMilliseconds,
        lessThanOrEqualTo(300),
      );
      expect(
        AnimationManager.quickDuration.inMilliseconds,
        lessThanOrEqualTo(300),
      );
      expect(
        AnimationManager.normalDuration.inMilliseconds,
        lessThanOrEqualTo(300),
      );
    });
  });
}
