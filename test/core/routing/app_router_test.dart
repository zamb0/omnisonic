import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/routing/app_router.dart';
import 'package:omnisonic/core/routing/entity_route.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';
import 'package:omnisonic/features/music/presentation/viewmodels/music_library_view_model.dart';
import 'package:provider/provider.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/view_model_fakes.dart';

/// The album and artist detail routes used to read `state.extra` through an
/// unconditional non-nullable cast. Anything that isn't an in-app tap — a
/// deep link, a restored window, a hot restart on that route — arrives with
/// a null `extra` and threw `_TypeError` before the page ever built.
void main() {
  late FakeMusicLibraryViewModel library;

  setUp(() => library = FakeMusicLibraryViewModel());

  /// Mirrors how the real router builds the detail routes, minus the pages
  /// themselves — those need six more providers and aren't what's under test.
  GoRouter buildRouter({String initialLocation = AppRouter.home}) {
    return GoRouter(
      initialLocation: initialLocation,
      errorBuilder: (context, state) =>
          NotFoundPage(location: state.uri.toString()),
      routes: [
        GoRoute(
          path: AppRouter.home,
          builder: (context, state) => const Text('home'),
        ),
        GoRoute(
          path: AppRouter.library,
          builder: (context, state) => const Text('library'),
        ),
        GoRoute(
          path: AppRouter.albumDetail,
          builder: (context, state) {
            final album = state.extra is Album ? state.extra as Album : null;
            return EntityRoute<Album>(
              entity: album,
              entityId: album?.id ?? state.uri.queryParameters['id'] ?? '',
              lookup: (library, id) =>
                  library.albums.where((a) => a.id == id).firstOrNull,
              builder: (album) => Text('album:${album.title}'),
              missingTitle: 'Album not found',
              missingSubtitle: 'gone',
            );
          },
        ),
      ],
    );
  }

  Future<GoRouter> pumpRouter(
    WidgetTester tester, {
    String initialLocation = AppRouter.home,
    // A spinner never settles, so a test that expects one has to stop at a
    // fixed number of frames instead.
    bool settle = true,
  }) async {
    final router = buildRouter(initialLocation: initialLocation);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<MusicLibraryViewModel>.value(
        value: library,
        child: MaterialApp.router(
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return router;
  }

  testWidgets('a detail route with no extra and no id does not crash', (
    tester,
  ) async {
    library.emitCollection(albums: testAlbums(3));

    await pumpRouter(tester, initialLocation: AppRouter.albumDetail);

    expect(tester.takeException(), isNull);
    expect(find.text('Album not found'), findsOneWidget);
  });

  testWidgets('a deep link resolves the album from its id alone', (
    tester,
  ) async {
    library.emitCollection(albums: testAlbums(3));

    await pumpRouter(
      tester,
      initialLocation: AppRouter.albumDetailLocation('server1_a2'),
    );

    expect(find.text('album:Album 2'), findsOneWidget);
  });

  testWidgets('an id with an underscore-bearing subsonic part survives the '
      'round trip', (tester) async {
    // Subsonic ids may themselves contain underscores, so the unique id has
    // more than one. Encoding has to leave it intact.
    final album = testAlbum(id: 'server1_al_2024_x', title: 'Underscored');
    library.emitCollection(albums: [album]);

    await pumpRouter(
      tester,
      initialLocation: AppRouter.albumDetailLocation(album.id),
    );

    expect(find.text('album:Underscored'), findsOneWidget);
  });

  testWidgets('a deep link waits for the collection instead of reporting the '
      'album missing', (tester) async {
    // Nothing emitted yet: the app is still starting up.
    await pumpRouter(
      tester,
      initialLocation: AppRouter.albumDetailLocation('server1_a2'),
      settle: false,
    );

    expect(find.byType(LoadingStateView), findsOneWidget);
    expect(find.text('Album not found'), findsNothing);

    library.emitCollection(albums: testAlbums(3));
    await tester.pump();

    expect(find.text('album:Album 2'), findsOneWidget);
  });

  testWidgets('an album that is genuinely absent reports as missing', (
    tester,
  ) async {
    library.emitCollection(albums: testAlbums(3));

    await pumpRouter(
      tester,
      initialLocation: AppRouter.albumDetailLocation('server9_nope'),
    );

    expect(find.text('Album not found'), findsOneWidget);
  });

  testWidgets('an in-app tap still renders straight from the passed entity', (
    tester,
  ) async {
    // Collection deliberately left empty: passing the entity means no lookup
    // is needed, which is the whole point of `extra`.
    final router = await pumpRouter(tester);
    router.push(
      AppRouter.albumDetailLocation('server1_a1'),
      extra: testAlbum(title: 'Handed Over'),
    );
    await tester.pumpAndSettle();

    expect(find.text('album:Handed Over'), findsOneWidget);
  });

  testWidgets('an unknown path lands on the not-found page', (tester) async {
    await pumpRouter(tester, initialLocation: '/no-such-page');

    expect(tester.takeException(), isNull);
    expect(find.text('Page not found'), findsOneWidget);
    expect(find.textContaining('/no-such-page'), findsOneWidget);
  });
}
