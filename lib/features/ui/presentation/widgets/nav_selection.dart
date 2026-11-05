import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/utils/animation_utils.dart';

/// The "you are here" mark of the sidebar and the rail: a 3 × 20 Aurora bar
/// on the item's left edge (docs/design-system.md §9.4). It scales in from
/// the middle in `fast`, and just appears with reduce motion.
///
/// The ink pill that used to mark the selection is gone: it was identical to
/// the Primary button, so "where am I" and "what do I do" read as one thing.
class AuroraBar extends StatelessWidget {
  const AuroraBar({super.key, required this.visible});

  static const double width = 3;
  static const double height = 20;

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final brand = OmnisonicBrand.of(context);
    return ExcludeSemantics(
      child: AnimatedScale(
        scale: visible ? 1 : 0,
        alignment: Alignment.center,
        duration: AnimationUtils.adjustedDuration(
          context,
          AnimationManager.fastDuration,
        ),
        curve: AnimationManager.enterCurve,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OmnisonicRadius.full),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: brand.aurora.colors,
              stops: brand.aurora.stops,
            ),
          ),
          child: const SizedBox(width: width, height: height),
        ),
      ),
    );
  }
}

/// Fill of a nav pill: `wellHover` when selected, otherwise bare (hover is
/// the InkWell's `well`).
Color navPillColor(BuildContext context, {required bool selected}) =>
    selected ? OmnisonicSurfaces.of(context).wellHover : Colors.transparent;
