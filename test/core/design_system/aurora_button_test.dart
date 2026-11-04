import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';

Widget _host(Widget child, {Brightness b = Brightness.dark}) => MaterialApp(
  theme: b == Brightness.dark
      ? OmnisonicTheme.darkTheme
      : OmnisonicTheme.lightTheme,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('AuroraButton', () {
    testWidgets('has the three heights from the spec', (t) async {
      for (final size in OmnisonicButtonSize.values) {
        await t.pumpWidget(
          _host(AuroraButton(label: 'Play', onPressed: () {}, size: size)),
        );
        expect(
          t.getSize(find.byType(AuroraButton)).height,
          size.height,
          reason: size.name,
        );
      }
      expect(OmnisonicButtonSize.sm.height, 36);
      expect(OmnisonicButtonSize.md.height, 44);
      expect(OmnisonicButtonSize.lg.height, 52);
    });

    testWidgets('taps call onPressed; disabled does not', (t) async {
      var taps = 0;
      await t.pumpWidget(
        _host(AuroraButton(label: 'Play', onPressed: () => taps++)),
      );
      await t.tap(find.byType(AuroraButton));
      expect(taps, 1);

      await t.pumpWidget(
        _host(const AuroraButton(label: 'Play', onPressed: null)),
      );
      await t.tap(find.byType(AuroraButton), warnIfMissed: false);
      expect(taps, 1);
      expect(
        t.widget<Opacity>(find.byType(Opacity).first).opacity,
        0.38,
        reason: 'disabled is 38 % opacity',
      );
    });

    for (final withIcon in [true, false]) {
      testWidgets('loading keeps the width (icon: $withIcon)', (t) async {
        Widget build(bool loading) => _host(
          AuroraButton(
            label: 'Play all',
            icon: withIcon ? OmnisonicIcons.playArrow : null,
            loading: loading,
            onPressed: () {},
          ),
        );
        await t.pumpWidget(build(false));
        final idle = t.getSize(find.byType(AuroraButton));
        await t.pumpWidget(build(true));
        expect(t.getSize(find.byType(AuroraButton)), idle);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    }

    testWidgets('loading ignores taps and is a live region', (t) async {
      var taps = 0;
      await t.pumpWidget(
        _host(
          AuroraButton(label: 'Play', loading: true, onPressed: () => taps++),
        ),
      );
      await t.tap(find.byType(AuroraButton));
      expect(taps, 0);
      final data = t.getSemantics(find.byType(AuroraButton));
      expect(data.label, 'Play, loading');
      expect(data.flagsCollection.isLiveRegion, isTrue);
    });

    testWidgets('text and icon use onAurora in both themes', (t) async {
      for (final b in Brightness.values) {
        await t.pumpWidget(
          _host(
            AuroraButton(
              label: 'Play',
              icon: OmnisonicIcons.playArrow,
              onPressed: () {},
            ),
            b: b,
          ),
        );
        expect(
          t.widget<Text>(find.text('Play')).style!.color,
          OmnisonicColors.onAurora,
        );
        expect(
          t.widget<Icon>(find.byType(Icon)).color,
          OmnisonicColors.onAurora,
        );
      }
    });

    testWidgets('long labels ellipsize instead of overflowing', (t) async {
      await t.pumpWidget(
        _host(
          SizedBox(
            width: 120,
            child: AuroraButton(
              label: 'A very long label that cannot fit',
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(t.takeException(), isNull);
    });
  });

  group('PlayDisc', () {
    testWidgets('has the four diameters', (t) async {
      for (final size in PlayDiscSize.values) {
        await t.pumpWidget(_host(PlayDisc(onPressed: () {}, size: size)));
        final box = t.getSize(find.byType(PlayDisc));
        expect(box, Size.square(size.diameter));
      }
      expect(PlayDiscSize.values.map((s) => s.diameter), [44, 48, 56, 64]);
    });

    testWidgets('swaps play and pause and labels itself', (t) async {
      await t.pumpWidget(_host(PlayDisc(onPressed: () {})));
      expect(find.byIcon(OmnisonicIcons.playArrow), findsOneWidget);
      expect(find.byTooltip('Play'), findsOneWidget);

      await t.pumpWidget(_host(PlayDisc(onPressed: () {}, playing: true)));
      await t.pumpAndSettle();
      expect(find.byIcon(OmnisonicIcons.pause), findsOneWidget);
      expect(find.byIcon(OmnisonicIcons.playArrow), findsNothing);
      expect(find.byTooltip('Pause'), findsOneWidget);
    });

    testWidgets('calls onPressed', (t) async {
      var taps = 0;
      await t.pumpWidget(_host(PlayDisc(onPressed: () => taps++)));
      await t.tap(find.byType(PlayDisc));
      expect(taps, 1);
    });

    testWidgets('is exposed as a button with its label', (t) async {
      await t.pumpWidget(
        _host(PlayDisc(onPressed: () {}, tooltip: 'Play album')),
      );
      expect(find.bySemanticsLabel('Play album'), findsOneWidget);
    });
  });
}
