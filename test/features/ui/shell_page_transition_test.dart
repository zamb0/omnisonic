import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:omnisonic/core/routing/app_router.dart';

import '../../helpers/widget_harness.dart';

/// Shell pages are transparent so the art-tint wash shows through them. A
/// plain fade between two of them used to be a double exposure: the
/// Navigator keeps the outgoing page fully painted until the incoming one has
/// finished, so both pages' content showed at once and then the old one was
/// cut away. These read the rendered pixels to hold the cross-fade to that.
void main() {
  // Each page draws one solid block in its own corner, so a pixel inside a
  // block belongs to exactly one page.
  List<RouteBase> routes() => [
    for (final (path, alignment) in [
      (AppRouter.home, Alignment.topLeft),
      (AppRouter.library, Alignment.bottomRight),
    ])
      GoRoute(
        path: path,
        pageBuilder: (context, state) => AppRouter.shellPage(
          context: context,
          state: state,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Align(
              alignment: alignment,
              child: Container(
                key: ValueKey(path),
                width: 120,
                height: 120,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
  ];

  Future<_Frame> capture(WidgetTester tester) async {
    final bytes = await tester.runAsync(() async {
      final image = await captureImage(
        tester.element(find.byType(MaterialApp)),
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return (data!, image.width);
    });
    return _Frame(bytes!.$1, bytes.$2);
  }

  Offset centreOf(WidgetTester tester, String path) =>
      tester.getCenter(find.byKey(ValueKey(path)));

  Future<void> pumpHome(WidgetTester tester) => pumpShell(
    tester,
    location: AppRouter.home,
    size: TestSizes.tablet,
    routes: routes(),
  );

  Future<void> goTo(WidgetTester tester, String from, String to) async {
    GoRouter.of(tester.element(find.byKey(ValueKey(from)))).go(to);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('a tab switch fades the old page out, not just the new one in', (
    tester,
  ) async {
    await pumpHome(tester);
    final oldBlock = centreOf(tester, AppRouter.home);

    await goTo(tester, AppRouter.home, AppRouter.library);
    final newBlock = centreOf(tester, AppRouter.library);
    final frame = await capture(tester);

    // Halfway through, both blocks are part-way. The old one used to stay
    // pure white until the new page finished, and was then cut away.
    expect(frame.luminanceAt(oldBlock), lessThan(0.85));
    expect(frame.luminanceAt(newBlock), lessThan(0.85));
    expect(
      frame.luminanceAt(newBlock),
      greaterThan(frame.luminanceAt(oldBlock) - 0.5),
    );

    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(AppRouter.home)), findsNothing);
    expect((await capture(tester)).luminanceAt(newBlock), greaterThan(0.95));
  });

  testWidgets('popping fades the revealed page back in', (tester) async {
    await pumpHome(tester);
    final homeBlock = centreOf(tester, AppRouter.home);
    GoRouter.of(
      tester.element(find.byKey(const ValueKey(AppRouter.home))),
    ).push(AppRouter.library);
    await tester.pumpAndSettle();

    GoRouter.of(
      tester.element(find.byKey(const ValueKey(AppRouter.library))),
    ).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect((await capture(tester)).luminanceAt(homeBlock), lessThan(0.85));

    await tester.pumpAndSettle();
    expect((await capture(tester)).luminanceAt(homeBlock), greaterThan(0.95));
  });

  testWidgets('the background is untouched by the fade', (tester) async {
    await pumpHome(tester);
    // Empty background in the middle of the content column, away from both
    // blocks.
    final probe = tester.getCenter(find.byType(Scaffold).last);
    final before = await capture(tester);

    await goTo(tester, AppRouter.home, AppRouter.library);
    final during = await capture(tester);
    await tester.pumpAndSettle();
    final after = await capture(tester);

    expect(during.distance(before, probe), lessThanOrEqualTo(1));
    expect(after.distance(before, probe), lessThanOrEqualTo(1));
  });
}

class _Frame {
  _Frame(this._data, this._width);

  final ByteData _data;
  final int _width;

  List<int> _rgb(Offset point) {
    final index = (point.dy.round() * _width + point.dx.round()) * 4;
    return [
      _data.getUint8(index),
      _data.getUint8(index + 1),
      _data.getUint8(index + 2),
    ];
  }

  double luminanceAt(Offset point) {
    final rgb = _rgb(point);
    return (0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]) / 255;
  }

  /// Largest per-channel difference from [other] at [point].
  int distance(_Frame other, Offset point) {
    final a = _rgb(point);
    final b = other._rgb(point);
    return [
      for (var i = 0; i < 3; i++) (a[i] - b[i]).abs(),
    ].reduce((x, y) => x > y ? x : y);
  }
}
