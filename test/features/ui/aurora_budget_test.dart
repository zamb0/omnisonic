import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/core/di/injection_container.dart';
import 'package:omnisonic/core/routing/app_router.dart';
import 'package:omnisonic/core/services/deduplication_engine.dart';
import 'package:omnisonic/features/music/presentation/pages/playlist_detail_page.dart';
import 'package:omnisonic/features/music/presentation/pages/playlist_management_page.dart';
import 'package:omnisonic/features/playback/presentation/widgets/animated_now_playing_bar.dart';
import 'package:omnisonic/features/servers/presentation/pages/server_management_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/album_detail_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/artist_detail_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/favorites_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/home_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/library_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/settings_page.dart';
import 'package:omnisonic/features/ui/presentation/widgets/media_card.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// docs/design-system.md §1: at most one filled Aurora element per screen.
///
/// The static check in `token_guardrail_test.dart` only counts the literal
/// `AuroraButton(` in page files; it cannot see a `PlayDisc`, nor one built
/// by a shared widget such as the detail header. This pumps each page in the
/// real shell, with a track playing, and counts what is actually on screen.
///
/// Not counted, as the spec allows:
/// - the persistent player (mini player / transport bar): chrome, present on
///   every screen while something plays;
/// - the `PlayDisc` of a [MediaCard]: revealed only on hover or focus.
void main() {
  setUp(() {
    if (!getIt.isRegistered<DeduplicationEngine>()) {
      getIt.registerSingleton<DeduplicationEngine>(DeduplicationEngine());
    }
  });

  tearDown(() {
    if (getIt.isRegistered<DeduplicationEngine>()) {
      getIt.unregister<DeduplicationEngine>();
    }
  });

  TestViewModels populated({bool withServers = true}) {
    final models = TestViewModels();
    if (withServers) {
      models.servers.emitServers([
        testServer(name: 'Living Room'),
        testServer(id: 'server2', name: 'Backup'),
      ]);
      models.library.emitCollection(
        tracks: testTracks(12),
        albums: testAlbums(12),
        artists: testArtists(6),
      );
      models.library.emitSmartCollections(
        recentlyPlayed: testTracks(6),
        recentlyAdded: testTracks(6),
        mostPlayed: testTracks(6),
        recentlyAddedAlbums: testAlbums(8),
        recentlyPlayedAlbums: testAlbums(8),
        mostPlayedAlbums: testAlbums(8),
      );
      models.library.emitStarred(
        albums: testAlbums(4),
        artists: testArtists(3),
        tracks: testTracks(5),
      );
      final playlist = testPlaylist(name: 'Morning');
      models.playlists.emitPlaylists([playlist]);
      models.playlists.emitSelected(playlist, tracks: testTracks(6));
    }
    models.playback.emitPlaying(testTrack(title: 'Now Playing Track'));
    return models;
  }

  final pages = <String, (String, Widget Function(), bool)>{
    'Home': (AppRouter.home, () => HomePage(random: Random(7)), true),
    'Home, first run': (
      AppRouter.home,
      () => HomePage(random: Random(7)),
      false,
    ),
    'Library': (AppRouter.library, () => const LibraryPage(), true),
    'Starred': (AppRouter.favorites, () => const FavoritesPage(), true),
    'Playlists': (
      AppRouter.playlistManagement,
      () => const PlaylistManagementPage(),
      true,
    ),
    'Playlist': (
      AppRouter.playlistDetail,
      () => PlaylistDetailPage(playlistId: testPlaylist().id),
      true,
    ),
    'Servers': (AppRouter.servers, () => const ServerManagementPage(), true),
    'Servers, none': (
      AppRouter.servers,
      () => const ServerManagementPage(),
      false,
    ),
    'Settings': (AppRouter.settings, () => const SettingsPage(), true),
    'Album': (
      AppRouter.albumDetail,
      () => AlbumDetailPage(album: testAlbum()),
      true,
    ),
    'Artist': (
      AppRouter.artistDetail,
      () => ArtistDetailPage(artist: testArtists(1).single),
      true,
    ),
  };

  const sizes = {'phone': TestSizes.phone, 'desktop': Size(1440, 900)};

  int auroraOnScreen(WidgetTester tester) {
    final exempt = [find.byType(AnimatedNowPlayingBar), find.byType(MediaCard)];
    final filled = find.byWidgetPredicate(
      (w) => w is AuroraButton || w is PlayDisc,
    );
    return filled.evaluate().where((element) {
      for (final finder in exempt) {
        final inside = find.descendant(
          of: finder,
          matching: find.byWidget(element.widget),
        );
        if (inside.evaluate().contains(element)) return false;
      }
      return true;
    }).length;
  }

  for (final MapEntry(key: name, value: (path, build, servers))
      in pages.entries) {
    for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
      testWidgets('$name at $sizeName: at most one Aurora element', (
        tester,
      ) async {
        await pumpShell(
          tester,
          location: path,
          routes: testShellRoutes(builders: {path: (_, _) => build()}),
          viewModels: populated(withServers: servers),
          size: size,
          settle: false,
        );
        await tester.pump(const Duration(milliseconds: 500));

        expect(auroraOnScreen(tester), lessThanOrEqualTo(1));
      });
    }
  }
}
