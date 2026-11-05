import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../music/presentation/widgets/add_to_playlist_sheet.dart';
import '../../../offline/presentation/viewmodels/offline_mode_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';
import 'cover_art.dart';
import 'dialogs.dart';
import 'feedback.dart';

/// One entry in an actions sheet.
class MediaAction {
  const MediaAction(this.label, this.icon, this.run);

  final String label;
  final IconData icon;

  /// Runs after the sheet has closed, with the context that opened it.
  final void Function(BuildContext context) run;
}

/// The actions available on a track, wherever it is shown.
///
/// There used to be three sheets, each with a different subset: the album
/// page had Info but no Download, search had Download but no Info, Home had
/// no sheet at all. [onPlay] is the surface's own "play from here" — it knows
/// the queue the track sits in — and is offered first when given.
Future<void> showTrackActions(
  BuildContext context,
  Track track, {
  VoidCallback? onPlay,
  bool showGoToAlbum = true,
  List<MediaAction> extra = const [],
}) {
  final playback = context.read<PlaybackViewModel>();
  final offline = _maybeRead<OfflineModeViewModel>(context);
  final isDownloaded = offline?.isTrackAvailableOffline(track.id) ?? false;
  final isDownloading = offline?.isTrackDownloading(track.id) ?? false;

  return _showActionSheet(
    context,
    title: track.title,
    subtitle: track.artist,
    imageUrl: track.coverArtUrl,
    actions: [
      if (onPlay != null)
        MediaAction('Play', OmnisonicIcons.playArrow, (_) => onPlay()),
      // Both undoable: a stray tap on the sheet changed the queue with no way
      // back but finding the track in it.
      MediaAction('Play next', OmnisonicIcons.playNext, (context) {
        final at = playback.hasCurrentTrack ? playback.currentIndex + 1 : 0;
        playback.insertInQueue(track, at);
        showFeedback(
          context,
          'Plays next',
          kind: FeedbackKind.success,
          actionLabel: 'Undo',
          onAction: () => playback.removeFromQueue(at),
        );
      }),
      MediaAction('Add to queue', OmnisonicIcons.addToQueue, (context) async {
        await playback.addToQueue(track);
        if (!context.mounted) return;
        final at = playback.queueLength - 1;
        showFeedback(
          context,
          'Added to queue',
          kind: FeedbackKind.success,
          actionLabel: 'Undo',
          onAction: () => playback.removeFromQueue(at),
        );
      }),
      MediaAction(
        'Add to playlist',
        OmnisonicIcons.playlistAdd,
        (context) => showAddToPlaylistSheet(context, track),
      ),
      MediaAction(
        track.isStarred ? 'Remove from favorites' : 'Add to favorites',
        track.isStarred
            ? OmnisonicIcons.favorite
            : OmnisonicIcons.favoriteOutline,
        (_) => playback.toggleFavorite(track),
      ),
      if (offline != null && !isDownloading)
        MediaAction(
          isDownloaded ? 'Remove download' : 'Download',
          isDownloaded
              ? OmnisonicIcons.downloadDone
              : OmnisonicIcons.downloadOutline,
          (context) async {
            final error = isDownloaded
                ? await offline.removeDownload(track.id)
                : await offline.downloadTrack(track);
            if (!context.mounted) return;
            showFeedback(
              context,
              error ??
                  (isDownloaded
                      ? 'Download removed'
                      : 'Downloaded for offline'),
              kind: error == null ? FeedbackKind.success : FeedbackKind.error,
            );
          },
        ),
      if (showGoToAlbum && track.albumId != null)
        MediaAction(
          'Go to album',
          OmnisonicIcons.album,
          (context) =>
              context.push(AppRouter.albumDetailLocation(track.albumId!)),
        ),
      if (track.artistId != null)
        MediaAction(
          'Go to artist',
          OmnisonicIcons.person,
          (context) =>
              context.push(AppRouter.artistDetailLocation(track.artistId!)),
        ),
      ...extra,
      MediaAction(
        'Track info',
        OmnisonicIcons.info,
        (context) => showTrackInfo(context, track),
      ),
    ],
  );
}

/// The actions available on an album card or header.
Future<void> showAlbumActions(
  BuildContext context,
  Album album, {
  bool showGoToAlbum = true,
}) {
  final library = context.read<MusicLibraryViewModel>();
  final starred = library.isAlbumStarred(album);
  final offline = _maybeRead<OfflineModeViewModel>(context);

  return _showActionSheet(
    context,
    title: album.title,
    subtitle: album.artist,
    imageUrl: album.coverArtUrl,
    actions: [
      MediaAction(
        'Play',
        OmnisonicIcons.playArrow,
        (context) => playAlbum(context, album),
      ),
      MediaAction(
        'Shuffle',
        OmnisonicIcons.shuffle,
        (context) => playAlbum(context, album, shuffle: true),
      ),
      MediaAction(
        starred ? 'Remove from favorites' : 'Add to favorites',
        starred ? OmnisonicIcons.star : OmnisonicIcons.starOutline,
        (_) => starred ? library.unstarAlbum(album) : library.starAlbum(album),
      ),
      if (offline != null)
        MediaAction('Download', OmnisonicIcons.downloadOutline, (
          context,
        ) async {
          final tracks = await library.getAlbumTracks(album.id);
          final failures = await offline.downloadTracks(tracks);
          if (!context.mounted) return;
          showFeedback(
            context,
            failures == 0
                ? '${album.title} is available offline'
                : "${pluralize(failures, 'track')} couldn't be downloaded",
            kind: failures == 0 ? FeedbackKind.success : FeedbackKind.error,
          );
        }),
      if (showGoToAlbum)
        MediaAction(
          'Go to album',
          OmnisonicIcons.album,
          (context) => context.push(
            AppRouter.albumDetailLocation(album.id),
            extra: album,
          ),
        ),
      if (album.artistId != null)
        MediaAction(
          'Go to artist',
          OmnisonicIcons.person,
          (context) =>
              context.push(AppRouter.artistDetailLocation(album.artistId!)),
        ),
    ],
  );
}

/// Loads [album]'s tracks and plays them, optionally shuffled.
Future<void> playAlbum(
  BuildContext context,
  Album album, {
  bool shuffle = false,
}) async {
  final library = context.read<MusicLibraryViewModel>();
  final playback = context.read<PlaybackViewModel>();
  final tracks = await library.getAlbumTracks(album.id);
  if (tracks.isEmpty) {
    if (context.mounted) {
      showFeedback(
        context,
        "Couldn't load ${album.title}",
        kind: FeedbackKind.error,
      );
    }
    return;
  }
  final queue = shuffle ? (List<Track>.of(tracks)..shuffle()) : tracks;
  await playback.playTrack(queue.first, queue: queue, startIndex: 0);
}

/// A dialog with a track's details.
Future<void> showTrackInfo(BuildContext context, Track track) {
  final servers = _maybeRead<ServerManagementViewModel>(context);
  final rows = <(String, String)>[
    ('Artist', track.artist),
    ('Album', track.album),
    ('Duration', formatDuration(track.duration)),
    if (track.year != null) ('Year', '${track.year}'),
    if (track.genre != null) ('Genre', track.genre!),
    if (track.trackNumber != null) ('Track', '${track.trackNumber}'),
    ('Format', track.quality.displayName),
    ('Server', servers?.serverNameFor(track.serverId) ?? track.serverId),
  ];
  return showDetailsDialog(context, title: track.title, rows: rows);
}

Future<void> _showActionSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  String? imageUrl,
  required List<MediaAction> actions,
}) async {
  Haptics.selection();
  final chosen = await showModalBottomSheet<MediaAction>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: OmnisonicSpacing.sm),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                OmnisonicSpacing.lg,
                0,
                OmnisonicSpacing.lg,
                OmnisonicSpacing.md,
              ),
              child: Row(
                children: [
                  CoverArt(
                    url: imageUrl,
                    seed: title,
                    size: 56,
                    elevated: true,
                  ),
                  const SizedBox(width: OmnisonicSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: OmnisonicTypography.groupTitle.copyWith(
                            color: Theme.of(sheetContext).colorScheme.onSurface,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: OmnisonicTypography.bodySmall.copyWith(
                              color: Theme.of(
                                sheetContext,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: OmnisonicSpacing.xs),
            for (final action in actions)
              ListTile(
                minTileHeight: OmnisonicTouchTargets.comfortable,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: OmnisonicSpacing.lg,
                ),
                leading: Icon(action.icon, size: OmnisonicIconSizes.smd),
                title: Text(action.label),
                onTap: () => Navigator.pop(sheetContext, action),
              ),
          ],
        ),
      ),
    ),
  );
  if (chosen != null && context.mounted) chosen.run(context);
}

T? _maybeRead<T>(BuildContext context) {
  try {
    return Provider.of<T>(context, listen: false);
  } on ProviderNotFoundException {
    return null;
  }
}
