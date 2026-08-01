import 'dart:ui';

import 'package:flutter/material.dart';

import 'colors.dart';
import 'spacing.dart';

/// How prominent a glass surface should read: [card] for content surfaces
/// (album/track cards, panels), [pill] for the floating nav bar and mini
/// player, which sit above everything else and need a heavier, more opaque
/// treatment.
enum GlassIntensity { card, pill }

/// A liquid-glass surface: a blurred, saturated backdrop behind a
/// translucent white gradient fill, border and drop shadow.
///
/// Wraps [BackdropFilter] with a composed blur + saturation [ImageFilter] so
/// content behind the surface reads as frosted glass rather than a flat
/// tint. Alpha values come from [OmnisonicColors.glassAlphasLight] /
/// [OmnisonicColors.glassAlphasDark] so every glass surface in the app stays
/// on the same alpha scale.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.intensity = GlassIntensity.card,
    this.brightness,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(OmnisonicRadius.card),
    ),
    this.padding,
  });

  final Widget child;
  final GlassIntensity intensity;

  /// Overrides the ambient theme brightness. Leave null to follow
  /// `Theme.of(context).brightness`.
  final Brightness? brightness;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;

  static const double _cardBlurSigma = 22;
  static const double _pillBlurSigma = 26;
  static const double _lightSaturation = 1.8;
  static const double _darkSaturation = 1.75;

  @override
  Widget build(BuildContext context) {
    final effectiveBrightness =
        brightness ?? Theme.of(context).brightness;
    final isDark = effectiveBrightness == Brightness.dark;
    final isPill = intensity == GlassIntensity.pill;

    final blurSigma = isPill ? _pillBlurSigma : _cardBlurSigma;
    final saturation = isDark ? _darkSaturation : _lightSaturation;

    final Color fillTop;
    final Color fillBottom;
    final Color borderColor;
    if (isDark) {
      fillTop = OmnisonicColors.glassDark(isPill ? 3 : 2);
      fillBottom = OmnisonicColors.glassDark(isPill ? 1 : 0);
      borderColor = OmnisonicColors.glassDark(isPill ? 3 : 2);
    } else {
      fillTop = OmnisonicColors.glassLight(isPill ? 3 : 2);
      fillBottom = OmnisonicColors.glassLight(isPill ? 1 : 0);
      borderColor = OmnisonicColors.glassLight(isPill ? 3 : 2);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.compose(
          outer: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          inner: ColorFilter.matrix(_saturationMatrix(saturation)),
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [fillTop, fillBottom],
            ),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  /// Luminance-preserving saturation matrix (`s` = 1 leaves colors
  /// unchanged; `s` > 1 boosts saturation), in the row-major 4x5 layout
  /// `ColorFilter.matrix` expects.
  static List<double> _saturationMatrix(double s) {
    const lumR = 0.213;
    const lumG = 0.715;
    const lumB = 0.072;
    return <double>[
      lumR + (1 - lumR) * s, lumG - lumG * s, lumB - lumB * s, 0, 0,
      lumR - lumR * s, lumG + (1 - lumG) * s, lumB - lumB * s, 0, 0,
      lumR - lumR * s, lumG - lumG * s, lumB + (1 - lumB) * s, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
}

/// Preset [GlassSurface] for the floating nav bar / mini player: heavier
/// blur, fully rounded pill shape.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.brightness,
    this.padding,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(OmnisonicRadius.full),
    ),
  });

  final Widget child;
  final Brightness? brightness;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      intensity: GlassIntensity.pill,
      brightness: brightness,
      borderRadius: borderRadius,
      padding: padding,
      child: child,
    );
  }
}
