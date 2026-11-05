import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/track.dart';
import '../../../../core/utils/formatters.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import 'cover_art.dart';
import 'now_playing_equalizer.dart';
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
class TrackRow extends StatefulWidget {
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
    this.selected = false,
    this.unavailable = false,
    this.unavailableReason = 'Server offline',
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

  /// Picked in a multi-selection: the `wellHover` fill.
  final bool selected;

  /// The track's server is offline: the row is dimmed to half, shows a
  /// cloud-off icon and explains itself in a tooltip. Still tappable — the
  /// source selection may have another copy to play.
  final bool unavailable;

  /// The tooltip and announcement for [unavailable].
  final String unavailableReason;

  @override
  State<TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends State<TrackRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final onTap = widget.onTap;
    final onShowActions = widget.onShowActions;
    final leading = widget.leading;
    final dense = widget.dense;
    final showDuration = widget.showDuration;
    final surfaces = OmnisonicSurfaces.of(context);
    final scheme = Theme.of(context).colorScheme;
    final gutter = PageGutter.of(context);
    final isCurrent = widget.isCurrent ?? _isCurrentTrack(context);
    // Paused: the bars stay, but still.
    final audible = isCurrent && _isAudible(context);
    final artSize = dense ? 40.0 : 48.0;
    final titleColor = isCurrent ? scheme.primary : scheme.onSurface;
    final sources = widget.sourceServerIds;

    final subtitleParts = <String>[
      track.artist,
      if (widget.showAlbum && track.album.isNotEmpty) track.album,
    ];

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
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
            ] else if (widget.serverId != null) ...[
              ServerDot(serverId: widget.serverId!, size: 8),
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
            if (widget.qualityLabel != null) ...[
              const SizedBox(width: OmnisonicSpacing.xs + OmnisonicSpacing.xxs),
              Text(
                '· ${widget.qualityLabel}',
                style: OmnisonicTypography.technicalSmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        if (widget.sourceNote != null)
          Padding(
            padding: const EdgeInsets.only(top: OmnisonicSpacing.xxs),
            child: Text(
              widget.sourceNote!,
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

    // The index slot: number, or — where the row can be played — a play
    // glyph under the pointer, or the equalizer when this is the live track.
    Widget indexSlot(String text, double width) => SizedBox(
      width: width,
      child: Center(
        child: isCurrent
            ? NowPlayingEqualizer(playing: audible, excludeSemantics: true)
            : _hovered && onTap != null
            ? Icon(
                OmnisonicIcons.playArrow,
                size: OmnisonicIconSizes.smd,
                color: scheme.onSurface,
              )
            : Text(
                text,
                textAlign: TextAlign.center,
                style: OmnisonicTypography.timecode.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
      ),
    );

    // On a thumbnail the live track is marked by the bars over a scrim.
    Widget art() => Stack(
      alignment: Alignment.center,
      children: [
        CoverArt(
          url: track.coverArtUrl,
          seed: track.albumId ?? track.id,
          size: artSize,
        ),
        if (isCurrent)
          SizedBox.square(
            dimension: artSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: OmnisonicColors.scrim,
                borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
              ),
              child: Center(
                child: NowPlayingEqualizer(
                  playing: audible,
                  color: OmnisonicColors.onScrim,
                  excludeSemantics: true,
                ),
              ),
            ),
          ),
      ],
    );

    final Widget lead = switch (leading) {
      TrackRowLeading.art => art(),
      TrackRowLeading.trackNumber => indexSlot(
        track.trackNumber?.toString() ?? '—',
        32,
      ),
      TrackRowLeading.positionAndArt => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          indexSlot(widget.position?.toString() ?? '', 24),
          const SizedBox(width: OmnisonicSpacing.sm),
          art(),
        ],
      ),
    };

    final label = [
      track.title,
      track.artist,
      if (showDuration) formatDuration(track.duration),
      if (isCurrent) 'now playing',
      if (widget.unavailable) widget.unavailableReason.toLowerCase(),
    ].join(', ');

    // The row's content sits on the page gutter; its hover and press ink
    // reaches a little past it on each side, as a rounded tile rather than a
    // full-bleed band.
    const inkBleed = OmnisonicSpacing.sm;
    final radius = BorderRadius.circular(OmnisonicRadius.tile);
    // Live > selected > hover. The live fill is the accent container at 40 %.
    final fill = isCurrent
        ? scheme.primaryContainer.withValues(alpha: 0.4)
        : widget.selected
        ? surfaces.wellHover
        : _hovered
        ? surfaces.well
        : Colors.transparent;

    Widget row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 0 : (gutter - inkBleed).clamp(0, gutter),
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: DecoratedBox(
          decoration: BoxDecoration(color: fill, borderRadius: radius),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              onLongPress: onShowActions,
              onSecondaryTap: onShowActions,
              borderRadius: radius,
              // The fill above is the hover state.
              hoverColor: Colors.transparent,
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
                                style: OmnisonicTypography.timecode.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            if (widget.unavailable) ...[
                              const SizedBox(width: OmnisonicSpacing.sm),
                              Icon(
                                OmnisonicIcons.cloudOff,
                                size: OmnisonicIconSizes.sm,
                                color: scheme.onSurfaceVariant,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    ?widget.trailing,
                    if (onShowActions != null)
                      IconButton(
                        icon: const Icon(OmnisonicIcons.moreVert),
                        iconSize: OmnisonicIconSizes.smd,
                        tooltip: 'More actions for ${track.title}',
                        onPressed: onShowActions,
                      ),
                    if (widget.reorderIndex != null)
                      ReorderableDragStartListener(
                        index: widget.reorderIndex!,
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
        ),
      ),
    );

    if (widget.unavailable) {
      row = Tooltip(
        message: widget.unavailableReason,
        child: Opacity(opacity: 0.5, child: row),
      );
    }
    return row;
  }

  bool _isCurrentTrack(BuildContext context) {
    try {
      return context.select<PlaybackViewModel, bool>(
        (vm) => vm.currentTrack?.id == widget.track.id,
      );
    } on ProviderNotFoundException {
      return false;
    }
  }

  bool _isAudible(BuildContext context) {
    try {
      return context.select<PlaybackViewModel, bool>((vm) => vm.isPlaying);
    } on ProviderNotFoundException {
      return true;
    }
  }
}
