import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/features/ui/presentation/widgets/album_card.dart';
import 'package:omnisonic/features/ui/presentation/widgets/media_card.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// MediaCard replaced FeishinCard and the Home page's own hover card. Covers
/// the regressions from #53 (points 2 and 3) and the touch, keyboard and
/// screen-reader paths from #55/#60.
void main() {
  Future<void> pumpCard(WidgetTester tester, Widget card) => pumpPage(
    tester,
    Center(child: SizedBox(width: 200, height: 260, child: card)),
    settle: false,
  );

  testWidgets('hidden hover overlay does not take taps on touch', (
    tester,
  ) async {
    var stars = 0;
    var taps = 0;
    var plays = 0;
    await pumpCard(
      tester,
      MediaCard(
        title: 'Album',
        onTap: () => taps++,
        onStar: () => stars++,
        onPlay: () => plays++,
        onShuffle: () {},
      ),
    );

    final art = tester.getRect(find.byType(AspectRatio).first);
    for (final dx in [-48.0, -24.0, 0.0, 24.0, 48.0]) {
      await tester.tapAt(art.center + Offset(dx, 0));
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(stars, 0);
    expect(plays, 0);
    expect(taps, 5);
  });

  testWidgets('card lays out in a Wrap, where height is unbounded', (
    tester,
  ) async {
    await pumpPage(
      tester,
      SingleChildScrollView(
        child: Wrap(
          spacing: 12,
          children: [
            for (final album in testAlbums(4))
              SizedBox(
                width: 96,
                child: AlbumCard(album: album, width: 96, showMeta: false),
              ),
          ],
        ),
      ),
      settle: false,
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AspectRatio).first), const Size(96, 96));
  });

  testWidgets('long press and right-click show the actions', (tester) async {
    var shown = 0;
    await pumpCard(
      tester,
      MediaCard(title: 'Album', onTap: () {}, onShowActions: () => shown++),
    );

    await tester.longPress(find.text('Album'));
    await tester.pump();
    await tester.tap(find.text('Album'), buttons: kSecondaryButton);
    await tester.pump();

    expect(shown, 2);
  });

  testWidgets('keyboard focus reveals the overlay and Enter opens', (
    tester,
  ) async {
    var taps = 0;
    var plays = 0;
    await pumpCard(
      tester,
      MediaCard(title: 'Album', onTap: () => taps++, onPlay: () => plays++),
    );

    final overlay = find.byType(AnimatedOpacity);
    expect(tester.widget<AnimatedOpacity>(overlay).opacity, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(tester.widget<AnimatedOpacity>(overlay).opacity, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);

    // Tab moves into the overlay's play button.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(plays, 1);
  });

  testWidgets('announces as one labelled button', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCard(
      tester,
      MediaCard(title: 'Blue Train', subtitle: 'John Coltrane', onTap: () {}),
    );

    expect(find.bySemanticsLabel('Blue Train, John Coltrane'), findsOneWidget);
    handle.dispose();
  });
}
