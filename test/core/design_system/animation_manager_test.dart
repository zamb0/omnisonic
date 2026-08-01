import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/animation_manager.dart';

void main() {
  group('AnimationManager', () {
    test('should provide standardized durations', () {
      expect(
        AnimationManager.fastDuration,
        equals(const Duration(milliseconds: 150)),
      );
      expect(
        AnimationManager.normalDuration,
        equals(const Duration(milliseconds: 300)),
      );
      expect(
        AnimationManager.slowDuration,
        equals(const Duration(milliseconds: 500)),
      );
    });

    test('should provide standardized curves', () {
      expect(AnimationManager.standardCurve, equals(Curves.easeInOutCubic));
      expect(AnimationManager.fastCurve, equals(Curves.easeOutQuart));
      expect(AnimationManager.slowCurve, equals(Curves.easeInOutQuint));
    });
  });
}
