import 'dart:ui';

import 'package:flutter/material.dart';

import 'colors.dart';
import 'spacing.dart';

/// How prominent a glass surface should read: [card] for content surfaces
/// (album/track cards, panels, the sidebar), [pill] for the floating nav bar
/// and player bar, which sit above everything else and need a heavier, more
/// opaque treatment.
enum GlassIntensity { card, pill }

/// A liquid-glass surface: three stacked layers — a blurred, saturated
/// backdrop, a translucent fill graded top-to-bottom, and a 1px specular
/// highlight along the top edge.
///
/// Wraps [BackdropFilter] with a composed blur + saturation [ImageFilter] so
/// content behind the surface reads as frosted glass rather than a flat
/// tint. The fill/border/shadow values come straight from the design doc's
/// glass spec, split per brightness and per [GlassIntensity].
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
    this.highlight = true,
  });

  final Widget child;
  final GlassIntensity intensity;

  /// Overrides the ambient theme brightness. Leave null to follow
  /// `Theme.of(context).brightness`.
  final Brightness? brightness;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;

  /// Draws the 1px specular line along the top edge. Off for surfaces whose
  /// top edge is clipped away (e.g. a panel flush against the window chrome).
  final bool highlight;

  static const double _cardBlurSigma = 24;
  static const double _pillBlurSigma = 28;

  @override
  Widget build(BuildContext context) {
    final effectiveBrightness = brightness ?? Theme.of(context).brightness;
    final isDark = effectiveBrightness == Brightness.dark;
    final isPill = intensity == GlassIntensity.pill;

    final blurSigma = isPill ? _pillBlurSigma : _cardBlurSigma;
    final saturation = isDark ? (isPill ? 1.7 : 1.6) : (isPill ? 1.9 : 1.8);

    // docs/design-system.md §2.1. Light: L1 .66 -> .40, L2 .74 -> .48.
    // Dark: L1 .06 -> .04, L2 .10 -> .06, on a near-black base, so it reads
    // as a flat white wash rather than a gradient.
    final Color fillTop;
    final Color fillBottom;
    final Color borderColor;
    if (isDark) {
      fillTop = Colors.white.withValues(alpha: isPill ? 0.10 : 0.06);
      fillBottom = Colors.white.withValues(alpha: isPill ? 0.06 : 0.04);
      borderColor = Colors.white.withValues(alpha: isPill ? 0.16 : 0.12);
    } else {
      fillTop = Colors.white.withValues(alpha: isPill ? 0.74 : 0.66);
      fillBottom = Colors.white.withValues(alpha: isPill ? 0.48 : 0.40);
      borderColor = Colors.white.withValues(alpha: isPill ? 0.90 : 0.85);
    }

    // `0 12px 32px -18px` / `0 16px 40px -18px` from the design's glass spec:
    // a deep, tight-spread drop that lifts the pane off the tinted backdrop.
    final shadow = BoxShadow(
      color: Colors.black.withValues(
        alpha: isDark ? (isPill ? 0.70 : 0.45) : (isPill ? 0.35 : 0.30),
      ),
      blurRadius: isPill ? 40 : 32,
      spreadRadius: -18,
      offset: Offset(0, isPill ? 16 : 12),
    );

    // "Reduce transparency": the platform's high-contrast setting is the
    // closest signal Flutter exposes. Glass becomes an opaque container with
    // a hairline, no blur: legible over any artwork and cheaper to paint.
    if (MediaQuery.highContrastOf(context)) {
      final scheme = Theme.of(context).colorScheme;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: borderRadius,
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [shadow],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      );
    }

    // Floating chrome in the dark gets a light edge instead of a flat
    // border: white 14 % at the top fading to nothing — thickness without a
    // heavy shadow.
    final lightEdge = isDark && isPill;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [shadow],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.compose(
            outer: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            inner: ColorFilter.matrix(_saturationMatrix(saturation)),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [fillTop, fillBottom],
              ),
              border: lightEdge
                  ? null
                  : Border.all(color: borderColor, width: 1),
            ),
            child: Stack(
              children: [
                // A Material of its own, so hover, press and focus ink from
                // controls inside the glass paints on top of the frosted fill.
                // Without it the ink drew on the nearest Material further up
                // — under the blur — and was all but invisible.
                Material(
                  type: MaterialType.transparency,
                  child: Padding(
                    padding: padding ?? EdgeInsets.zero,
                    child: child,
                  ),
                ),
                if (lightEdge)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _LightEdgePainter(borderRadius),
                      ),
                    ),
                  ),
                if (highlight && !lightEdge)
                  Positioned(
                    left: borderRadius.topLeft.x,
                    right: borderRadius.topRight.x,
                    top: 0,
                    height: 1,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: isDark ? 0.16 : 0.55,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
      lumR + (1 - lumR) * s,
      lumG - lumG * s,
      lumB - lumB * s,
      0,
      0,
      lumR - lumR * s,
      lumG + (1 - lumG) * s,
      lumB - lumB * s,
      0,
      0,
      lumR - lumR * s,
      lumG - lumG * s,
      lumB + (1 - lumB) * s,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }
}

/// A tappable [GlassSurface]: the glass pane is the button.
///
/// The ink sits inside the pane, over the frosted fill, with the padding
/// inside the ink so the whole pane is the hit target. Wrapping a
/// [GlassSurface] in an `InkWell` instead draws the ink underneath the blur.
class GlassInkButton extends StatelessWidget {
  const GlassInkButton({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(OmnisonicRadius.full),
    ),
    this.padding = const EdgeInsets.symmetric(
      horizontal: OmnisonicSpacing.md,
      vertical: OmnisonicSpacing.sm + OmnisonicSpacing.xxs,
    ),
    this.intensity = GlassIntensity.card,
    this.tooltip,
    this.semanticLabel,
    this.selected,
    this.focusNode,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final GlassIntensity intensity;
  final String? tooltip;
  final String? semanticLabel;
  final bool? selected;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget button = GlassSurface(
      borderRadius: borderRadius,
      intensity: intensity,
      child: InkWell(
        onTap: onTap,
        focusNode: focusNode,
        borderRadius: borderRadius,
        hoverColor: scheme.onSurface.withValues(alpha: 0.06),
        focusColor: scheme.primary.withValues(alpha: 0.18),
        highlightColor: scheme.onSurface.withValues(alpha: 0.08),
        child: Padding(padding: padding, child: child),
      ),
    );
    if (semanticLabel != null || selected != null) {
      button = Semantics(
        button: true,
        selected: selected,
        label: semanticLabel,
        child: button,
      );
    }
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    return button;
  }
}

/// Preset [GlassSurface] for the floating nav bar / player bar: heavier
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

/// The third glass layer: a still diagonal reflection across a pane
/// (docs/design-system.md §6).
///
/// Dark theme only, at 4 % white: on Pearl glass a white sheen has nothing to
/// lift and reads as a smear. It does not move — the motion rules allow no
/// decorative loops besides the live equalizer and the Aurora drift, and a
/// sweep crossing the player bar every few seconds was exactly that.
///
/// Purely decorative and [IgnorePointer]-wrapped, so it can be stacked over
/// any glass surface without stealing taps. Stack it *inside* the surface's
/// clip.
class GlassSheen extends StatelessWidget {
  const GlassSheen({super.key});

  /// Peak white alpha of the reflection, dark theme.
  static const double peakAlpha = 0.04;

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness != Brightness.dark) {
      return const SizedBox.shrink();
    }
    final peak = OmnisonicColors.neutralWhite.withValues(alpha: peakAlpha);
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.transparent, peak, Colors.transparent],
            stops: const [0.25, 0.45, 0.65],
          ),
        ),
      ),
    );
  }
}

/// A 1 px outline fading from white 14 % at the top edge to transparent at
/// the bottom: the "light edge" of floating dark chrome.
class _LightEdgePainter extends CustomPainter {
  const _LightEdgePainter(this.radius);

  final BorderRadius radius;

  static const Color _top = Color(0x24FFFFFF); // white 14 %
  static const Color _bottom = Color(0x00FFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      radius.toRRect(rect).deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_top, _bottom],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_LightEdgePainter old) => old.radius != radius;
}
