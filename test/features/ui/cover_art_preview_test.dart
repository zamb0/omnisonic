import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/features/playback/presentation/widgets/full_screen_player.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// Now Playing's cover flies up from the player bar's thumbnail. It used to
/// size its request from the layout, so during the Hero flight it walked up
/// the size buckets (fetching and decoding each), and until its large copy
/// arrived it showed the gradient placeholder — a coloured square mid-air.
void main() {
  const cover = 'https://music.example.test/rest/getCoverArt?id=al-1&size=1000';

  Iterable<String> requestedUrls(WidgetTester tester) => tester
      .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
      .map((image) => image.imageUrl);

  testWidgets('a cover shows its preview size while its own size loads', (
    tester,
  ) async {
    await pumpPage(
      tester,
      const Center(
        child: CoverArt(
          url: cover,
          size: 200,
          requestSize: 1000,
          previewRequestSize: 128,
        ),
      ),
      settle: false,
    );

    final urls = requestedUrls(tester);
    // The server caps covers at 512.
    expect(urls.any((u) => u.contains('size=512')), isTrue);
    expect(urls.any((u) => u.contains('size=128')), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Now Playing pins its cover request to the resting size', (
    tester,
  ) async {
    final models = TestViewModels();
    // No artwork URL: only the CoverArt's configuration is under test, and
    // a real URL leaves the image loader's timers behind.
    final track = testTrack();
    models.playback.emitPlaying(track);
    await pumpPage(
      tester,
      const FullScreenPlayer(),
      viewModels: models,
      size: TestSizes.desktop,
      settle: false,
      disableAnimations: true,
    );
    await tester.pump(const Duration(milliseconds: 500));

    final hero = tester.widget<CoverArt>(
      find.descendant(of: find.byType(Hero), matching: find.byType(CoverArt)),
    );
    expect(hero.requestSize, isNotNull);
    expect(
      hero.previewRequestSize,
      CoverArt.requestSizeFor(
        tester.element(find.byType(Hero)),
        FullScreenPlayer.barArtworkSize,
      ),
    );
  });
}
