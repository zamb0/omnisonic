import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';

/// Proportional digits make a ticking timer change width every second.
void main() {
  test('timer styles use tabular figures', () {
    for (final style in [
      OmnisonicTypography.duration,
      OmnisonicTypography.technical,
      OmnisonicTypography.metadata,
    ]) {
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    }
  });
}
