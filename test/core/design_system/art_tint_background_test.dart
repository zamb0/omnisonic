import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';

Widget _host(Widget child, {bool reduce = false, ThemeData? theme}) =>
    MaterialApp(
      theme: theme ?? OmnisonicTheme.darkTheme,
      builder: (c, w) => MediaQuery(
        data: MediaQuery.of(c).copyWith(disableAnimations: reduce),
        child: w!,
      ),
      home: SizedBox(width: 400, height: 600, child: child),
    );

void main() {
  testWidgets(
    'with no cover it is the drifting Aurora mesh, not a flat canvas',
    (t) async {
      await t.pumpWidget(_host(const ArtTintBackground()));
      final mesh = t.widget<AuroraMesh>(find.byType(AuroraMesh));
      expect(mesh.drift, isTrue);
      expect(mesh.driftPeriod, const Duration(seconds: 20));
    },
  );

  testWidgets('with a cover it follows the cover and has no mesh', (t) async {
    await t.pumpWidget(_host(const ArtTintBackground(seed: Color(0xFF3366CC))));
    expect(find.byType(AuroraMesh), findsNothing);
  });

  for (final light in [false, true]) {
    testWidgets('the fallback is painted on ${light ? 'light' : 'dark'} too', (
      t,
    ) async {
      await t.pumpWidget(
        _host(
          const ArtTintBackground(),
          theme: light ? OmnisonicTheme.lightTheme : OmnisonicTheme.darkTheme,
        ),
      );
      expect(find.byType(AuroraMesh), findsOneWidget);
    });
  }

  testWidgets('the mesh sits still with reduce motion', (t) async {
    await t.pumpWidget(_host(const ArtTintBackground(), reduce: true));
    List<Alignment> centres() => [
      for (final box in t.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(AuroraMesh),
          matching: find.byType(DecoratedBox),
        ),
      ))
        ((box.decoration as BoxDecoration).gradient as RadialGradient).center
            as Alignment,
    ];
    final a = centres();
    await t.pump(const Duration(seconds: 7));
    expect(centres(), a);
  });

  testWidgets('it never takes pointers', (t) async {
    var taps = 0;
    await t.pumpWidget(
      _host(
        ArtTintBackground(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await t.tapAt(const Offset(200, 300));
    expect(taps, 1);
  });
}
