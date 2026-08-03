import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/routing/app_router.dart';
import 'package:omnisonic/features/ui/presentation/pages/home_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/library_page.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// Locks the current look of the shell at each of its three chrome modes.
///
/// These exist to make the UX overhaul reviewable: any phase that changes
/// spacing, icons, type or layout will fail these, and the image diff is the
/// review artifact. They are not assertions about what the design *should*
/// be — regenerate with `flutter test --update-goldens` once a change has
/// been looked at and is intended.
void main() {
  TestViewModels populatedModels() {
    final models = TestViewModels();
    models.servers.emitServers([
      testServer(name: 'Living Room', lastSync: DateTime(2026, 1, 1)),
      testServer(id: 'server2', name: 'Backup', lastSync: DateTime(2026, 1, 1)),
    ]);
    models.library.emitCollection(
      tracks: testTracks(24),
      albums: testAlbums(18),
      artists: testArtists(9),
    );
    models.library.emitSmartCollections(
      recentlyPlayed: testTracks(6),
      recentlyAdded: testTracks(6),
      mostPlayed: testTracks(6),
      recentlyAddedAlbums: testAlbums(8),
      recentlyPlayedAlbums: testAlbums(8),
      mostPlayedAlbums: testAlbums(8),
    );
    models.playlists.emitPlaylists([
      testPlaylist(name: 'Morning'),
      testPlaylist(id: 'server1_p2', name: 'Focus', isPublic: true),
    ]);
    models.playback.emitPlaying(
      testTrack(title: 'Now Playing Track', artist: 'Someone'),
      position: const Duration(seconds: 42),
    );
    return models;
  }

  Future<void> pumpAt(
    WidgetTester tester, {
    required String location,
    required Size size,
    required Widget page,
  }) => pumpShell(
    tester,
    location: location,
    size: size,
    viewModels: populatedModels(),
    routes: testShellRoutes(builders: {location: (context, state) => page}),
  );

  testWidgets('home at phone width (bottom bar)', (tester) async {
    await pumpAt(
      tester,
      location: AppRouter.home,
      size: TestSizes.phone,
      page: HomePage(random: Random(7)),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_phone.png'),
    );
  });

  testWidgets('library at tablet width (collapsed rail)', (tester) async {
    await pumpAt(
      tester,
      location: AppRouter.library,
      size: TestSizes.tablet,
      page: const LibraryPage(),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/library_tablet.png'),
    );
  });

  testWidgets('home at desktop width (extended sidebar)', (tester) async {
    await pumpAt(
      tester,
      location: AppRouter.home,
      size: TestSizes.desktop,
      page: HomePage(random: Random(7)),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_desktop.png'),
    );
  });
}
