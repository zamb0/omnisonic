import 'dart:ui';

import 'package:flutter/material.dart';

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

    // Design spec, light: card fill .66 -> .38, pill fill .72 -> .46 with a
    // .85/.90 border. Dark glass sits on a near-black base so it reads as a
    // flat white wash instead of a gradient.
    final Color fillTop;
    final Color fillBottom;
    final Color borderColor;
    if (isDark) {
      fillTop = Colors.white.withValues(alpha: isPill ? 0.09 : 0.06);
      fillBottom = Colors.white.withValues(alpha: isPill ? 0.06 : 0.04);
      borderColor = Colors.white.withValues(alpha: isPill ? 0.16 : 0.12);
    } else {
      fillTop = Colors.white.withValues(alpha: isPill ? 0.72 : 0.66);
      fillBottom = Colors.white.withValues(alpha: isPill ? 0.46 : 0.38);
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
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Stack(
              children: [
                Padding(padding: padding ?? EdgeInsets.zero, child: child),
                if (highlight)
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

/// The third glass layer: a slow specular sweep travelling across a pane.
///
/// Purely decorative and always [IgnorePointer]-wrapped, so it can be
/// stacked over any glass surface without stealing taps. Stack it *inside*
/// the surface's clip — it draws a full-height band and relies on the parent
/// to crop it.
class GlassSheen extends StatefulWidget {
  const GlassSheen({
    super.key,
    this.period = const Duration(seconds: 6),
    this.bandWidthFactor = 0.18,
    this.opacity = 0.5,
  });

  /// One full left-to-right pass.
  final Duration period;

  /// Band width as a fraction of the pane width.
  final double bandWidthFactor;

  /// Peak white alpha at the centre of the band.
  final double opacity;

  @override
  State<GlassSheen> createState() => _GlassSheenState();
}

class _GlassSheenState extends State<GlassSheen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: widget.period,
    vsync: this,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honours "reduce motion": a continuously repeating sweep is exactly the
    // kind of ambient animation that setting exists to suppress.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final peak = Colors.white.withValues(
      alpha: isDark ? widget.opacity * 0.24 : widget.opacity,
    );

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          if (!width.isFinite || width <= 0) return const SizedBox.shrink();
          final bandWidth = width * widget.bandWidthFactor;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final dx = -bandWidth + _controller.value * (width + bandWidth);
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: bandWidth,
                height: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.transparent, peak, Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
