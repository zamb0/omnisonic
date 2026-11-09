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
  const ArtTintBackground({
    super.key,
    this.seed,
    this.child,
    this.fallbackOpacity,
  });

  /// Dominant colour of the art currently on screen. Null falls back to the
  /// Aurora mesh.
  final Color? seed;

  final Widget? child;

  /// How much of the Aurora fallback shows, from 0 (only the cover washes)
  /// to 1 (only the mesh). Null derives it from [seed]. Set in between by a
  /// cross-fade, so arriving at or leaving the fallback is a fade too.
  final double? fallbackOpacity;

  static const _meshKey = ValueKey('art-tint-mesh');
  static const _contentKey = ValueKey('art-tint-content');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    // No cover to follow: the Aurora mesh, drifting slowly (still with reduce
    // motion). Settings, servers, offline and every empty state sit on it,
    // so no screen is a flat canvas when there is no artwork.
    final cover = seed;
    final meshOpacity = (fallbackOpacity ?? (cover == null ? 1.0 : 0.0)).clamp(
      0.0,
      1.0,
    );
    final coverOpacity = cover == null ? 0.0 : 1 - meshOpacity;
    final washes = <Widget>[
      if (cover != null && coverOpacity > 0)
        ..._coverWashes(cover, isDark: isDark, opacity: coverOpacity),
      // Keyed so its drift carries on through a cross-fade rather than
      // restarting whenever the washes before it come or go.
      if (meshOpacity > 0)
        AuroraMesh(key: _meshKey, drift: true, opacity: meshOpacity),
    ];

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
        // On its own layer, and keyed so it is never remounted when the
        // washes change. The background repaints on every frame of a tint
        // cross-fade; without the boundary every page and pane in the window
        // was repainted with it.
        if (child case final content?)
          RepaintBoundary(key: _contentKey, child: content),
      ],
    );
  }

  /// The two radial washes of a cover colour: the colour itself and its
  /// hue rotated 78°.
  static List<Widget> _coverWashes(
    Color cover, {
    required bool isDark,
    double opacity = 1,
  }) {
    final primaryTint = _normalize(cover, isDark: isDark);
    final secondaryTint = _normalize(_rotateHue(cover, 78), isDark: isDark);
    return [
      IgnorePointer(
        key: const ValueKey('art-tint-wash-1'),
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
                primaryTint.withValues(alpha: (isDark ? 0.85 : 0.62) * opacity),
                primaryTint.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
      IgnorePointer(
        key: const ValueKey('art-tint-wash-2'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: isDark
                  ? const Alignment(0.4, -1.1)
                  : const Alignment(-0.76, 0.76),
              radius: isDark ? 0.95 : 0.85,
              colors: [
                secondaryTint.withValues(alpha: (isDark ? 0.6 : 0.5) * opacity),
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
