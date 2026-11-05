import 'package:flutter/material.dart';

import 'aurora_button.dart';
import 'motion.dart';
import 'spacing.dart';
import 'surfaces.dart';

/// What a button is for (docs/design-system.md §9.1). The signature Play is
/// an [AuroraButton]; outlined and text buttons are the stock Material ones,
/// themed.
enum OmnisonicButtonVariant {
  /// Ink fill: Save, Add server, Connect.
  primary,

  /// `well` fill with a hairline: secondary actions, Shuffle beside Play.
  tonal,

  /// `error` fill: confirming a deletion. Never in the first view.
  destructive,
}

/// A [FilledButton] with the three heights, a loading state and the press
/// scale. The loading state keeps the width (spinner in the icon's place, or
/// over the label when there is no icon), ignores taps and announces itself
/// as a live region.
class OmnisonicButton extends StatelessWidget {
  const OmnisonicButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.size = OmnisonicButtonSize.md,
    this.variant = OmnisonicButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final OmnisonicButtonSize size;
  final OmnisonicButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surfaces = OmnisonicSurfaces.of(context);
    final enabled = onPressed != null && !loading;

    final (Color fg, ButtonStyle style) = switch (variant) {
      OmnisonicButtonVariant.primary => (surfaces.onInk, const ButtonStyle()),
      OmnisonicButtonVariant.tonal => (
        scheme.onSurface,
        ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? surfaces.well
                : states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.pressed)
                ? surfaces.wellHover
                : surfaces.well,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: 0.38)
                : scheme.onSurface,
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? BorderSide(color: scheme.primary, width: 2)
                : BorderSide(color: surfaces.hairline),
          ),
        ),
      ),
      OmnisonicButtonVariant.destructive => (
        scheme.onError,
        ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: 0.12)
                : scheme.error,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: 0.38)
                : scheme.onError,
          ),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered)
                ? scheme.onError.withValues(alpha: 0.08)
                : states.contains(WidgetState.pressed) ||
                      states.contains(WidgetState.focused)
                ? scheme.onError.withValues(alpha: 0.12)
                : null,
          ),
        ),
      ),
    };

    final sized = style.copyWith(
      // The size already is the target; Material would pad 36 up to 48.
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: WidgetStatePropertyAll(Size(64, size.height)),
      maximumSize: WidgetStatePropertyAll(Size(double.infinity, size.height)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: OmnisonicSpacing.ml),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled || loading,
      liveRegion: loading,
      label: loading ? '$label, loading' : label,
      excludeSemantics: true,
      child: PressScale(
        enabled: enabled,
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: sized,
          child: ButtonContent(
            label: label,
            icon: icon,
            loading: loading,
            size: size,
            color: enabled || loading ? fg : fg.withValues(alpha: 0.38),
          ),
        ),
      ),
    );
  }
}
