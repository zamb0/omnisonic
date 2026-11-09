import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// Five stars showing a 0-5 rating, each one a button that sets it.
///
/// Tapping the star that matches the current rating clears it, the usual
/// way to un-rate, since there is no "zero stars" to tap.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = OmnisonicIconSizes.sm,
  });

  /// 0 (unrated) to 5.
  final int rating;

  /// Null shows the rating read-only.
  final ValueChanged<int>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filled = OmnisonicBrand.of(context).heat;
    return Semantics(
      container: true,
      label: rating == 0 ? 'Not rated' : 'Rated $rating of 5',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var star = 1; star <= 5; star++)
            IconButton(
              onPressed: onChanged == null
                  ? null
                  : () => onChanged!(star == rating ? 0 : star),
              tooltip: star == rating
                  ? 'Clear rating'
                  : 'Rate $star star${star == 1 ? '' : 's'}',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(
                width: size + OmnisonicSpacing.sm,
                height: kMinInteractiveDimension,
              ),
              iconSize: size,
              icon: Icon(
                star <= rating
                    ? OmnisonicIcons.star
                    : OmnisonicIcons.starOutline,
                color: star <= rating ? filled : scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
