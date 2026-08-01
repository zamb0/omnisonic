import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/track.dart';
import '../../../../core/services/subsonic_image_cache_manager.dart';
import 'server_dot.dart';

/// A reusable tile widget for displaying track information
class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback? onTap;
  final VoidCallback? onMorePressed;
  final bool showAlbumArt;
  final bool showTrackNumber;

  /// Source server ID: when set, renders a small [ServerDot] before the
  /// artist name. Leave null on single-source lists (search results, queue,
  /// playlists) where the source isn't relevant. Ignored when
  /// [sourceServerIds] is also set.
  final String? serverId;

  /// Server IDs for a track merged from multiple sources: when set (with
  /// more than one entry), renders a [ServerDotStack] instead of the single
  /// [ServerDot] from [serverId].
  final List<String>? sourceServerIds;

  /// Short quality label (e.g. `track.quality.format`), shown next to the
  /// artist name in JetBrains Mono, the design system's typeface for
  /// technical text.
  final String? qualityLabel;

  /// Optional one-line note comparing this copy of the track against other
  /// sources of the same album (e.g. "Only on Attic", "Lossless available
  /// on Home"). Null when there's nothing noteworthy to say.
  final String? sourceNote;

  const TrackTile({
    super.key,
    required this.track,
    this.onTap,
    this.onMorePressed,
    this.showAlbumArt = true,
    this.showTrackNumber = false,
    this.serverId,
    this.sourceServerIds,
    this.qualityLabel,
    this.sourceNote,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      tileColor: scheme.surface,
      leading: showAlbumArt
          ? _buildAlbumArt(context)
          : _buildTrackNumber(context),
      title: Text(
        track.title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (sourceServerIds != null && sourceServerIds!.length > 1) ...[
                ServerDotStack(serverIds: sourceServerIds!, dotSize: 8),
                const SizedBox(width: 6),
              ] else if (serverId != null) ...[
                ServerDot(serverId: serverId!, size: 8),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  track.artist,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (qualityLabel != null) ...[
                const SizedBox(width: 6),
                Text(
                  '· $qualityLabel',
                  style: OmnisonicTypography.metadata.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          if (sourceNote != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                sourceNote!,
                style: OmnisonicTypography.caption.copyWith(
                  color: scheme.tertiary,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDuration(track.duration),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (onMorePressed != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: onMorePressed,
              iconSize: 20,
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildAlbumArt(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: scheme.surfaceContainerHighest,
      ),
      child: track.coverArtUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: track.coverArtUrl!.withCoverArtSize(128),
                cacheKey: track.coverArtUrl!
                    .withCoverArtSize(128)
                    .subsonicCacheKey,
                cacheManager: OmnisonicImageCacheManager.instance,
                fit: BoxFit.cover,
                memCacheWidth: 128,
                memCacheHeight: 128,
                fadeInDuration: const Duration(milliseconds: 120),
                useOldImageOnUrlChange: true,
                placeholder: (context, url) => Container(
                  color: scheme.surfaceContainerHighest,
                  child: Icon(Icons.music_note, color: scheme.onSurfaceVariant),
                ),
                errorWidget: (context, url, error) => Container(
                  color: scheme.surfaceContainerHighest,
                  child: Icon(Icons.music_note, color: scheme.onSurfaceVariant),
                ),
              ),
            )
          : Icon(Icons.music_note, color: scheme.onSurfaceVariant),
    );
  }

  Widget _buildTrackNumber(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      child: Text(
        track.trackNumber?.toString() ?? '—',
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
