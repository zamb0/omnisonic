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
      home: SizedBox(width: 300, height: 300, child: child),
    );

List<Alignment> _centres(WidgetTester t) => [
  for (final box in t.widgetList<DecoratedBox>(
    find.descendant(
      of: find.byType(AuroraMesh),
      matching: find.byType(DecoratedBox),
    ),
  ))
    ((box.decoration as BoxDecoration).gradient as RadialGradient).center
        as Alignment,
];

void main() {
  tearDown(() => AuroraMesh.driftEnabled = true);

  testWidgets('draws the three Aurora blobs', (t) async {
    await t.pumpWidget(_host(const AuroraMesh()));
    expect(_centres(t), hasLength(3));
  });

  testWidgets('opacity scales the blob alpha', (t) async {
    await t.pumpWidget(_host(const AuroraMesh(opacity: 0.5)));
    final box = t
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(AuroraMesh),
            matching: find.byType(DecoratedBox),
          ),
        )
        .first;
    final colors =
        ((box.decoration as BoxDecoration).gradient as RadialGradient).colors;
    expect(
      colors.first.a,
      closeTo(OmnisonicBrand.dark.auroraMesh.first.colors.first.a * 0.5, 0.01),
    );
  });

  testWidgets('still by default', (t) async {
    await t.pumpWidget(_host(const AuroraMesh()));
    final a = _centres(t);
    await t.pump(const Duration(seconds: 5));
    expect(_centres(t), a);
  });

  testWidgets('drifts when asked, within its radius', (t) async {
    AuroraMesh.driftEnabled = true;
    await t.pumpWidget(_host(const AuroraMesh(drift: true)));
    final base = _centres(t);
    await t.pump(const Duration(seconds: 5));
    final later = _centres(t);
    expect(later, isNot(base));
    for (var i = 0; i < 3; i++) {
      expect(
        (later[i].x - base[i].x).abs(),
        lessThanOrEqualTo(AuroraMesh.driftRadius * 2 + 1e-9),
      );
    }
  });

  testWidgets('does not drift with reduce motion', (t) async {
    await t.pumpWidget(_host(const AuroraMesh(drift: true), reduce: true));
    final a = _centres(t);
    await t.pump(const Duration(seconds: 5));
    expect(_centres(t), a);
  });

  testWidgets('ignores pointers and semantics', (t) async {
    await t.pumpWidget(_host(const AuroraMesh()));
    expect(
      find.descendant(
        of: find.byType(AuroraMesh),
        matching: find.byType(IgnorePointer),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byType(AuroraMesh),
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
  });
}
