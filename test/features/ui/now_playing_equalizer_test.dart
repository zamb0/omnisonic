import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/features/ui/presentation/widgets/now_playing_equalizer.dart';

Widget _host({
  required bool playing,
  bool reduce = false,
  bool exclude = false,
}) => MaterialApp(
  builder: (c, w) => MediaQuery(
    data: MediaQuery.of(c).copyWith(disableAnimations: reduce),
    child: w!,
  ),
  home: Center(
    child: NowPlayingEqualizer(playing: playing, excludeSemantics: exclude),
  ),
);

List<double> _heights(WidgetTester t) => [
  for (final box in t.widgetList<SizedBox>(
    find.descendant(
      of: find.byType(NowPlayingEqualizer),
      matching: find.byType(SizedBox),
    ),
  ))
    if (box.width == NowPlayingEqualizer.barWidth) box.height!,
];

void main() {
  const mid =
      (NowPlayingEqualizer.minBarHeight + NowPlayingEqualizer.maxBarHeight) / 2;

  testWidgets('playing: bars move, out of phase', (t) async {
    await t.pumpWidget(_host(playing: true));
    await t.pump(const Duration(milliseconds: 100));
    final first = _heights(t);
    expect(first, hasLength(3));
    await t.pump(const Duration(milliseconds: 150));
    final later = _heights(t);
    expect(later, isNot(first), reason: 'bars animate');
    expect(
      later.toSet().length,
      greaterThan(1),
      reason: 'bars are out of phase',
    );
    for (final h in later) {
      expect(
        h,
        inInclusiveRange(
          NowPlayingEqualizer.minBarHeight,
          NowPlayingEqualizer.maxBarHeight,
        ),
      );
    }
  });

  testWidgets('paused: bars hold at mid height', (t) async {
    await t.pumpWidget(_host(playing: false));
    await t.pump(const Duration(milliseconds: 300));
    expect(_heights(t), [mid, mid, mid]);
  });

  testWidgets('playing then paused stops and settles at mid', (t) async {
    await t.pumpWidget(_host(playing: true));
    await t.pump(const Duration(milliseconds: 130));
    await t.pumpWidget(_host(playing: false));
    await t.pump();
    expect(_heights(t), [mid, mid, mid]);
    await t.pump(const Duration(milliseconds: 500));
    expect(_heights(t), [mid, mid, mid]);
  });

  testWidgets('reduce motion: static even while playing', (t) async {
    await t.pumpWidget(_host(playing: true, reduce: true));
    await t.pump(const Duration(milliseconds: 300));
    expect(_heights(t), [mid, mid, mid]);
  });

  testWidgets('announces "Now playing" unless excluded', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(_host(playing: true));
    expect(find.bySemanticsLabel('Now playing'), findsOneWidget);
    await t.pumpWidget(_host(playing: true, exclude: true));
    expect(find.bySemanticsLabel('Now playing'), findsNothing);
    h.dispose();
  });
}
