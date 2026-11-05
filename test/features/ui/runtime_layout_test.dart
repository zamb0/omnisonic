import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/di/injection_container.dart';
import 'package:omnisonic/core/routing/app_router.dart';
import 'package:omnisonic/core/services/deduplication_engine.dart';
import 'package:omnisonic/features/playback/presentation/widgets/full_screen_player.dart';
import 'package:omnisonic/features/playback/presentation/widgets/transport_controls.dart';
import 'package:omnisonic/features/ui/presentation/pages/album_detail_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/home_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/library_page.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// #70: the sizes the runtime review used — a 390x844 phone, the same phone
/// on its side, and 2x text — with a track playing, so the mini player is
/// part of every layout.
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
    final tracks = testTracks(12);
    models.library.emitCollection(
      tracks: tracks,
      albums: testAlbums(12),
      artists: testArtists(6),
    );
    models.playback.emitPlaying(tracks.first, queue: tracks);
    return models;
  }

  const sizes = {
    '390x844': Size(390, 844),
    'landscape 844x390': Size(844, 390),
  };

  final shellPages = <String, (String, Widget Function())>{
    'Home': (AppRouter.home, () => const HomePage()),
    'Album': (
      AppRouter.albumDetail,
      () => AlbumDetailPage(
        album: testAlbum(title: 'An album title long enough to wrap twice'),
      ),
    ),
  };

  for (final MapEntry(key: sizeName, value: size) in sizes.entries) {
    for (final scale in [1.0, 2.0]) {
      for (final MapEntry(key: name, value: (path, build))
          in shellPages.entries) {
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

      testWidgets('Now Playing at $sizeName, ${scale}x text', (tester) async {
        await pumpPage(
          tester,
          const FullScreenPlayer(),
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

  testWidgets('Home and Library share the same gutter', (tester) async {
    Future<double> titleLeft(String path, Widget page, String title) async {
      await pumpShell(
        tester,
        location: path,
        routes: testShellRoutes(builders: {path: (_, _) => page}),
        viewModels: populated(),
        size: const Size(390, 844),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 500));
      return tester.getTopLeft(find.text(title).first).dx;
    }

    final home = await titleLeft(AppRouter.home, const HomePage(), 'Home');
    final library = await titleLeft(
      AppRouter.library,
      const LibraryPage(),
      'Library',
    );
    expect(home, library);
  });

  testWidgets('the mini player drops previous below 420pt', (tester) async {
    await pumpShell(
      tester,
      routes: testShellRoutes(
        builders: {AppRouter.home: (_, _) => const HomePage()},
      ),
      viewModels: populated(),
      size: const Size(390, 844),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SkipPreviousButton), findsNothing);
    expect(find.byType(SkipNextButton), findsOneWidget);
  });

  testWidgets('Now Playing shows shuffle and repeat without scrolling', (
    tester,
  ) async {
    await pumpPage(
      tester,
      const FullScreenPlayer(),
      viewModels: populated(),
      size: const Size(390, 844),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 500));

    for (final type in [ShuffleModeButton, RepeatModeButton]) {
      expect(tester.getBottomLeft(find.byType(type).first).dy, lessThan(844));
    }
  });
}
