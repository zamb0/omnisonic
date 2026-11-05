import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';

Widget _host(Widget child, {bool highContrast = false, bool dark = true}) =>
    MaterialApp(
      theme: dark ? OmnisonicTheme.darkTheme : OmnisonicTheme.lightTheme,
      builder: (c, w) => MediaQuery(
        data: MediaQuery.of(c).copyWith(highContrast: highContrast),
        child: w!,
      ),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  Finder edge() => find.descendant(
    of: find.byType(GlassSurface),
    matching: find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == '_LightEdgePainter',
    ),
  );

  testWidgets('dark pill glass draws the light edge', (t) async {
    await t.pumpWidget(
      _host(
        const GlassSurface(
          intensity: GlassIntensity.pill,
          child: SizedBox(width: 80, height: 40),
        ),
      ),
    );
    expect(edge(), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('dark card glass and light pill keep the plain border', (
    t,
  ) async {
    await t.pumpWidget(
      _host(const GlassSurface(child: SizedBox(width: 80, height: 40))),
    );
    expect(edge(), findsNothing);
    await t.pumpWidget(
      _host(
        const GlassSurface(
          intensity: GlassIntensity.pill,
          child: SizedBox(width: 80, height: 40),
        ),
        dark: false,
      ),
    );
    await t.pumpAndSettle(); // the theme cross-fades
    expect(edge(), findsNothing);
  });

  testWidgets('reduce transparency: opaque surfaceContainer, no blur', (
    t,
  ) async {
    await t.pumpWidget(
      _host(
        const GlassSurface(child: SizedBox(width: 80, height: 40)),
        highContrast: true,
      ),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    final box = t
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(GlassSurface),
            matching: find.byType(DecoratedBox),
          ),
        )
        .first;
    final deco = box.decoration as BoxDecoration;
    expect(deco.color, OmnisonicTheme.darkTheme.colorScheme.surfaceContainer);
    expect(deco.color!.a, 1);
  });
}
