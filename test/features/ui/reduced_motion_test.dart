import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/features/playback/presentation/widgets/audio_visualizer.dart';
import 'package:omnisonic/features/ui/presentation/pages/favorites_page.dart';
import 'package:omnisonic/features/ui/presentation/pages/home_page.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// `pumpAndSettle` completing is the assertion here: it throws if anything
/// is still animating after its timeout, so a page that settles under
/// reduced motion has no loops left running.
///
/// The audio visualizer was the notable offender — a continuously repeating
/// controller with no guard at all, which is exactly what this accessibility
/// setting is asking about.
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
    models.library.emitStarred(albums: testAlbums(3));
    models.playback.emitPlaying(testTrack());
    return models;
  }

  testWidgets('the audio visualizer stops looping', (tester) async {
    await pumpPage(
      tester,
      const Center(
        child: SizedBox(
          width: 200,
          height: 100,
          child: AudioVisualizer(isPlaying: true),
        ),
      ),
      disableAnimations: true,
    );

    // Would time out if the bars were still cycling.
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the visualizer still animates when motion is allowed', (
    tester,
  ) async {
    // The counterpart: without this, the test above would pass just as well
    // if the visualizer never animated at all.
    await pumpPage(
      tester,
      const Center(
        child: SizedBox(
          width: 200,
          height: 100,
          child: AudioVisualizer(isPlaying: true),
        ),
      ),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      () => tester.pumpAndSettle(const Duration(milliseconds: 50)),
      throwsA(isA<FlutterError>()),
    );
  });

  testWidgets('skeletons stop sweeping', (tester) async {
    await pumpPage(
      tester,
      const Scaffold(body: LoadingStateView(kind: SkeletonKind.grid)),
      disableAnimations: true,
    );

    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
  });

  for (final (name, page) in [
    ('Home', HomePage()),
    ('Starred', const FavoritesPage()),
  ]) {
    testWidgets('$name settles under reduced motion', (tester) async {
      await pumpPage(
        tester,
        page,
        viewModels: populated(),
        disableAnimations: true,
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    });
  }
}
