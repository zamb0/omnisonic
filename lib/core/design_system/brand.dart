import 'package:flutter/material.dart';

import 'colors.dart';
import 'spacing.dart';

/// The Aurora Glass signature: gradient, mesh, and the colours that go with
/// them. Read with `OmnisonicBrand.of(context)`.
///
/// Aurora is for the one main Play per screen, the playing track's progress,
/// the brand mark and the fallback background when there is no artwork.
/// Text and icons on it are always [onAurora], in both themes.
@immutable
class OmnisonicBrand extends ThemeExtension<OmnisonicBrand> {
  const OmnisonicBrand({
    required this.aurora,
    required this.auroraSoft,
    required this.auroraMesh,
    required this.onAurora,
    required this.heat,
    required this.glow,
  });

  /// violet → magenta → coral, 135°.
  final LinearGradient aurora;

  /// [aurora] at 18 % alpha: halos, focus glow, "now playing" chips.
  final LinearGradient auroraSoft;

  /// Three soft radial blobs for backgrounds without artwork.
  final List<RadialGradient> auroraMesh;

  /// Foreground on [aurora].
  final Color onAurora;

  /// Favourites / love. Never decorative.
  final Color heat;

  /// Shadow under an Aurora fill.
  final List<BoxShadow> glow;

  static const _stops = [0.0, 0.55, 1.0];
  static const _colors = [
    OmnisonicColors.auroraViolet,
    OmnisonicColors.auroraMagenta,
    OmnisonicColors.auroraCoral,
  ];

  static LinearGradient _aurora([double alpha = 1]) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [for (final c in _colors) c.withValues(alpha: alpha)],
    stops: _stops,
  );

  static List<RadialGradient> _mesh(double alpha) {
    RadialGradient blob(Color c, Alignment center, double radius) =>
        RadialGradient(
          center: center,
          radius: radius,
          colors: [
            c.withValues(alpha: alpha),
            c.withValues(alpha: 0),
          ],
        );
    return [
      blob(const Color(0xFF6A3DF0), const Alignment(-0.6, -0.8), 0.9),
      blob(const Color(0xFFC04BE8), const Alignment(0.8, -0.4), 0.8),
      blob(const Color(0xFFF0644A), const Alignment(0.0, 1.2), 0.9),
    ];
  }

  static final OmnisonicBrand dark = OmnisonicBrand(
    aurora: _aurora(),
    auroraSoft: _aurora(0.18),
    auroraMesh: _mesh(0.35),
    onAurora: OmnisonicColors.onAurora,
    heat: OmnisonicColors.heatDark,
    glow: OmnisonicShadows.glow(Brightness.dark),
  );

  static final OmnisonicBrand light = OmnisonicBrand(
    aurora: _aurora(),
    auroraSoft: _aurora(0.18),
    auroraMesh: _mesh(0.22),
    onAurora: OmnisonicColors.onAurora,
    heat: OmnisonicColors.heatLight,
    glow: OmnisonicShadows.glow(Brightness.light),
  );

  static OmnisonicBrand of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<OmnisonicBrand>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  OmnisonicBrand copyWith({
    LinearGradient? aurora,
    LinearGradient? auroraSoft,
    List<RadialGradient>? auroraMesh,
    Color? onAurora,
    Color? heat,
    List<BoxShadow>? glow,
  }) => OmnisonicBrand(
    aurora: aurora ?? this.aurora,
    auroraSoft: auroraSoft ?? this.auroraSoft,
    auroraMesh: auroraMesh ?? this.auroraMesh,
    onAurora: onAurora ?? this.onAurora,
    heat: heat ?? this.heat,
    glow: glow ?? this.glow,
  );

  @override
  OmnisonicBrand lerp(ThemeExtension<OmnisonicBrand>? other, double t) {
    if (other is! OmnisonicBrand) return this;
    return t < 0.5 ? this : other;
  }
}
