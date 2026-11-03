import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/track.dart';
import '../../../../core/utils/formatters.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import 'cover_art.dart';
import 'server_dot.dart';

/// What sits at the start of a [TrackRow].
enum TrackRowLeading {
  /// The cover thumbnail.
  art,

  /// The track's number on its album — album lists.
  trackNumber,

  /// [TrackRow.position], then the cover — queue and playlist lists.
  positionAndArt,
}

/// One track in a list, for every list in the app.
///
/// Replaces `TrackTile`, the Home page's own row, the playlist page's
/// `DraggableTrackTile` and the queue's private row, which disagreed on
/// density, artwork, menus and drag handles — and painted opaque
/// `surface` slabs over the glass backdrop.
///
/// - Tap plays ([onTap]). Long press, right-click and the trailing "more"
///   button call [onShowActions].
/// - Pass [reorderIndex] inside a reorderable list to show a drag handle;
///   only the handle starts a drag, so the list still scrolls on touch.
/// - Announced as one button: title, artist and length.
class TrackRow extends StatelessWidget {
  const TrackRow({
    super.key,
    required this.track,
    this.onTap,
    this.onShowActions,
    this.leading = TrackRowLeading.art,
    this.position,
    this.serverId,
    this.sourceServerIds,
    this.qualityLabel,
    this.sourceNote,
    this.showAlbum = false,
    this.isCurrent,
    this.reorderIndex,
    this.trailing,
    this.dense = false,
    this.showDuration = true,
  });

  final Track track;
  final VoidCallback? onTap;

  /// Opens the track's actions sheet. Also shows the "more" button.
  final VoidCallback? onShowActions;

  final TrackRowLeading leading;

  /// 1-based position in the list, for [TrackRowLeading.positionAndArt].
  final int? position;

  /// Source server: a small [ServerDot] before the artist. Leave null where
  /// the source is not relevant.
  final String? serverId;

  /// Servers a merged track is on; more than one shows a [ServerDotStack]
  /// instead of [serverId]'s single dot.
  final List<String>? sourceServerIds;

  /// Short technical label after the artist, e.g. "FLAC".
  final String? qualityLabel;

  /// One line comparing this copy with other sources ("Only on Attic").
  final String? sourceNote;

  /// Adds the album after the artist.
  final bool showAlbum;

  /// Marks the row as the track now playing. Null works it out from the
  /// [PlaybackViewModel] in the tree.
  final bool? isCurrent;

  /// The row's index in an enclosing [ReorderableListView] or
  /// [SliverReorderableList]; shows a drag handle that starts the drag.
  final int? reorderIndex;

  /// Extra trailing control, before the duration — e.g. a remove button.
  final Widget? trailing;

  /// Tighter padding and a smaller thumbnail, for narrow carousels.
  final bool dense;

  final bool showDuration;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gutter = PageGutter.of(context);
    final isCurrent = this.isCurrent ?? _isPlaying(context);
    final artSize = dense ? 40.0 : 48.0;
    final titleColor = isCurrent ? scheme.primary : scheme.onSurface;
    final sources = sourceServerIds;

    final subtitleParts = <String>[
      track.artist,
      if (showAlbum && track.album.isNotEmpty) track.album,
    ];

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (isCurrent) ...[
              Icon(
                OmnisonicIcons.graphicEq,
                size: OmnisonicIconSizes.inline,
                color: scheme.primary,
              ),
              const SizedBox(width: OmnisonicSpacing.xs),
            ],
            Expanded(
              child: Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    (dense
                            ? OmnisonicTypography.cardTitle
                            : OmnisonicTypography.titleSmall)
                        .copyWith(color: titleColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: OmnisonicSpacing.xxs),
        Row(
          children: [
            if (sources != null && sources.length > 1) ...[
              ServerDotStack(serverIds: sources, dotSize: 8),
              const SizedBox(width: OmnisonicSpacing.xs + OmnisonicSpacing.xxs),
            ] else if (serverId != null) ...[
              ServerDot(serverId: serverId!, size: 8),
              const SizedBox(width: OmnisonicSpacing.xs + OmnisonicSpacing.xxs),
            ],
            Flexible(
              child: Text(
                subtitleParts.join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OmnisonicTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (qualityLabel != null) ...[
              const SizedBox(width: OmnisonicSpacing.xs + OmnisonicSpacing.xxs),
              Text(
                '· $qualityLabel',
                style: OmnisonicTypography.technicalSmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        if (sourceNote != null)
          Padding(
            padding: const EdgeInsets.only(top: OmnisonicSpacing.xxs),
            child: Text(
              sourceNote!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OmnisonicTypography.caption.copyWith(
                color: scheme.tertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );

    final Widget lead = switch (leading) {
      TrackRowLeading.art => CoverArt(url: track.coverArtUrl, size: artSize),
      TrackRowLeading.trackNumber => SizedBox(
        width: 32,
        child: Text(
          track.trackNumber?.toString() ?? '—',
          textAlign: TextAlign.center,
          style: OmnisonicTypography.metadata.copyWith(
            color: isCurrent ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
      TrackRowLeading.positionAndArt => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              position?.toString() ?? '',
              textAlign: TextAlign.center,
              style: OmnisonicTypography.metadata.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: OmnisonicSpacing.sm),
          CoverArt(url: track.coverArtUrl, size: artSize),
        ],
      ),
    };

    final label = [
      track.title,
      track.artist,
      if (showDuration) formatDuration(track.duration),
      if (isCurrent) 'now playing',
    ].join(', ');

    // The row's content sits on the page gutter; its hover and press ink
    // reaches a little past it on each side, as a rounded tile rather than a
    // full-bleed band.
    const inkBleed = OmnisonicSpacing.sm;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 0 : (gutter - inkBleed).clamp(0, gutter),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onShowActions,
          onSecondaryTap: onShowActions,
          borderRadius: BorderRadius.circular(OmnisonicRadius.tile),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? OmnisonicSpacing.xs : inkBleed,
              vertical: dense
                  ? OmnisonicSpacing.xs
                  : OmnisonicSpacing.xs + OmnisonicSpacing.xxs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: onTap != null,
                    label: label,
                    excludeSemantics: true,
                    child: Row(
                      children: [
                        lead,
                        SizedBox(
                          width: dense
                              ? OmnisonicSpacing.sm
                              : OmnisonicSpacing.ms,
                        ),
                        Expanded(child: info),
                        if (showDuration) ...[
                          const SizedBox(width: OmnisonicSpacing.sm),
                          Text(
                            formatDuration(track.duration),
                            style: OmnisonicTypography.duration.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                ?trailing,
                if (onShowActions != null)
                  IconButton(
                    icon: const Icon(OmnisonicIcons.moreVert),
                    iconSize: OmnisonicIconSizes.smd,
                    tooltip: 'More actions for ${track.title}',
                    onPressed: onShowActions,
                  ),
                if (reorderIndex != null)
                  ReorderableDragStartListener(
                    index: reorderIndex!,
                    child: Semantics(
                      label: 'Reorder ${track.title}',
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: SizedBox.square(
                          dimension: OmnisonicTouchTargets.minimum,
                          child: Icon(
                            OmnisonicIcons.dragHandle,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isPlaying(BuildContext context) {
    try {
      return context.select<PlaybackViewModel, bool>(
        (vm) => vm.currentTrack?.id == track.id,
      );
    } on ProviderNotFoundException {
      return false;
    }
  }
}
