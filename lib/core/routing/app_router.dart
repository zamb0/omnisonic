import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../core/entities/entities.dart';
import '../../core/constants/animation_constants.dart';
import '../../core/utils/animation_utils.dart';
import '../../features/ui/presentation/pages/home_page.dart';
import '../../features/ui/presentation/pages/library_page.dart';
import '../../features/ui/presentation/pages/search_page.dart';
import '../../features/ui/presentation/pages/favorites_page.dart';
import '../../features/ui/presentation/pages/now_playing_page.dart';
import '../../features/playback/presentation/pages/queue_page.dart';
import '../../features/offline/presentation/pages/offline_mode_page.dart';
import '../../features/ui/presentation/pages/settings_page.dart';
import '../../features/playback/presentation/widgets/full_screen_player.dart'
    show NowPlayingPanel;
import '../../features/ui/presentation/pages/album_detail_page.dart';
import '../../features/ui/presentation/pages/artist_detail_page.dart';
import '../../features/servers/presentation/pages/server_management_page.dart';
import '../../features/music/presentation/pages/playlist_management_page.dart';
import '../../features/music/presentation/pages/playlist_detail_page.dart';
import '../../features/ui/presentation/pages/main_shell.dart';
import 'entity_route.dart';

/// Application routing configuration
class AppRouter {
  static const String home = '/';
  static const String library = '/library';
  static const String search = '/search';
  static const String nowPlaying = '/now-playing';
  static const String queue = '/queue';
  static const String albumDetail = '/album-detail';
  static const String artistDetail = '/artist-detail';
  static const String favorites = '/favorites';
  static const String servers = '/servers';
  static const String downloads = '/downloads';
  static const String settings = '/settings';
  static const String playlistManagement = '/playlist-management';
  static const String playlistDetail = '/playlist-detail';

  /// The `?id=` a deep link carries. Detail routes are linkable by id even
  /// when no entity travelled with the navigation.
  static String _idParam(GoRouterState state) =>
      state.uri.queryParameters['id'] ?? '';

  /// Locations for the detail routes.
  ///
  /// Always navigate through these rather than writing the bare path: the id
  /// in the URL is what survives a share, a restart or a restored window,
  /// even when the entity itself is also passed as `extra`.
  static String albumDetailLocation(String albumId) =>
      '$albumDetail?id=${Uri.encodeComponent(albumId)}';

  static String artistDetailLocation(String artistId) =>
      '$artistDetail?id=${Uri.encodeComponent(artistId)}';

  static String playlistDetailLocation(String playlistId) =>
      '$playlistDetail?id=${Uri.encodeComponent(playlistId)}';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    errorBuilder: (context, state) =>
        NotFoundPage(location: state.uri.toString()),
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: home,
            name: 'home',
            pageBuilder: (context, state) => _fadePage(
              context: context,
              state: state,
              child: const HomePage(),
            ),
          ),
          GoRoute(
            path: library,
            name: 'library',
            pageBuilder: (context, state) => _fadePage(
              context: context,
              state: state,
              child: const LibraryPage(),
            ),
          ),
          GoRoute(
            path: search,
            name: 'search',
            pageBuilder: (context, state) => _fadePage(
              context: context,
              state: state,
              child: const SearchPage(),
            ),
          ),
          GoRoute(
            path: favorites,
            name: 'favorites',
            pageBuilder: (context, state) => _fadePage(
              context: context,
              state: state,
              child: const FavoritesPage(),
            ),
          ),
          GoRoute(
            path: servers,
            name: 'servers',
            pageBuilder: (context, state) => _fadePage(
              context: context,
              state: state,
              child: const ServerManagementPage(),
            ),
          ),
          GoRoute(
            path: downloads,
            name: 'downloads',
            pageBuilder: (context, state) => _fadePage(
              context: context,
              state: state,
              child: const OfflineModePage(),
            ),
          ),
          GoRoute(
            path: settings,
            name: 'settings',
            pageBuilder: (context, state) => _fadePage(
              context: context,
              state: state,
              child: const SettingsPage(),
            ),
          ),
          GoRoute(
            path: albumDetail,
            name: 'albumDetail',
            pageBuilder: (context, state) {
              // `extra` is null for anything that isn't an in-app tap, so
              // the id in the URL is what makes this route linkable.
              final album = state.extra is Album ? state.extra as Album : null;
              return _fadePage(
                context: context,
                state: state,
                child: EntityRoute<Album>(
                  entity: album,
                  entityId: album?.id ?? _idParam(state),
                  lookup: (library, id) =>
                      library.albums.where((a) => a.id == id).firstOrNull,
                  builder: (album) => AlbumDetailPage(album: album),
                  missingTitle: 'Album not found',
                  missingSubtitle:
                      'It may have been removed, or its server is offline.',
                ),
              );
            },
          ),
          GoRoute(
            path: artistDetail,
            name: 'artistDetail',
            pageBuilder: (context, state) {
              final artist = state.extra is Artist
                  ? state.extra as Artist
                  : null;
              return _fadePage(
                context: context,
                state: state,
                child: EntityRoute<Artist>(
                  entity: artist,
                  entityId: artist?.id ?? _idParam(state),
                  lookup: (library, id) =>
                      library.artists.where((a) => a.id == id).firstOrNull,
                  builder: (artist) => ArtistDetailPage(artist: artist),
                  missingTitle: 'Artist not found',
                  missingSubtitle:
                      'They may have been removed, or their server is offline.',
                ),
              );
            },
          ),
          GoRoute(
            path: playlistManagement,
            name: 'playlistManagement',
            pageBuilder: (context, state) => _fadePage(
              context: context,
              state: state,
              child: const PlaylistManagementPage(),
            ),
          ),
          GoRoute(
            path: playlistDetail,
            name: 'playlistDetail',
            pageBuilder: (context, state) {
              final playlistId = state.uri.queryParameters['id'] ?? '';
              return _fadePage(
                context: context,
                state: state,
                child: PlaylistDetailPage(playlistId: playlistId),
              );
            },
          ),
          // Inside the shell so the queue's glass surfaces sit on the art
          // tint like every other page; the full-screen player stays outside
          // because it paints its own background.
          GoRoute(
            path: queue,
            name: 'queue',
            pageBuilder: (context, state) => _fadePage(
              context: context,
              state: state,
              child: const QueuePage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: nowPlaying,
        name: 'nowPlaying',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: NowPlayingPage(initialPanel: state.extra as NowPlayingPanel?),
          transitionDuration: AnimationUtils.adjustedDuration(
            context,
            const Duration(milliseconds: 300),
          ),
          reverseTransitionDuration: AnimationUtils.adjustedDuration(
            context,
            const Duration(milliseconds: 300),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide up when entering, slide down when exiting
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),
    ],
  );

  static CustomTransitionPage<void> _fadePage({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    final duration = AnimationUtils.adjustedDuration(
      context,
      AnimationConstants.quickAnimation,
    );
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: AnimationConstants.smoothCurve,
          ),
          child: child,
        );
      },
    );
  }
}
