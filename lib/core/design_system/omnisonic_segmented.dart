import 'package:flutter/material.dart';

import '../utils/animation_utils.dart';
import 'animation_manager.dart';
import 'focus_decoration.dart';
import 'icons.dart';
import 'spacing.dart';
import 'surfaces.dart';
import 'typography.dart';

/// One choice of an [OmnisonicSegmented].
class SegmentOption<T> {
  const SegmentOption({required this.value, required this.label, this.icon});

  final T value;

  /// Shown unless the control is [OmnisonicSegmented.iconsOnly]; always the
  /// tooltip and the screen-reader label.
  final String label;
  final IconData? icon;
}

/// A single-choice control on a `well` stadium: the current option sits on an
/// ink pill that **slides** to the new one (`quick`, `spring`; still with
/// reduce motion). Sort direction, theme mode, the Now Playing panels.
///
/// Replaces `SegmentedButton`, whose selection just swaps fill. Every
/// segment is a focusable button announced as selected or not, with the
/// keyboard focus ring, and equal width so the pill is one slot wide.
class OmnisonicSegmented<T> extends StatelessWidget {
  const OmnisonicSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.iconsOnly = false,
  }) : assert(options.length >= 2);

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Hide the labels, keep the icons (each option then needs an icon).
  final bool iconsOnly;

  /// Height of the control; segments are 44 minus the inset to meet the
  /// touch target.
  static const double height = OmnisonicTouchTargets.minimum;
  static const double inset = OmnisonicSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surfaces = OmnisonicSurfaces.of(context);
    final index = options.indexWhere((o) => o.value == selected);
    final duration = AnimationUtils.adjustedDuration(
      context,
      AnimationManager.quickDuration,
    );

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: surfaces.well,
        shape: StadiumBorder(side: BorderSide(color: surfaces.hairline)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(inset),
        child: SizedBox(
          height: height - inset * 2,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slot = constraints.maxWidth / options.length;
              return Stack(
                children: [
                  if (index >= 0)
                    AnimatedPositioned(
                      left: slot * index,
                      width: slot,
                      top: 0,
                      bottom: 0,
                      duration: duration,
                      curve: AnimationManager.springCurve,
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          color: surfaces.ink,
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                  // Its own transparent Material, over the pill: ink drawn on
                  // a Material further up would be hidden under it.
                  Material(
                    type: MaterialType.transparency,
                    child: Row(
                      children: [
                        for (final option in options)
                          Expanded(
                            child: _Segment<T>(
                              option: option,
                              selected: option.value == selected,
                              iconsOnly: iconsOnly,
                              onTap: () => onChanged(option.value),
                              ink: surfaces.onInk,
                              idle: scheme.onSurface,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.selected,
    required this.iconsOnly,
    required this.onTap,
    required this.ink,
    required this.idle,
  });

  final SegmentOption<T> option;
  final bool selected;
  final bool iconsOnly;
  final VoidCallback onTap;
  final Color ink;
  final Color idle;

  @override
  Widget build(BuildContext context) {
    final color = selected ? ink : idle;
    final children = [
      if (option.icon != null)
        Icon(option.icon, size: OmnisonicIconSizes.smd, color: color),
      if (option.icon != null && !iconsOnly)
        const SizedBox(width: OmnisonicSpacing.sm),
      if (!iconsOnly)
        Flexible(
          child: Text(
            option.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OmnisonicTypography.button.copyWith(color: color),
          ),
        ),
    ];

    Widget segment = Semantics(
      button: true,
      selected: selected,
      label: option.label,
      excludeSemantics: true,
      child: FocusDecoration(
        borderRadius: BorderRadius.circular(OmnisonicRadius.full),
        child: InkWell(
          onTap: selected ? null : onTap,
          customBorder: const StadiumBorder(),
          child: Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
    if (iconsOnly) segment = Tooltip(message: option.label, child: segment);
    return segment;
  }
}
