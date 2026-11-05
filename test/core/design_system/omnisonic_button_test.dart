import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';

Widget _host(Widget child) => MaterialApp(
  theme: OmnisonicTheme.darkTheme,
  home: Scaffold(body: Center(child: child)),
);

Color? _fill(WidgetTester t) {
  final button = t.widget<FilledButton>(find.byType(FilledButton));
  return button.style!.backgroundColor?.resolve({});
}

void main() {
  testWidgets('heights follow the size', (t) async {
    for (final size in OmnisonicButtonSize.values) {
      await t.pumpWidget(
        _host(OmnisonicButton(label: 'Save', onPressed: () {}, size: size)),
      );
      expect(t.getSize(find.byType(FilledButton)).height, size.height);
    }
  });

  for (final withIcon in [true, false]) {
    testWidgets('loading keeps the width (icon: $withIcon)', (t) async {
      Widget build(bool loading) => _host(
        OmnisonicButton(
          label: 'Connect',
          icon: withIcon ? OmnisonicIcons.playArrow : null,
          loading: loading,
          onPressed: () {},
        ),
      );
      await t.pumpWidget(build(false));
      final idle = t.getSize(find.byType(FilledButton));
      await t.pumpWidget(build(true));
      expect(t.getSize(find.byType(FilledButton)), idle);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  }

  testWidgets('loading ignores taps and is a live region', (t) async {
    var taps = 0;
    await t.pumpWidget(
      _host(
        OmnisonicButton(label: 'Save', loading: true, onPressed: () => taps++),
      ),
    );
    await t.tap(find.byType(FilledButton), warnIfMissed: false);
    expect(taps, 0);
    final data = t.getSemantics(find.byType(OmnisonicButton));
    expect(data.label, 'Save, loading');
    expect(data.flagsCollection.isLiveRegion, isTrue);
  });

  testWidgets('tap works and null onPressed disables', (t) async {
    var taps = 0;
    await t.pumpWidget(
      _host(OmnisonicButton(label: 'Save', onPressed: () => taps++)),
    );
    await t.tap(find.byType(FilledButton));
    expect(taps, 1);
    await t.pumpWidget(
      _host(const OmnisonicButton(label: 'Save', onPressed: null)),
    );
    expect(t.widget<FilledButton>(find.byType(FilledButton)).enabled, isFalse);
  });

  testWidgets('variants use ink, well and error fills', (t) async {
    final scheme = OmnisonicTheme.darkTheme.colorScheme;
    const surfaces = OmnisonicSurfaces.dark;
    OmnisonicButton b(OmnisonicButtonVariant v) =>
        OmnisonicButton(label: 'x', onPressed: () {}, variant: v);

    await t.pumpWidget(_host(b(OmnisonicButtonVariant.primary)));
    // Primary inherits the theme's ink fill.
    expect(_fill(t), isNull);

    await t.pumpWidget(_host(b(OmnisonicButtonVariant.tonal)));
    expect(_fill(t), surfaces.well);

    await t.pumpWidget(_host(b(OmnisonicButtonVariant.destructive)));
    expect(_fill(t), scheme.error);
  });
}
