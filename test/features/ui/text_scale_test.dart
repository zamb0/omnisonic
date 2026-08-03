import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/core/di/injection_container.dart';
import 'package:omnisonic/core/routing/app_router.dart';
import 'package:omnisonic/core/services/deduplication_engine.dart';
import 'package:omnisonic/features/music/presentation/bloc/search_bloc.dart';
import 'package:omnisonic/features/ui/presentation/pages/favorites_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/home_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/library_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/search_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/settings_page.dart';

import '../../helpers/bloc_fakes.dart';
import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// The app had no dynamic-type support of any kind: `textScaler` appeared
/// nowhere in lib/, every size was a fixed logical pixel value, and no test
/// had ever pumped a page above 1x. Overflow at large text is the default
/// state of an app in that position, so this sweep is the point.
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
      testServer(),
      testServer(id: 'server2', name: 'Backup'),
    ]);
    models.library.emitCollection(
      tracks: testTracks(12),
      albums: testAlbums(12),
      artists: testArtists(6),
    );
    models.library.emitSmartCollections(
      recentlyPlayed: testTracks(4),
      recentlyAddedAlbums: testAlbums(6),
      recentlyPlayedAlbums: testAlbums(6),
      mostPlayedAlbums: testAlbums(6),
    );
    models.library.emitStarred(
      albums: testAlbums(4),
      artists: testArtists(3),
      tracks: testTracks(5),
    );
    models.playlists.emitPlaylists([testPlaylist()]);
    models.playback.emitPlaying(testTrack(title: 'A Long Track Title Here'));
    return models;
  }

  // 1.0 is the baseline, 1.3 is where the shell's chrome stops growing, and
  // 2.0 is roughly the largest system setting on both platforms.
  const scales = [1.0, 1.3, 2.0];

  /// Pages that stand alone, without needing the router or a bloc.
  final standalonePages = <String, Widget Function()>{
    'Starred': () => const FavoritesPage(),
    'Home': () => const HomePage(),
    'Settings': () => const SettingsPage(),
  };

  for (final scale in scales) {
    group('at ${scale}x', () {
      standalonePages.forEach((name, build) {
        for (final size in [TestSizes.smallPhone, TestSizes.desktop]) {
          testWidgets('$name lays out at ${size.width.toInt()}px', (
            tester,
          ) async {
            await pumpPage(
              tester,
              build(),
              viewModels: populated(),
              size: size,
              textScale: scale,
              settle: false,
            );
            await tester.pump();

            expect(tester.takeException(), isNull);
          });
        }
      });

      testWidgets('Library lays out', (tester) async {
        await pumpShell(
          tester,
          location: AppRouter.library,
          viewModels: populated(),
          size: TestSizes.smallPhone,
          textScale: scale,
          settle: false,
          routes: testShellRoutes(
            builders: {
              AppRouter.library: (context, state) => const LibraryPage(),
            },
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('Search lays out with results', (tester) async {
        final bloc = FakeSearchBloc(
          SearchStates.success(
            tracks: [
              testTrack(
                id: 'server1_a',
                title: 'A Really Quite Long Track Title',
                duration: const Duration(minutes: 4),
              ),
              testTrack(
                id: 'server1_b',
                title: 'Another Long One Entirely',
                artist: 'A Band With A Long Name',
                duration: const Duration(minutes: 9),
              ),
            ],
            albums: testAlbums(4),
            artists: testArtists(4),
          ),
        );
        addTearDown(bloc.close);

        await pumpPage(
          tester,
          BlocProvider<SearchBloc>.value(
            value: bloc,
            child: const SearchPage(),
          ),
          viewModels: populated(),
          size: TestSizes.smallPhone,
          textScale: scale,
          settle: false,
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('the shell chrome lays out', (tester) async {
        await pumpShell(
          tester,
          viewModels: populated(),
          size: TestSizes.smallPhone,
          textScale: scale,
          settle: false,
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    });
  }

  group('the chrome clamp', () {
    testWidgets('leaves scales at or below the cap alone', (tester) async {
      late double observed;

      await pumpPage(
        tester,
        Builder(
          builder: (context) => OmnisonicTextScale.clampChrome(
            context,
            Builder(
              builder: (inner) {
                observed = MediaQuery.textScalerOf(inner).scale(1);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        textScale: 1.2,
      );

      expect(observed, closeTo(1.2, 0.001));
    });

    testWidgets('caps anything above it', (tester) async {
      late double observed;

      await pumpPage(
        tester,
        Builder(
          builder: (context) => OmnisonicTextScale.clampChrome(
            context,
            Builder(
              builder: (inner) {
                observed = MediaQuery.textScalerOf(inner).scale(1);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        textScale: 2.4,
      );

      expect(observed, OmnisonicTextScale.chromeMax);
    });

    testWidgets('content outside the clamp keeps the full scale', (
      tester,
    ) async {
      // The clamp exists to protect fixed chrome, not to override the
      // accessibility setting for the things the user is trying to read.
      late double observed;

      await pumpPage(
        tester,
        Builder(
          builder: (context) {
            observed = MediaQuery.textScalerOf(context).scale(1);
            return const SizedBox.shrink();
          },
        ),
        textScale: 2.4,
      );

      expect(observed, closeTo(2.4, 0.001));
    });
  });
}
