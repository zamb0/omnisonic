import 'package:flutter/material.dart';

import '../utils/animation_utils.dart';
import 'animation_manager.dart';
import 'brand.dart';
import 'colors.dart';
import 'icons.dart';
import 'motion.dart';
import 'spacing.dart';
import 'typography.dart';

/// Heights of an [AuroraButton] and [OmnisonicButton] (docs/design-system.md §9.1). `sm` is for
/// pointer-only desktop layouts; touch layouts use [md] or [lg].
enum OmnisonicButtonSize {
  sm(36),
  md(44),
  lg(52);

  const OmnisonicButtonSize(this.height);
  final double height;
}

/// Diameters of a [PlayDisc].
enum PlayDiscSize {
  s44(44),
  s48(48),
  s56(56),
  s64(64);

  const PlayDiscSize(this.diameter);
  final double diameter;

  /// Glyph size: `md` up to 48, `lg` above.
  double get iconSize =>
      diameter > 48 ? OmnisonicIconSizes.lg : OmnisonicIconSizes.md;
}

/// The signature action: the one main Play/Shuffle of a screen.
///
/// Aurora fill, [OmnisonicBrand.onAurora] content, glow underneath.
/// **At most one per screen** — it is what makes it the signature. Everything
/// else is a `FilledButton` (ink) or tonal.
///
/// Loading keeps the width: the spinner takes the icon's place, or, without
/// an icon, is drawn over the label, which stays laid out but invisible.
/// While loading the button ignores taps and announces itself as a live
/// region.
class AuroraButton extends StatelessWidget {
  const AuroraButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.size = OmnisonicButtonSize.md,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final OmnisonicButtonSize size;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final brand = OmnisonicBrand.of(context);
    final content = ButtonContent(
      label: label,
      icon: icon,
      loading: loading,
      size: size,
      color: brand.onAurora,
    );

    return Semantics(
      button: true,
      enabled: _enabled || loading,
      liveRegion: loading,
      label: loading ? '$label, loading' : label,
      excludeSemantics: true,
      child: _AuroraInk(
        enabled: _enabled,
        onTap: _enabled ? onPressed : null,
        circle: false,
        constraints: BoxConstraints(
          minHeight: size.height,
          maxHeight: size.height,
          minWidth: 64,
        ),
        padding: const EdgeInsets.symmetric(horizontal: OmnisonicSpacing.ml),
        child: content,
      ),
    );
  }
}

/// The round Aurora Play: cards, detail headers, mini player, transport and
/// Now Playing. The glyph swaps play ↔ pause in `quick`.
class PlayDisc extends StatelessWidget {
  const PlayDisc({
    super.key,
    required this.onPressed,
    this.playing = false,
    this.size = PlayDiscSize.s48,
    this.tooltip,
  });

  final VoidCallback? onPressed;

  /// Shows pause instead of play.
  final bool playing;
  final PlayDiscSize size;

  /// Defaults to "Play" / "Pause".
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final brand = OmnisonicBrand.of(context);
    final label = tooltip ?? (playing ? 'Pause' : 'Play');
    final glyph = playing ? OmnisonicIcons.pause : OmnisonicIcons.playArrow;

    final disc = _AuroraInk(
      enabled: onPressed != null,
      onTap: onPressed,
      circle: true,
      constraints: BoxConstraints.tightFor(
        width: size.diameter,
        height: size.diameter,
      ),
      child: AnimatedSwitcher(
        duration: AnimationUtils.adjustedDuration(
          context,
          AnimationManager.quickDuration,
        ),
        switchInCurve: AnimationManager.enterCurve,
        switchOutCurve: AnimationManager.exitCurve,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          glyph,
          key: ValueKey(playing),
          size: size.iconSize,
          color: brand.onAurora,
        ),
      ),
    );

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        label: label,
        excludeSemantics: true,
        child: disc,
      ),
    );
  }
}

/// Shared Aurora surface: gradient fill, glow, light-theme hairline,
/// hover sheen, press scale and the keyboard focus ring.
class _AuroraInk extends StatefulWidget {
  const _AuroraInk({
    required this.enabled,
    required this.onTap,
    required this.circle,
    required this.constraints,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final bool enabled;
  final VoidCallback? onTap;
  final bool circle;
  final BoxConstraints constraints;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  State<_AuroraInk> createState() => _AuroraInkState();
}

class _AuroraInkState extends State<_AuroraInk> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = OmnisonicBrand.of(context);
    final isLight = theme.brightness == Brightness.light;
    final ring = OmnisonicShadows.focusRing(
      theme.colorScheme.primary,
      brand.auroraSoft.colors[1],
    );

    // On Pearl the gradient alone is 2–3:1 against the canvas, below the 3:1 a
    // boundary needs: a 1 px #2A1F5C 12 % edge makes up the difference.
    final edge = isLight
        ? const BorderSide(color: Color(0x1F2A1F5C))
        : BorderSide.none;
    final ShapeBorder shape = widget.circle
        ? CircleBorder(side: edge)
        : StadiumBorder(side: edge);

    final decorated = DecoratedBox(
      decoration: ShapeDecoration(
        gradient: brand.aurora,
        shape: shape,
        shadows: [if (widget.enabled) ...brand.glow, if (_focused) ...ring],
      ),
      position: DecorationPosition.background,
      child: DecoratedBox(
        decoration: ShapeDecoration(shape: shape),
        position: DecorationPosition.foreground,
        child: Material(
          type: MaterialType.transparency,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onFocusChange: (value) => setState(() => _focused = value),
            customBorder: shape,
            hoverColor: OmnisonicColors.neutralWhite.withValues(alpha: 0.08),
            focusColor: OmnisonicColors.neutralWhite.withValues(alpha: 0.08),
            splashColor: OmnisonicColors.neutralWhite.withValues(alpha: 0.16),
            child: Padding(
              padding: widget.padding,
              child: Center(widthFactor: 1, child: widget.child),
            ),
          ),
        ),
      ),
    );

    return PressScale(
      enabled: widget.enabled,
      child: ConstrainedBox(
        constraints: widget.constraints,
        child: Opacity(opacity: widget.enabled ? 1 : 0.38, child: decorated),
      ),
    );
  }
}

/// Icon (or spinner) + label, shared by every button with a loading state.
///
/// Loading keeps the width: the spinner takes the icon's place, or, without
/// an icon, is drawn over the label, which stays laid out but invisible.
class ButtonContent extends StatelessWidget {
  const ButtonContent({
    super.key,
    required this.label,
    required this.color,
    required this.size,
    this.icon,
    this.loading = false,
  });

  final String label;
  final IconData? icon;
  final bool loading;
  final OmnisonicButtonSize size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = size == OmnisonicButtonSize.lg
        ? OmnisonicTypography.button.copyWith(fontSize: 16)
        : OmnisonicTypography.button;
    const glyph = OmnisonicIconSizes.smd;
    final hasLead = icon != null;

    Widget lead() => SizedBox.square(
      dimension: glyph,
      child: loading
          ? _Spinner(color: color)
          : Icon(icon, size: glyph, color: color),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: loading && !hasLead ? 0 : 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasLead) ...[
                lead(),
                const SizedBox(width: OmnisonicSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
        if (loading && !hasLead) lead(),
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox.square(
      dimension: OmnisonicIconSizes.sm,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    ),
  );
}
