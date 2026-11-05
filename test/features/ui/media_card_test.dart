import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/features/ui/presentation/widgets/album_card.dart';
import 'package:omnisonic/features/ui/presentation/widgets/cover_art.dart';
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

  group('hover (docs/design-system.md §9.5)', () {
    Future<TestGesture> hover(WidgetTester tester) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: const Offset(-100, -100));
      await mouse.moveTo(tester.getCenter(find.byType(MediaCard)));
      await tester.pump(); // the state change starts the animations here
      await tester.pump(const Duration(milliseconds: 400));
      return mouse;
    }

    Widget card() => MediaCard(
      title: 'Album',
      onTap: () {},
      onPlay: () {},
      onShuffle: () {},
      onStar: () {},
    );

    testWidgets('lifts 1.03 and swaps the shadow for the glow', (tester) async {
      await pumpCard(tester, card());
      Iterable<double> scales() => tester
          .widgetList<AnimatedScale>(find.byType(AnimatedScale))
          .map((w) => w.scale);
      expect(scales(), isNot(contains(1.03)));
      final restShadow =
          tester
                  .widget<AnimatedContainer>(
                    find
                        .descendant(
                          of: find.byType(AspectRatio),
                          matching: find.byType(AnimatedContainer),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(restShadow.boxShadow, OmnisonicShadows.art);

      await hover(tester);
      expect(scales(), contains(1.03));
      final hovered =
          tester
                  .widget<AnimatedContainer>(
                    find
                        .descendant(
                          of: find.byType(AspectRatio),
                          matching: find.byType(AnimatedContainer),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(hovered.boxShadow!.single.color.a, closeTo(0.5, 0.01));
    });

    testWidgets(
      'shows a 35 % scrim and the Play disc, 8 px higher once settled',
      (tester) async {
        await pumpCard(tester, card());
        expect(find.byType(PlayDisc), findsOneWidget);
        double opacity() => tester
            .widget<AnimatedOpacity>(
              find
                  .descendant(
                    of: find.byType(AspectRatio),
                    matching: find.byType(AnimatedOpacity),
                  )
                  .first,
            )
            .opacity;
        expect(opacity(), 0);
        final restY = tester.getCenter(find.byType(PlayDisc)).dy;

        await hover(tester);
        expect(opacity(), 1);
        expect(
          tester
              .widget<ColoredBox>(
                find
                    .descendant(
                      of: find.byType(AnimatedOpacity),
                      matching: find.byType(ColoredBox),
                    )
                    .first,
              )
              .color,
          OmnisonicColors.scrimHover,
        );
        expect(OmnisonicColors.scrimHover.a, closeTo(0.35, 0.01));
        // It rises 8 px; the cover's own 1.03 lift pushes it back out by 3 %
        // of its distance from the cover's centre.
        final artCenterY = tester.getCenter(find.byType(AspectRatio).first).dy;
        final fromCentre = (restY - 8) - artCenterY;
        expect(
          restY - tester.getCenter(find.byType(PlayDisc)).dy,
          closeTo(8 - 0.03 * fromCentre, 0.5),
        );
      },
    );

    testWidgets('the Play disc is bottom-right, the badge top-left', (
      tester,
    ) async {
      await pumpCard(
        tester,
        MediaCard(
          title: 'Album',
          onPlay: () {},
          badge: const SizedBox(key: Key('badge'), width: 10, height: 10),
        ),
      );
      await hover(tester);
      final art = tester.getRect(find.byType(AspectRatio).first);
      final disc = tester.getCenter(find.byType(PlayDisc));
      final badge = tester.getCenter(find.byKey(const Key('badge')));
      expect(disc.dx, greaterThan(art.center.dx));
      expect(disc.dy, greaterThan(art.center.dy));
      expect(badge.dx, lessThan(art.center.dx));
      expect(badge.dy, lessThan(art.center.dy));
    });

    testWidgets('hover and press change no layout, only transforms', (
      tester,
    ) async {
      await pumpCard(tester, card());
      final rest = tester.getSize(find.byType(MediaCard));
      final textTop = tester.getTopLeft(find.text('Album'));
      final mouse = await hover(tester);
      expect(tester.getSize(find.byType(MediaCard)), rest);
      expect(tester.getTopLeft(find.text('Album')), textTop);
      await mouse.down(
        tester.getCenter(find.byType(MediaCard)) + const Offset(0, -40),
      );
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.getSize(find.byType(MediaCard)), rest);
      await mouse.up();
    });

    testWidgets('pressing the card scales it to 0.97', (tester) async {
      await pumpCard(tester, MediaCard(title: 'Album', onTap: () {}));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(MediaCard)),
      );
      await tester.pump(const Duration(milliseconds: 150));
      final pressed = tester
          .widgetList<AnimatedScale>(find.byType(AnimatedScale))
          .map((s) => s.scale);
      expect(pressed, contains(PressScale.pressedScale));
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'an artist gets the auroraSoft ring on hover, an album does not',
      (tester) async {
        double ring() {
          final fades = tester.widgetList<AnimatedOpacity>(
            find.ancestor(
              of: find.byWidgetPredicate(
                (w) => w is CustomPaint && w.painter is AuroraRingPainter,
              ),
              matching: find.byType(AnimatedOpacity),
            ),
          );
          return fades.isEmpty ? -1 : fades.first.opacity;
        }

        await pumpCard(
          tester,
          MediaCard(title: 'Artist', shape: CoverArtShape.circle, onTap: () {}),
        );
        expect(ring(), 0);
        await hover(tester);
        expect(ring(), 1);

        await pumpCard(tester, MediaCard(title: 'Album', onTap: () {}));
        expect(ring(), -1, reason: 'albums have no ring');
      },
    );

    testWidgets('a tap on touch never leaves the overlay stuck open', (
      tester,
    ) async {
      await pumpCard(tester, card());
      await tester.tapAt(
        tester.getCenter(find.byType(MediaCard)) + const Offset(0, -40),
      );
      await tester.pumpAndSettle();
      final opacity = tester
          .widget<AnimatedOpacity>(
            find
                .descendant(
                  of: find.byType(AspectRatio),
                  matching: find.byType(AnimatedOpacity),
                )
                .first,
          )
          .opacity;
      expect(opacity, 0);
    });
  });
}
