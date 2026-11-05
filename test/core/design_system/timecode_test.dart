import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';

void main() {
  test('timecode is 12/500 mono with tabular figures', () {
    final style = OmnisonicTypography.timecode;
    expect(style.fontSize, 12);
    expect(style.fontWeight, FontWeight.w500);
    expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
  });

  test('track durations use the same voice', () {
    expect(
      OmnisonicTypography.duration.fontSize,
      OmnisonicTypography.timecode.fontSize,
    );
    expect(
      OmnisonicTypography.duration.fontFeatures,
      OmnisonicTypography.timecode.fontFeatures,
    );
  });
}
