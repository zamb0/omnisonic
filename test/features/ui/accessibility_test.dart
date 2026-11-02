import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/routing/app_router.dart';
import 'package:omnisonic/features/ui/presentation/pages/favorites_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/home_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/library_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/settings_page.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// Explicit `Semantics` appeared in two files in the whole app, and nothing
/// had ever been run through Flutter's own accessibility guidelines. These
/// ship with flutter_test and cover tap-target size, labelling and text
/// contrast for the entire rendered tree, which is a great deal of coverage
/// for very little code.
void main() {
  TestViewModels populated() {
    final models = TestViewModels();
    models.servers.emitServers([testServer()]);
    models.library.emitCollection(
      tracks: testTracks(8),
      albums: testAlbums(8),
      artists: testArtists(4),
    );
    models.library.emitSmartCollections(
      recentlyPlayed: testTracks(3),
      recentlyAddedAlbums: testAlbums(4),
    );
    models.library.emitStarred(
      albums: testAlbums(3),
      artists: testArtists(2),
      tracks: testTracks(4),
    );
    models.playlists.emitPlaylists([testPlaylist()]);
    models.playback.emitPlaying(testTrack());
    return models;
  }

  group('guidelines', () {
    Future<void> check(WidgetTester tester, Widget page) async {
      final handle = tester.ensureSemantics();
      await pumpPage(
        tester,
        page,
        viewModels: populated(),
        size: TestSizes.phone,
        settle: false,
      );
      await tester.pump();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    }

    testWidgets('Home', (tester) async => check(tester, HomePage()));

    testWidgets(
      'Starred',
      (tester) async => check(tester, const FavoritesPage()),
    );

    testWidgets(
      'Settings',
      (tester) async => check(tester, const SettingsPage()),
    );

    testWidgets('the shell chrome', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpShell(
        tester,
        viewModels: populated(),
        size: TestSizes.phone,
        settle: false,
      );
      await tester.pump();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('Library', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpShell(
        tester,
        location: AppRouter.library,
        viewModels: populated(),
        size: TestSizes.phone,
        settle: false,
        routes: testShellRoutes(
          builders: {
            AppRouter.library: (context, state) => const LibraryPage(),
          },
        ),
      );
      await tester.pump();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('navigation state is announced', () {
    testWidgets('the current destination reports as selected', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpShell(
        tester,
        location: AppRouter.library,
        viewModels: populated(),
        size: TestSizes.phone,
        settle: false,
        routes: testShellRoutes(
          builders: {
            AppRouter.library: (context, state) =>
                const Scaffold(body: SizedBox.shrink()),
          },
        ),
      );
      await tester.pump();

      // Colour alone does not reach a screen reader, so the pill has to
      // carry the selected flag as well as the tint.
      final library = tester.getSemantics(find.text('Library'));
      expect(library.flagsCollection.isSelected, Tristate.isTrue);

      handle.dispose();
    });
  });
}
