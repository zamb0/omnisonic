import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// How prominent a [SectionHeader] is.
enum SectionHeaderSize {
  /// Home's feed sections: Gabarito display type.
  large,

  /// A section inside a page — "Tracks", "Albums" in search results.
  medium,

  /// A label above a group in a sheet or a card.
  small,
}

/// A section's heading, with an optional mono counter and one action.
///
/// Replaces Home's private `_buildSectionHeader` and the ad hoc "Tracks"
/// and "Albums" rows, which each picked their own size and weight.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  /// Mono counter after the title — "24", "3 servers".
  final String? meta;

  final VoidCallback? onSeeAllPressed;

  /// Label for the trailing action, so a section that toggles can read
  /// "Show less" once it is expanded.
  final String seeAllLabel;
  final EdgeInsets? padding;
  final SectionHeaderSize size;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.meta,
    this.onSeeAllPressed,
    this.seeAllLabel = 'See all',
    this.padding,
    this.size = SectionHeaderSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = switch (size) {
      SectionHeaderSize.large =>
        MediaQuery.sizeOf(context).width >= ResponsiveBreakpoints.tablet
            ? OmnisonicTypography.sectionTitle
            : OmnisonicTypography.sectionTitleSmall,
      SectionHeaderSize.medium => OmnisonicTypography.titleLarge.copyWith(
        fontWeight: OmnisonicTypography.bold,
      ),
      SectionHeaderSize.small => OmnisonicTypography.titleSmall.copyWith(
        fontWeight: OmnisonicTypography.semiBold,
      ),
    };

    return Padding(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Semantics(
                        header: true,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: style.copyWith(color: scheme.onSurface),
                        ),
                      ),
                    ),
                    if (meta != null) ...[
                      const SizedBox(width: OmnisonicSpacing.sm),
                      Flexible(
                        child: Text(
                          meta!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: OmnisonicTypography.technical.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: OmnisonicTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onSeeAllPressed != null)
            TextButton(onPressed: onSeeAllPressed, child: Text(seeAllLabel)),
        ],
      ),
    );
  }
}
