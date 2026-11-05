import 'package:flutter/material.dart';

import 'brand.dart';
import 'spacing.dart';

/// Draws the keyboard focus ring (`focusRing`, §6) around a custom control
/// that has no ring of its own — an `InkWell` or `GestureDetector` built into
/// a bespoke widget. Wrap it, and the ring appears while anything inside has
/// focus *and the user is navigating by keyboard*; a mouse click does not
/// light it. (The focus node itself stays the child's.)
///
/// - [halo] alone (no [ring]) is what the search field wears: the soft
///   `auroraSoft` glow, shown for any focus.
/// - [shape] / [borderRadius] match the child's outline.
class FocusDecoration extends StatefulWidget {
  const FocusDecoration({
    super.key,
    required this.child,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.ring = true,
    this.keyboardOnly = true,
  });

  final Widget child;

  /// For a rectangular child; defaults to the control radius.
  final BorderRadius? borderRadius;
  final BoxShape shape;

  /// Whether the 2 px accent ring is drawn (the halo always is).
  final bool ring;

  /// Show only for keyboard focus. Set false for text input, where focus by
  /// click is also worth showing.
  final bool keyboardOnly;

  @override
  State<FocusDecoration> createState() => _FocusDecorationState();
}

class _FocusDecorationState extends State<FocusDecoration> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final halo = OmnisonicBrand.of(context).auroraSoft.colors[1];
    final byKeyboard =
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    final show = _focused && (!widget.keyboardOnly || byKeyboard);

    final shadows = !show
        ? null
        : widget.ring
        ? OmnisonicShadows.focusRing(scheme.primary, halo)
        : [BoxShadow(color: halo, spreadRadius: 4)];

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (value) => setState(() => _focused = value),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: widget.shape,
          borderRadius: widget.shape == BoxShape.circle
              ? null
              : widget.borderRadius ??
                    BorderRadius.circular(OmnisonicRadius.control),
          boxShadow: shadows,
        ),
        child: widget.child,
      ),
    );
  }
}
