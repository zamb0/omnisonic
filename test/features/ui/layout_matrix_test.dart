import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/di/injection_container.dart';
import 'package:omnisonic/core/routing/app_router.dart';
import 'package:omnisonic/core/services/deduplication_engine.dart';
import 'package:omnisonic/features/music/presentation/pages/playlist_detail_page.dart';
import 'package:omnisonic/features/music/presentation/pages/playlist_management_page.dart';
import 'package:omnisonic/features/servers/presentation/pages/server_management_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/album_detail_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/artist_detail_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/favorites_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/library_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/settings_page.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// #54: the pages this epic touched, on the smallest supported phone, a
/// landscape phone, and at 1.3x and 2x text — no overflow anywhere.
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

  TestViewModels populated() {
    final models = TestViewModels();
    models.servers.emitServers([
      testServer(name: 'A server with a rather long name'),
      testServer(id: 'server2', name: 'Backup'),
    ]);
    models.library.emitCollection(
      tracks: testTracks(12),
      albums: testAlbums(12),
      artists: testArtists(6),
    );
    models.library.emitStarred(
      albums: testAlbums(4),
      artists: testArtists(3),
      tracks: testTracks(5),
    );
    final playlist = testPlaylist(name: 'Songs for a very long drive home');
    models.playlists.emitPlaylists([playlist]);
    models.playlists.emitSelected(playlist, tracks: testTracks(6));
    return models;
  }

  // Each page is pumped inside the real shell at its own route, so the
  // chrome (bottom bar or rail, mini player) is part of the layout checked.
  final pages = <String, (String, Widget Function())>{
    'Library': (AppRouter.library, () => const LibraryPage()),
    'Starred': (AppRouter.favorites, () => const FavoritesPage()),
    'Playlists': (
      AppRouter.playlistManagement,
      () => const PlaylistManagementPage(),
    ),
    'Playlist': (
      AppRouter.playlistDetail,
      () => PlaylistDetailPage(playlistId: testPlaylist().id),
    ),
    'Servers': (AppRouter.servers, () => const ServerManagementPage()),
    'Settings': (AppRouter.settings, () => const SettingsPage()),
    'Album': (
      AppRouter.albumDetail,
      () => AlbumDetailPage(
        album: testAlbum(title: 'An album title long enough to wrap twice'),
      ),
    ),
    'Artist': (
      AppRouter.artistDetail,
      () => ArtistDetailPage(artist: testArtists(1).single),
    ),
  };

  const sizes = {
    '360x640': Size(360, 640),
    'landscape 740x360': Size(740, 360),
  };

  for (final MapEntry(key: name, value: (path, build)) in pages.entries) {
    for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('$name at $sizeName, ${scale}x text', (tester) async {
          await pumpShell(
            tester,
            location: path,
            routes: testShellRoutes(builders: {path: (_, _) => build()}),
            viewModels: populated(),
            size: size,
            textScale: scale,
            settle: false,
          );
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
