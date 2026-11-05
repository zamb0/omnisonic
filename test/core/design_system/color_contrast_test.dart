import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/colors.dart';

/// WCAG 2.1 relative luminance.
double _relativeLuminance(Color color) {
  double channel(int value) {
    final v = value / 255.0;
    return v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4) as double;
  }

  return 0.2126 * channel((color.r * 255).round()) +
      0.7152 * channel((color.g * 255).round()) +
      0.0722 * channel((color.b * 255).round());
}

/// WCAG 2.1 contrast ratio between two opaque colors.
double contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('light color scheme meets WCAG AA', () {
    const scheme = OmnisonicColors.lightColorScheme;

    // 4.5:1 is the AA threshold for normal-size text.
    const textThreshold = 4.5;

    final textPairs = <String, List<Color>>{
      'onPrimary on primary': [scheme.onPrimary, scheme.primary],
      'onSecondary on secondary': [scheme.onSecondary, scheme.secondary],
      'onTertiary on tertiary': [scheme.onTertiary, scheme.tertiary],
      'onError on error': [scheme.onError, scheme.error],
      'onSurface on surface': [scheme.onSurface, scheme.surface],
      'onSurfaceVariant on surface': [scheme.onSurfaceVariant, scheme.surface],
      'primary on surface': [scheme.primary, scheme.surface],
      'onPrimaryContainer on primaryContainer': [
        scheme.onPrimaryContainer,
        scheme.primaryContainer,
      ],
      'onSecondaryContainer on secondaryContainer': [
        scheme.onSecondaryContainer,
        scheme.secondaryContainer,
      ],
      'onErrorContainer on errorContainer': [
        scheme.onErrorContainer,
        scheme.errorContainer,
      ],
      'white on success': [
        OmnisonicColors.neutralWhite,
        OmnisonicColors.successAccessible,
      ],
      'white on warning': [
        OmnisonicColors.neutralWhite,
        OmnisonicColors.warningAccessible,
      ],
      'white on info': [
        OmnisonicColors.neutralWhite,
        OmnisonicColors.infoAccessible,
      ],
    };

    textPairs.forEach((name, pair) {
      test('$name reaches $textThreshold:1', () {
        expect(
          contrastRatio(pair[0], pair[1]),
          greaterThanOrEqualTo(textThreshold),
          reason: '$name is below the AA text threshold',
        );
      });
    });
  });

  group('dark color scheme stays compliant', () {
    const scheme = OmnisonicColors.darkColorScheme;

    test('onSurface on surface reaches 4.5:1', () {
      expect(
        contrastRatio(scheme.onSurface, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('onPrimary on primary reaches 4.5:1', () {
      expect(
        contrastRatio(scheme.onPrimary, scheme.primary),
        greaterThanOrEqualTo(4.5),
      );
    });

    // The favourite heart is a non-text indicator, so 3:1 applies, but the
    // token clears the text threshold on the dark surface too.
    test('favourite indicator on dark surface reaches 4.5:1', () {
      expect(
        contrastRatio(OmnisonicColors.heatDark, OmnisonicColors.surfaceDark),
        greaterThanOrEqualTo(4.5),
      );
    });
  });
}
