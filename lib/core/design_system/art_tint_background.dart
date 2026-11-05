import 'package:flutter/material.dart';

import 'aurora_mesh.dart';

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
  /// Aurora mesh.
  final Color? seed;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    // No cover to follow: the Aurora mesh, drifting slowly (still with reduce
    // motion). Settings, servers, offline and every empty state sit on it,
    // so no screen is a flat canvas when there is no artwork.
    final cover = seed;
    final washes = cover == null
        ? const <Widget>[AuroraMesh(drift: true)]
        : <Widget>[..._coverWashes(cover, isDark: isDark)];

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: scheme.surface),
        ...washes,
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

  /// The two radial washes of a cover colour: the colour itself and its
  /// hue rotated 78°.
  static List<Widget> _coverWashes(Color cover, {required bool isDark}) {
    final primaryTint = _normalize(cover, isDark: isDark);
    final secondaryTint = _normalize(_rotateHue(cover, 78), isDark: isDark);
    return [
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
            ),
          ),
        ),
      ),
    ];
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
