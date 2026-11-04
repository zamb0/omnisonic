import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';

double _lum(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Composites [fg] (with alpha) over opaque [bg].
Color over(Color fg, Color bg) => Color.alphaBlend(fg, bg);

/// Every pair declared in docs/design-system.md §2, both themes.
void main() {
  for (final entry in {
    Brightness.dark: OmnisonicColors.darkColorScheme,
    Brightness.light: OmnisonicColors.lightColorScheme,
  }.entries) {
    final b = entry.key;
    final s = entry.value;
    final brand = b == Brightness.dark
        ? OmnisonicBrand.dark
        : OmnisonicBrand.light;
    final surfaces = b == Brightness.dark
        ? OmnisonicSurfaces.dark
        : OmnisonicSurfaces.light;

    group('${b.name} text >= 4.5:1', () {
      final canvas = s.surface;
      final pairs = <String, (Color, Color)>{
        'onSurface/surface': (s.onSurface, canvas),
        'onSurfaceVariant/surface': (s.onSurfaceVariant, canvas),
        'onSurfaceVariant/surfaceContainer': (
          s.onSurfaceVariant,
          s.surfaceContainer,
        ),
        'onSurface/surfaceContainerHigh': (s.onSurface, s.surfaceContainerHigh),
        'primary/surface': (s.primary, canvas),
        'onPrimary/primary': (s.onPrimary, s.primary),
        'onPrimaryContainer/primaryContainer': (
          s.onPrimaryContainer,
          s.primaryContainer,
        ),
        'primary/primaryContainer': (s.primary, s.primaryContainer),
        'secondary/surface': (s.secondary, canvas),
        'onSecondary/secondary': (s.onSecondary, s.secondary),
        'onSecondaryContainer/secondaryContainer': (
          s.onSecondaryContainer,
          s.secondaryContainer,
        ),
        'tertiary/surface': (s.tertiary, canvas),
        'onTertiary/tertiary': (s.onTertiary, s.tertiary),
        'onTertiaryContainer/tertiaryContainer': (
          s.onTertiaryContainer,
          s.tertiaryContainer,
        ),
        'error/surface': (s.error, canvas),
        'onError/error': (s.onError, s.error),
        'onErrorContainer/errorContainer': (
          s.onErrorContainer,
          s.errorContainer,
        ),
        'heat/surface': (brand.heat, canvas),
        'onInverseSurface/inverseSurface': (
          s.onInverseSurface,
          s.inverseSurface,
        ),
        'success/surface': (
          b == Brightness.dark
              ? OmnisonicColors.success
              : OmnisonicColors.successAccessible,
          canvas,
        ),
        'warning/surface': (
          b == Brightness.dark
              ? OmnisonicColors.warning
              : OmnisonicColors.warningAccessible,
          canvas,
        ),
        'onAurora/violet': (
          OmnisonicColors.onAurora,
          OmnisonicColors.auroraViolet,
        ),
        'onAurora/magenta': (
          OmnisonicColors.onAurora,
          OmnisonicColors.auroraMagenta,
        ),
        'onAurora/coral': (
          OmnisonicColors.onAurora,
          OmnisonicColors.auroraCoral,
        ),
        'onSurface/well': (s.onSurface, over(surfaces.well, canvas)),
        'onSurface/wellHover': (s.onSurface, over(surfaces.wellHover, canvas)),
      };
      pairs.forEach((name, p) {
        test(
          name,
          () => expect(contrast(p.$1, p.$2), greaterThanOrEqualTo(4.5)),
        );
      });
    });

    group('${b.name} borders and dots >= 3:1', () {
      test('outline on surface', () {
        expect(contrast(s.outline, s.surface), greaterThanOrEqualTo(3.0));
      });
      for (var i = 0; i < OmnisonicColors.serverHueSwatches.length; i++) {
        test('server dot $i', () {
          expect(
            contrast(
              OmnisonicColors.serverColorFor('x', index: i, brightness: b),
              s.surface,
            ),
            greaterThanOrEqualTo(3.0),
          );
        });
      }
    });
  }

  test('white on Aurora would fail (documents why onAurora is dark)', () {
    expect(contrast(Colors.white, OmnisonicColors.auroraCoral), lessThan(3.3));
  });
}
