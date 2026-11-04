import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/haptics.dart';
import 'animation_manager.dart';
import 'brand.dart';
import 'colors.dart';
import 'icons.dart';
import 'motion.dart';
import 'spacing.dart';
import 'surfaces.dart';

/// Looks of an [OmnisonicIconButton] (docs/design-system.md §9.2).
enum OmnisonicIconButtonVariant {
  /// Bare glyph, wash on hover.
  standard,

  /// Ink disc, `surface` glyph.
  filled,

  /// `well` disc.
  tonal,

  /// Translucent disc with white glyph, for controls over artwork.
  onScrim,

  /// Outlined ↔ filled glyph; on = accent (or [OmnisonicIconButton.selectedColor],
  /// e.g. `heat` for favourites). Turning on bursts the glyph 1 → 1.25 → 1
  /// with a light haptic.
  toggle,
}

/// The app's icon button: 44 × 44, always with a [tooltip] (which is also
/// the semantic label), press scale, and the keyboard focus ring on every
/// variant.
class OmnisonicIconButton extends StatefulWidget {
  const OmnisonicIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.variant = OmnisonicIconButtonVariant.standard,
    this.selected = false,
    this.selectedIcon,
    this.selectedColor,
    this.iconSize = OmnisonicIconSizes.smd,
    this.dimension = OmnisonicTouchTargets.minimum,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final OmnisonicIconButtonVariant variant;

  /// Toggle only: whether it is on.
  final bool selected;

  /// Toggle only: glyph when on (default: [icon]).
  final IconData? selectedIcon;

  /// Toggle only: colour when on (default: `primary`).
  final Color? selectedColor;
  final double iconSize;
  final double dimension;

  @override
  State<OmnisonicIconButton> createState() => _OmnisonicIconButtonState();
}

class _OmnisonicIconButtonState extends State<OmnisonicIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: AnimationManager.quickDuration,
  );
  // The spring overshoots 1, which a TweenSequence's own curve would reject,
  // so each leg carries its curve and the controller stays linear.
  late final Animation<double> _burstScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.25,
      ).chain(CurveTween(curve: AnimationManager.enterCurve)),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.25,
        end: 1.0,
      ).chain(CurveTween(curve: AnimationManager.springCurve)),
      weight: 1,
    ),
  ]).animate(_burst);

  bool _focused = false;

  @override
  void didUpdateWidget(OmnisonicIconButton old) {
    super.didUpdateWidget(old);
    final turnedOn =
        widget.variant == OmnisonicIconButtonVariant.toggle &&
        widget.selected &&
        !old.selected;
    if (turnedOn && !MediaQuery.disableAnimationsOf(context)) {
      _burst.forward(from: 0);
    }
    if (turnedOn) unawaited(Haptics.impact());
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surfaces = OmnisonicSurfaces.of(context);
    final brand = OmnisonicBrand.of(context);
    final variant = widget.variant;
    final enabled = widget.onPressed != null;

    final (Color? bg, Color fg, Color hover) = switch (variant) {
      OmnisonicIconButtonVariant.standard ||
      OmnisonicIconButtonVariant.toggle => (
        null,
        scheme.onSurface,
        scheme.onSurface.withValues(alpha: 0.08),
      ),
      OmnisonicIconButtonVariant.filled => (
        surfaces.ink,
        surfaces.onInk,
        surfaces.onInk.withValues(alpha: 0.08),
      ),
      OmnisonicIconButtonVariant.tonal => (
        surfaces.well,
        scheme.onSurface,
        surfaces.wellHover,
      ),
      OmnisonicIconButtonVariant.onScrim => (
        OmnisonicColors.scrimControl,
        OmnisonicColors.onScrim,
        OmnisonicColors.onScrim.withValues(alpha: 0.12),
      ),
    };

    final isToggle = variant == OmnisonicIconButtonVariant.toggle;
    final on = isToggle && widget.selected;
    final foreground = on ? (widget.selectedColor ?? scheme.primary) : fg;

    final ring = OmnisonicShadows.focusRing(
      scheme.primary,
      brand.auroraSoft.colors[1],
    );
    final showRing =
        _focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

    Widget glyph = Icon(
      on ? (widget.selectedIcon ?? widget.icon) : widget.icon,
    );
    if (isToggle) {
      glyph = ScaleTransition(scale: _burstScale, child: glyph);
    }

    final button = IconButton(
      onPressed: widget.onPressed,
      tooltip: widget.tooltip,
      isSelected: isToggle ? widget.selected : null,
      icon: glyph,
      iconSize: widget.iconSize,
      style: IconButton.styleFrom(
        fixedSize: Size.square(widget.dimension),
        minimumSize: Size.square(widget.dimension),
        backgroundColor: bg,
        foregroundColor: foreground,
        disabledForegroundColor: foreground.withValues(alpha: 0.38),
        disabledBackgroundColor: bg?.withValues(alpha: (bg.a * 0.5)),
        hoverColor: hover,
        highlightColor: hover,
        side: BorderSide.none,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (value) => setState(() => _focused = value),
      child: PressScale(
        enabled: enabled,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: showRing ? ring : null,
          ),
          child: button,
        ),
      ),
    );
  }
}
