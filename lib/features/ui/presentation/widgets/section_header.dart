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
      SectionHeaderSize.medium => OmnisonicTypography.groupTitle,
      SectionHeaderSize.small => OmnisonicTypography.eyebrow,
    };
    final small = size == SectionHeaderSize.small;
    // A large title and its counter do not both fit a phone row: the
    // counter goes, rather than the title being cut to "Recently Add…".
    final showMeta =
        meta != null &&
        !(size == SectionHeaderSize.large &&
            MediaQuery.sizeOf(context).width < ResponsiveBreakpoints.mobile);
    final shownTitle = small ? title.toUpperCase() : title;
    final titleColor = small ? scheme.onSurfaceVariant : scheme.onSurface;

    // Default: on the page gutter, with the space above stepping down with
    // the header's rank and the header-to-content gap below.
    final gutter = PageGutter.of(context);
    return Padding(
      padding:
          padding ??
          EdgeInsets.fromLTRB(
            gutter,
            switch (size) {
              SectionHeaderSize.large => OmnisonicLayout.sectionGap(context),
              SectionHeaderSize.medium => OmnisonicSpacing.lg,
              SectionHeaderSize.small => OmnisonicSpacing.md,
            },
            gutter,
            size == SectionHeaderSize.small
                ? OmnisonicSpacing.sm
                : OmnisonicLayout.headerGap,
          ),
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
                          shownTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: style.copyWith(color: titleColor),
                        ),
                      ),
                    ),
                    if (showMeta) ...[
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
                  const SizedBox(height: OmnisonicSpacing.xxs),
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
            // Pulled right by its own padding so the label, not the ink
            // area, ends on the gutter.
            Transform.translate(
              offset: const Offset(OmnisonicSpacing.ms, 0),
              child: TextButton(
                onPressed: onSeeAllPressed,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(
                    horizontal: OmnisonicSpacing.ms,
                  ),
                ),
                child: Text(seeAllLabel),
              ),
            ),
        ],
      ),
    );
  }
}
