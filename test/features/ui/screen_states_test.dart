import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/features/ui/presentation/pages/favorites_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/home_page.dart';
import 'package:omnisonic/core/routing/app_router.dart';
import 'package:omnisonic/features/ui/presentation/pages/library_page.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// Before this, every screen invented its own answer to "we're loading",
/// "that failed" and "there's nothing here": bare spinners on three screens,
/// shimmer on one, `Center(Text('No offline albums available'))` on four,
/// errors as a SnackBar that vanished after three seconds on one, and no
/// error branch at all on two.
///
/// These tests are what stops that drifting back. Adding a screen without a
/// skeleton, or with an error the user can't retry, fails here.
void main() {
  /// LibraryPage reads GoRouterState for its `?tab=` parameter, so it has to
  /// be pumped inside a router rather than on its own.
  Future<void> pumpLibrary(WidgetTester tester, TestViewModels models) =>
      pumpShell(
        tester,
        location: AppRouter.library,
        viewModels: models,
        settle: false,
        routes: testShellRoutes(
          builders: {
            AppRouter.library: (context, state) => const LibraryPage(),
          },
        ),
      );

  TestViewModels loaded() {
    final models = TestViewModels();
    models.servers.emitServers([testServer()]);
    models.library.emitCollection(
      tracks: testTracks(6),
      albums: testAlbums(6),
      artists: testArtists(3),
    );
    return models;
  }

  group('Library', () {
    testWidgets('loading shows a skeleton, not a spinner', (tester) async {
      final models = TestViewModels();
      models.servers.emitServers([testServer()]);
      models.library.emitLoading();

      await pumpLibrary(tester, models);

      expect(find.byType(SkeletonCard), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a failure renders inline with a working retry', (
      tester,
    ) async {
      final models = loaded();
      models.library.emitError('Server unreachable');

      await pumpLibrary(tester, models);

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Server unreachable'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();

      expect(models.library.syncCallCount, 1);
    });

    testWidgets('an empty library offers a way out', (tester) async {
      final models = TestViewModels();
      models.servers.emitServers([testServer()]);
      models.library.emitCollection();

      await pumpLibrary(tester, models);

      expect(find.byType(EmptyState), findsWidgets);
    });
  });

  group('Starred', () {
    testWidgets('loading shows a skeleton', (tester) async {
      final models = TestViewModels();
      models.library.emitLoading();

      await pumpPage(
        tester,
        const FavoritesPage(),
        viewModels: models,
        settle: false,
      );

      expect(find.byType(SkeletonCard), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a failure renders inline with a retry', (tester) async {
      final models = TestViewModels();
      models.library.emitError('Nope');

      await pumpPage(
        tester,
        const FavoritesPage(),
        viewModels: models,
        settle: false,
      );

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('empty explains what to do', (tester) async {
      final models = TestViewModels();
      models.library.emitStarred();

      await pumpPage(tester, const FavoritesPage(), viewModels: models);

      expect(find.text('No Starred Albums'), findsOneWidget);
    });
  });

  group('Home', () {
    testWidgets('a still-syncing feed shows skeleton carousels', (
      tester,
    ) async {
      // The sections used to return SizedBox.shrink() while empty, so a
      // first sync looked like an app with no content rather than one that
      // was still working.
      final models = TestViewModels();
      models.servers.emitServers([testServer()]);
      models.library.emitSyncing(true);

      await pumpPage(
        tester,
        HomePage(random: null),
        viewModels: models,
        settle: false,
      );

      expect(find.byType(SkeletonCard), findsWidgets);
    });

    testWidgets('a failed refresh is surfaced above the feed, not instead of '
        'it', (tester) async {
      final models = loaded();
      models.library.emitSmartCollections(recentlyAddedAlbums: testAlbums(4));
      models.library.emitError('Sync failed');

      await pumpPage(
        tester,
        HomePage(random: null),
        viewModels: models,
        settle: false,
      );

      expect(find.text('Sync failed'), findsOneWidget);
      // The content that did load is still on screen.
      expect(find.text('Recently Added'), findsOneWidget);
    });
  });

  group('the vocabulary itself', () {
    testWidgets('an error always carries a retry', (tester) async {
      await pumpPage(
        tester,
        ErrorStateView(message: 'Broke', onRetry: () {}),
        settle: false,
      );

      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('skeletons hold still under reduced motion', (tester) async {
      // A looping shimmer is exactly what this accessibility setting is
      // about, so the sweep parks at a midpoint instead.
      await pumpPage(
        tester,
        const LoadingStateView(kind: SkeletonKind.list),
        disableAnimations: true,
      );

      // pumpAndSettle inside pumpPage would time out on a live repeat().
      expect(tester.takeException(), isNull);
      expect(find.byType(SkeletonBox), findsWidgets);
    });

    for (final kind in SkeletonKind.values) {
      testWidgets('the $kind skeleton renders without overflowing', (
        tester,
      ) async {
        await pumpPage(tester, LoadingStateView(kind: kind), settle: false);

        expect(tester.takeException(), isNull);
        expect(find.byType(SkeletonBox), findsWidgets);
      });

      // The shimmer sweeps, so the golden is taken with reduced motion on:
      // that parks it at a fixed midpoint and makes the frame reproducible.
      testWidgets('the $kind skeleton matches its golden', (tester) async {
        // Inside a Scaffold, because the skeleton's greys are chosen
        // against the theme's surface — on a bare white canvas they read as
        // near-black slabs, which is a harness artifact, not the design.
        await pumpPage(
          tester,
          Scaffold(body: LoadingStateView(kind: kind)),
          disableAnimations: true,
        );

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/skeleton_${kind.name}.png'),
        );
      });
    }
  });
}
