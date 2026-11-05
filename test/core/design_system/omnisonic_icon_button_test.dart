import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';

Widget _host(Widget child, {bool reduce = false}) => MaterialApp(
  theme: OmnisonicTheme.darkTheme,
  builder: (c, w) => MediaQuery(
    data: MediaQuery.of(c).copyWith(disableAnimations: reduce),
    child: w!,
  ),
  home: Scaffold(body: Center(child: child)),
);

Color? _bg(WidgetTester t) => t
    .widget<IconButton>(find.byType(IconButton))
    .style!
    .backgroundColor
    ?.resolve({});

void main() {
  testWidgets('is 44 x 44 with a tooltip', (t) async {
    await t.pumpWidget(
      _host(
        OmnisonicIconButton(
          icon: OmnisonicIcons.playArrow,
          tooltip: 'Queue',
          onPressed: () {},
        ),
      ),
    );
    expect(t.getSize(find.byType(IconButton)), const Size(44, 44));
    expect(find.byTooltip('Queue'), findsOneWidget);
  });

  testWidgets('variants paint the spec fills', (t) async {
    const surfaces = OmnisonicSurfaces.dark;
    OmnisonicIconButton b(OmnisonicIconButtonVariant v) => OmnisonicIconButton(
      icon: OmnisonicIcons.playArrow,
      tooltip: 't',
      onPressed: () {},
      variant: v,
    );
    await t.pumpWidget(_host(b(OmnisonicIconButtonVariant.standard)));
    expect(_bg(t), isNull);
    await t.pumpWidget(_host(b(OmnisonicIconButtonVariant.filled)));
    expect(_bg(t), surfaces.ink);
    await t.pumpWidget(_host(b(OmnisonicIconButtonVariant.tonal)));
    expect(_bg(t), surfaces.well);
    await t.pumpWidget(_host(b(OmnisonicIconButtonVariant.onScrim)));
    expect(_bg(t), OmnisonicColors.scrimControl);
  });

  group('toggle', () {
    Widget toggle({
      required bool selected,
      Color? color,
      VoidCallback? onPressed,
    }) => _host(
      OmnisonicIconButton(
        icon: OmnisonicIcons.favoriteOutline,
        selectedIcon: OmnisonicIcons.favorite,
        selectedColor: color,
        tooltip: 'Favourite',
        variant: OmnisonicIconButtonVariant.toggle,
        selected: selected,
        onPressed: onPressed ?? () {},
      ),
    );

    testWidgets('swaps the glyph and exposes selected semantics', (t) async {
      final handle = t.ensureSemantics();
      await t.pumpWidget(toggle(selected: false));
      expect(find.byIcon(OmnisonicIcons.favoriteOutline), findsOneWidget);
      expect(
        t.getSemantics(find.byType(IconButton)).flagsCollection.isSelected,
        isNot(Tristate.isTrue),
      );

      await t.pumpWidget(toggle(selected: true));
      await t.pumpAndSettle();
      expect(find.byIcon(OmnisonicIcons.favorite), findsOneWidget);
      expect(
        t.getSemantics(find.byType(IconButton)).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      handle.dispose();
    });

    testWidgets('on uses selectedColor, defaulting to primary', (t) async {
      Color? fg() => t
          .widget<IconButton>(find.byType(IconButton))
          .style!
          .foregroundColor!
          .resolve({});
      await t.pumpWidget(toggle(selected: true));
      expect(fg(), OmnisonicTheme.darkTheme.colorScheme.primary);
      await t.pumpWidget(
        toggle(selected: true, color: OmnisonicColors.heatDark),
      );
      expect(fg(), OmnisonicColors.heatDark);
    });

    testWidgets('turning on bursts 1 -> 1.25 -> 1', (t) async {
      await t.pumpWidget(toggle(selected: false));
      double scale() => t
          .widget<ScaleTransition>(
            find.descendant(
              of: find.byType(IconButton),
              matching: find.byType(ScaleTransition),
            ),
          )
          .scale
          .value;
      expect(scale(), 1);
      await t.pumpWidget(toggle(selected: true));
      var peak = 1.0;
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 10));
        if (scale() > peak) peak = scale();
      }
      expect(peak, greaterThan(1.1));
      await t.pumpAndSettle();
      expect(scale(), closeTo(1, 0.001));
    });

    testWidgets('no burst with reduce motion', (t) async {
      Widget w(bool s) => _host(
        OmnisonicIconButton(
          icon: OmnisonicIcons.favoriteOutline,
          tooltip: 'x',
          variant: OmnisonicIconButtonVariant.toggle,
          selected: s,
          onPressed: () {},
        ),
        reduce: true,
      );
      await t.pumpWidget(w(false));
      await t.pumpWidget(w(true));
      await t.pump(const Duration(milliseconds: 50));
      final scale = t
          .widget<ScaleTransition>(
            find.descendant(
              of: find.byType(IconButton),
              matching: find.byType(ScaleTransition),
            ),
          )
          .scale
          .value;
      expect(scale, 1);
    });
  });

  testWidgets('keyboard focus draws the focus ring', (t) async {
    await t.pumpWidget(
      _host(
        OmnisonicIconButton(
          icon: OmnisonicIcons.playArrow,
          tooltip: 'x',
          onPressed: () {},
        ),
      ),
    );
    bool hasRing() => t
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .any(
          (d) =>
              d.decoration is BoxDecoration &&
              (d.decoration as BoxDecoration).boxShadow?.length == 2,
        );
    expect(hasRing(), isFalse);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    expect(hasRing(), isTrue);
  });

  testWidgets('disabled does not fire', (t) async {
    await t.pumpWidget(
      _host(
        const OmnisonicIconButton(
          icon: OmnisonicIcons.playArrow,
          tooltip: 'x',
          onPressed: null,
        ),
      ),
    );
    expect(t.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
  });
}
