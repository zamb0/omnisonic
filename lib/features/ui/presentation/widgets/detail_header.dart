import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// The header of an album, artist or playlist page: artwork, an eyebrow, the
/// title, a subtitle, metadata chips and the primary actions.
///
/// - Narrow (under 720px): artwork above the text, title at
///   [OmnisonicTypography.sectionTitle]. Wide: artwork beside the text,
///   title at [OmnisonicTypography.pageTitle]. The album page had these
///   inverted (52px on phones, 28px on desktop), so long titles took five
///   lines on the smallest screens.
/// - Actions sit in a [Wrap]: Play, Shuffle and Download in a Row needed
///   ~360px and overflowed a 360dp phone.
/// - Narrow and not [forceNarrow] (a phone): a 120px cover beside the title,
///   the actions on one full-width row below. Stacked, the 160px cover and
///   the wrapped actions pushed the first track below the fold. Icon-only
///   actions ([IconButton]) keep their size; the others share the row.
/// - Short windows (landscape phones) get a smaller cover when wide.
class DetailHeader extends StatelessWidget {
  const DetailHeader({
    super.key,
    required this.title,
    required this.artwork,
    this.eyebrow,
    this.subtitle,
    this.chips = const [],
    this.actions = const [],
    this.below,
    this.artworkSize,
    this.forceNarrow = false,
  });

  final String title;

  /// The artwork; it is laid out at [artworkSize] (or the default for the
  /// width) and should fill that box.
  final Widget artwork;
  final String? eyebrow;

  /// Usually the artist. A widget, so it can be a link.
  final Widget? subtitle;
  final List<Widget> chips;

  /// Primary actions — Play first, as a filled button.
  final List<Widget> actions;

  /// Extra content under the actions, e.g. a source picker.
  final Widget? below;

  /// Overrides the artwork edge (160 narrow, 200 wide).
  final double? artworkSize;

  /// Stacks artwork and text even when wide — for a header that sits in a
  /// column of its own.
  final bool forceNarrow;

  /// Below this width the header stacks.
  static const double narrowBreakpoint = 720;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = forceNarrow || constraints.maxWidth < narrowBreakpoint;
        final short = MediaQuery.sizeOf(context).height < 500;
        if (narrow && !forceNarrow) {
          return _buildCompact(context, artworkSize ?? 120);
        }
        final size = artworkSize ?? (narrow ? 160.0 : (short ? 140.0 : 200.0));
        final art = SizedBox.square(dimension: size, child: artwork);
        final text = _buildText(context, narrow: narrow);
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              art,
              const SizedBox(height: OmnisonicSpacing.md),
              text,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            art,
            const SizedBox(width: OmnisonicSpacing.lg),
            Expanded(child: text),
          ],
        );
      },
    );
  }

  Widget _buildCompact(BuildContext context, double size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox.square(dimension: size, child: artwork),
            const SizedBox(width: OmnisonicSpacing.md),
            Expanded(
              child: _buildText(context, narrow: true, withActions: false),
            ),
          ],
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: OmnisonicSpacing.md),
          Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: OmnisonicSpacing.sm),
                if (actions[i] is IconButton)
                  actions[i]
                else
                  Expanded(child: actions[i]),
              ],
            ],
          ),
        ],
        if (below != null) ...[
          const SizedBox(height: OmnisonicSpacing.md),
          below!,
        ],
      ],
    );
  }

  Widget _buildText(
    BuildContext context, {
    required bool narrow,
    bool withActions = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle =
        (narrow
                ? OmnisonicTypography.sectionTitle
                : OmnisonicTypography.pageTitle)
            .copyWith(color: scheme.onSurface);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!.toUpperCase(),
            style: OmnisonicTypography.eyebrow.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: OmnisonicSpacing.ms),
        ],
        Semantics(
          header: true,
          child: Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: OmnisonicSpacing.sm),
          DefaultTextStyle.merge(
            style: OmnisonicTypography.bodyMedium.copyWith(
              color: scheme.onSurface,
              fontWeight: OmnisonicTypography.semiBold,
            ),
            child: subtitle!,
          ),
        ],
        if (chips.isNotEmpty) ...[
          const SizedBox(height: OmnisonicSpacing.md),
          Wrap(
            spacing: OmnisonicSpacing.sm,
            runSpacing: OmnisonicSpacing.sm,
            children: chips,
          ),
        ],
        if (withActions && actions.isNotEmpty) ...[
          const SizedBox(height: OmnisonicSpacing.ml),
          Wrap(
            spacing: OmnisonicSpacing.sm,
            runSpacing: OmnisonicSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions,
          ),
        ],
        if (withActions && below != null) ...[
          const SizedBox(height: OmnisonicSpacing.md),
          below!,
        ],
      ],
    );
  }
}
