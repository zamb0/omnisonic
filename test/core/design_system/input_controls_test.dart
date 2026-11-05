import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';

Widget _host(Widget child, {ThemeData? theme, bool reduce = false}) =>
    MaterialApp(
      theme: theme ?? OmnisonicTheme.darkTheme,
      builder: (c, w) => MediaQuery(
        data: MediaQuery.of(c).copyWith(disableAnimations: reduce),
        child: w!,
      ),
      home: Scaffold(
        body: Center(child: SizedBox(width: 360, child: child)),
      ),
    );

void main() {
  group('OmnisonicSegmented', () {
    Widget segmented(
      ValueChanged<int> onChanged, {
      int selected = 0,
      bool iconsOnly = false,
    }) => OmnisonicSegmented<int>(
      iconsOnly: iconsOnly,
      selected: selected,
      onChanged: onChanged,
      options: const [
        SegmentOption(value: 0, label: 'Light', icon: Icons.light_mode),
        SegmentOption(value: 1, label: 'Dark', icon: Icons.dark_mode),
        SegmentOption(value: 2, label: 'Auto', icon: Icons.brightness_auto),
      ],
    );

    Finder pill() => find.descendant(
      of: find.byType(AnimatedPositioned),
      matching: find.byType(DecoratedBox),
    );

    testWidgets(
      'is a 44 high stadium on the well, the selected on an ink pill',
      (t) async {
        await t.pumpWidget(_host(segmented((_) {})));
        expect(t.getSize(find.byType(OmnisonicSegmented<int>)).height, 44);
        final pillDeco =
            t.widget<DecoratedBox>(pill()).decoration as ShapeDecoration;
        expect(pillDeco.color, OmnisonicSurfaces.dark.ink);
      },
    );

    testWidgets('the ink pill slides to the chosen segment', (t) async {
      var value = 0;
      late StateSetter set;
      await t.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return segmented(
                (v) => setState(() => value = v),
                selected: value,
              );
            },
          ),
        ),
      );
      final start = t.getCenter(pill()).dx;
      await t.tap(find.text('Auto'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      final mid = t.getCenter(pill()).dx;
      await t.pumpAndSettle();
      final end = t.getCenter(pill()).dx;
      expect(value, 2);
      expect(mid, greaterThan(start));
      expect(mid, lessThan(end), reason: 'on its way, not there yet');
      expect(end, closeTo(t.getCenter(find.text('Auto')).dx - 0, 40));
      set(() {});
    });

    testWidgets('with reduce motion the pill does not travel', (t) async {
      await t.pumpWidget(_host(segmented((_) {}), reduce: true));
      expect(
        t.widget<AnimatedPositioned>(find.byType(AnimatedPositioned)).duration,
        Duration.zero,
      );
    });

    testWidgets('every segment is a button announced selected or not', (
      t,
    ) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(_host(segmented((_) {}, selected: 1)));
      expect(
        t.getSemantics(find.text('Dark')).flagsCollection.isSelected.name,
        'isTrue',
      );
      expect(
        t.getSemantics(find.text('Light')).flagsCollection.isSelected.name,
        'isFalse',
      );
      expect(
        t.getSemantics(find.text('Light')).flagsCollection.isButton,
        isTrue,
      );
      h.dispose();
    });

    testWidgets(
      'keyboard: tab to a segment, Enter picks it, focus ring shows',
      (t) async {
        var picked = -1;
        await t.pumpWidget(_host(segmented((v) => picked = v)));
        await t.sendKeyEvent(LogicalKeyboardKey.tab);
        await t.pump();
        expect(
          t
              .widgetList<DecoratedBox>(find.byType(DecoratedBox))
              .any(
                (d) =>
                    d.decoration is BoxDecoration &&
                    ((d.decoration as BoxDecoration).boxShadow?.length ?? 0) ==
                        2,
              ),
          isTrue,
          reason: 'the focus ring',
        );
        await t.sendKeyEvent(LogicalKeyboardKey.enter);
        await t.pump();
        expect(picked, 1);
      },
    );

    testWidgets('icons only: labels hidden, tooltips and semantics kept', (
      t,
    ) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(_host(segmented((_) {}, iconsOnly: true)));
      expect(find.text('Dark'), findsNothing);
      expect(find.byTooltip('Dark'), findsOneWidget);
      expect(find.bySemanticsLabel('Dark'), findsOneWidget);
      h.dispose();
    });

    testWidgets('selecting the current one does nothing', (t) async {
      var taps = 0;
      await t.pumpWidget(_host(segmented((_) => taps++)));
      await t.tap(find.text('Light'));
      expect(taps, 0);
    });
  });

  group('FocusDecoration', () {
    testWidgets('rings a focused child for keyboard focus only', (t) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      final node = FocusNode();
      addTearDown(node.dispose);
      await t.pumpWidget(
        _host(
          FocusDecoration(
            child: Focus(
              focusNode: node,
              child: const SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      );
      List<BoxShadow>? shadows() => t
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(FocusDecoration),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => (d.decoration as BoxDecoration).boxShadow)
          .firstWhere((_) => true);
      expect(shadows(), isNull);
      node.requestFocus();
      await t.pump();
      expect(shadows(), hasLength(2));
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
    });

    testWidgets('halo-only draws one soft shadow and shows for any focus', (
      t,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await t.pumpWidget(
        _host(
          FocusDecoration(
            ring: false,
            keyboardOnly: false,
            child: Focus(
              focusNode: node,
              child: const SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      );
      node.requestFocus();
      await t.pump();
      final shadows = t
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(FocusDecoration),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => (d.decoration as BoxDecoration).boxShadow)
          .firstWhere((_) => true)!;
      expect(shadows, hasLength(1));
    });
  });

  group('theme values (§9.3)', () {
    for (final entry in {
      Brightness.dark: OmnisonicTheme.darkTheme,
      Brightness.light: OmnisonicTheme.lightTheme,
    }.entries) {
      final theme = entry.value;
      final scheme = theme.colorScheme;
      final surfaces = theme.extension<OmnisonicSurfaces>()!;
      group(entry.key.name, () {
        test(
          'chip: selected = primaryContainer, 1 px primary edge and a check',
          () {
            final c = theme.chipTheme;
            expect(c.selectedColor, scheme.primaryContainer);
            expect(c.showCheckmark, isTrue);
            final on = c.side!;
            final side = (on as WidgetStateBorderSide).resolve({
              WidgetState.selected,
            })!;
            expect(side.color, scheme.primary);
            expect(side.width, 1);
            expect(on.resolve({})!.color, surfaces.hairline);
          },
        );

        test('switch: off = container-highest + outline, on = primary', () {
          final s = theme.switchTheme;
          expect(s.trackColor!.resolve({}), scheme.surfaceContainerHighest);
          expect(s.trackColor!.resolve({WidgetState.selected}), scheme.primary);
          expect(s.trackOutlineColor!.resolve({}), scheme.outline);
          expect(
            s.thumbColor!.resolve({WidgetState.selected}),
            scheme.onPrimary,
          );
        });

        test('checkbox and radio: outline 1.5, on = primary', () {
          expect(
            theme.checkboxTheme.side,
            BorderSide(color: scheme.outline, width: 1.5),
          );
          expect(
            theme.checkboxTheme.fillColor!.resolve({WidgetState.selected}),
            scheme.primary,
          );
          expect(
            theme.radioTheme.fillColor!.resolve({WidgetState.selected}),
            scheme.primary,
          );
          expect(theme.radioTheme.fillColor!.resolve({}), scheme.outline);
        });

        test(
          'slider: track 4 on container-highest, thumb 14 growing to 18',
          () {
            final s = theme.sliderTheme;
            expect(s.trackHeight, 4);
            expect(s.inactiveTrackColor, scheme.surfaceContainerHighest);
            expect(s.activeTrackColor, scheme.primary);
            expect(s.thumbShape, isA<GrowingThumbShape>());
            expect(GrowingThumbShape.restRadius * 2, 14);
            expect(GrowingThumbShape.pressedRadius * 2, 18);
          },
        );

        test('inputs: focus 2 px primary, error 1 px with text below', () {
          final i = theme.inputDecorationTheme;
          expect((i.focusedBorder as OutlineInputBorder).borderSide.width, 2);
          expect(
            (i.focusedBorder as OutlineInputBorder).borderSide.color,
            scheme.primary,
          );
          expect(
            (i.errorBorder as OutlineInputBorder).borderSide.color,
            scheme.error,
          );
          expect(i.errorStyle!.color, scheme.error);
          expect(i.helperStyle!.color, scheme.onSurfaceVariant);
          expect(i.fillColor, surfaces.well);
        });
      });
    }
  });

  group('GrowingThumbShape', () {
    double radiusAt(double activation) {
      final canvas = TestRecordingCanvas();
      final context = TestRecordingPaintingContext(canvas);
      const GrowingThumbShape().paint(
        context,
        Offset.zero,
        activationAnimation: AlwaysStoppedAnimation(activation),
        enableAnimation: const AlwaysStoppedAnimation(1),
        isDiscrete: false,
        labelPainter: TextPainter(),
        parentBox: RenderConstrainedBox(
          additionalConstraints: const BoxConstraints(),
        ),
        sliderTheme: const SliderThemeData(thumbColor: Color(0xFF000000)),
        textDirection: TextDirection.ltr,
        value: 0.5,
        textScaleFactor: 1,
        sizeWithOverflow: Size.zero,
      );
      final draw = canvas.invocations.firstWhere(
        (i) => i.invocation.memberName == #drawCircle,
      );
      return draw.invocation.positionalArguments[1] as double;
    }

    test('14 px at rest, 18 px pressed, in between while it grows', () {
      expect(radiusAt(0) * 2, 14);
      expect(radiusAt(1) * 2, 18);
      expect(radiusAt(0.5) * 2, 16);
    });

    test('reserves room for the grown thumb', () {
      expect(
        const GrowingThumbShape().getPreferredSize(true, false),
        const Size.square(18),
      );
    });
  });
}
