import 'package:flutter/material.dart';

/// The bottom layer of the liquid-glass stack: two large, soft radial washes
/// tinted from the current cover art, sitting behind every glass pane in the
/// window.
///
/// Without this the sidebar and player bar blur an essentially flat surface
/// and read as plain translucent panels; the wash is what gives the glass
/// something to refract. Purely decorative — never intercepts pointers.
class ArtTintBackground extends StatelessWidget {
  const ArtTintBackground({super.key, this.seed, this.child});

  /// Dominant colour of the art currently on screen. Null falls back to the
  /// design's neutral warm/violet pair.
  final Color? seed;

  final Widget? child;

  /// Design fallbacks — `oklch(.86 .1 55)` and `oklch(.85 .08 300)`
  /// converted to sRGB.
  static const Color _fallbackWarmLight = Color(0xFFF7C9A2);
  static const Color _fallbackCoolLight = Color(0xFFE2C6EE);

  /// Design fallbacks for the dark canvas — `oklch(.55 .16 285)` and
  /// `oklch(.5 .14 20)`.
  static const Color _fallbackWarmDark = Color(0xFF5B4BB8);
  static const Color _fallbackCoolDark = Color(0xFF8E4442);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    final primaryTint = seed == null
        ? (isDark ? _fallbackWarmDark : _fallbackWarmLight)
        : _normalize(seed!, isDark: isDark);
    final secondaryTint = seed == null
        ? (isDark ? _fallbackCoolDark : _fallbackCoolLight)
        : _normalize(_rotateHue(seed!, 78), isDark: isDark);

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: scheme.surface),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                // 78% / 8% in light, pulled to the top band in dark where the
                // design anchors both washes above the fold.
                center: isDark
                    ? const Alignment(-0.56, -1.1)
                    : const Alignment(0.56, -0.84),
                radius: isDark ? 1.1 : 0.95,
                colors: [
                  primaryTint.withValues(alpha: isDark ? 0.85 : 0.62),
                  primaryTint.withValues(alpha: 0),
                ],
                stops: const [0, 1],
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: isDark
                    ? const Alignment(0.4, -1.1)
                    : const Alignment(-0.76, 0.76),
                radius: isDark ? 0.95 : 0.85,
                colors: [
                  secondaryTint.withValues(alpha: isDark ? 0.6 : 0.5),
                  secondaryTint.withValues(alpha: 0),
                ],
                stops: const [0, 1],
              ),
            ),
          ),
        ),
        // Dark mode grades the washes back down to the base so content lower
        // on the page keeps full contrast, mirroring the design's
        // `linear-gradient(180deg, .25 -> .9 -> solid)` scrim.
        if (isDark)
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.surface.withValues(alpha: 0.25),
                    scheme.surface.withValues(alpha: 0.9),
                    scheme.surface,
                  ],
                  stops: const [0, 0.55, 1],
                ),
              ),
            ),
          ),
        ?child,
      ],
    );
  }

  /// Pulls an arbitrary cover-art colour into the design's tint envelope:
  /// pale and lightly saturated on the light canvas, deep and richer on the
  /// dark one. Raw dominant colours are far too vivid to sit under glass.
  static Color _normalize(Color color, {required bool isDark}) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation(
          hsl.saturation.clamp(isDark ? 0.35 : 0.25, isDark ? 0.62 : 0.5),
        )
        .withLightness(isDark ? 0.42 : 0.76)
        .toColor();
  }

  static Color _rotateHue(Color color, double degrees) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withHue((hsl.hue + degrees) % 360).toColor();
  }
}
