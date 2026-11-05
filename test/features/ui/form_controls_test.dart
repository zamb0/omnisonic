import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';

import '../../core/design_system/contrast_test.dart' show contrast, over;
import '../../helpers/widget_harness.dart';

void main() {
  group('SearchField', () {
    Future<(TextEditingController, FocusNode)> pumpSearch(
      WidgetTester t, {
      String text = '',
    }) async {
      final controller = TextEditingController(text: text);
      final node = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(node.dispose);
      await pumpPage(
        t,
        Center(
          child: SizedBox(
            width: 320,
            child: SearchField(
              controller: controller,
              hint: 'Search',
              focusNode: node,
            ),
          ),
        ),
        settle: false,
      );
      return (controller, node);
    }

    List<BoxShadow>? halo(WidgetTester t) => t
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(FocusDecoration),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((d) => (d.decoration as BoxDecoration).boxShadow)
        .firstWhere((_) => true);

    testWidgets('48 high, no halo at rest, an auroraSoft halo on focus', (
      t,
    ) async {
      final (_, node) = await pumpSearch(t);
      expect(t.getSize(find.byType(SearchField)).height, 48);
      expect(halo(t), isNull);
      node.requestFocus();
      await t.pump();
      await t.pump(); // focus lands a frame after the request
      final shadows = halo(t)!;
      expect(shadows, hasLength(1));
      expect(shadows.single.color, OmnisonicBrand.dark.auroraSoft.colors[1]);
    });

    testWidgets(
      'the clear button is 44 x 44, has a tooltip, and empties the field',
      (t) async {
        final (controller, _) = await pumpSearch(t, text: 'miles');
        final clear = find.byTooltip('Clear search');
        expect(clear, findsOneWidget);
        final size = t.getSize(clear);
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
        await t.tap(clear);
        await t.pump();
        expect(controller.text, isEmpty);
        expect(find.byTooltip('Clear search'), findsNothing);
      },
    );
  });

  group('chips', () {
    Widget chips() => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilterChip(label: const Text('On'), selected: true, onSelected: (_) {}),
        const SizedBox(width: 8),
        FilterChip(
          label: const Text('Off'),
          selected: false,
          onSelected: (_) {},
        ),
      ],
    );

    testWidgets('the selected one carries a check, not only a colour', (
      t,
    ) async {
      await pumpPage(t, Material(child: Center(child: chips())), settle: false);
      await t.pump(const Duration(milliseconds: 300));
      RawChip raw(String label) => t.widget<RawChip>(
        find.descendant(
          of: find.widgetWithText(FilterChip, label),
          matching: find.byType(RawChip),
        ),
      );
      final theme = OmnisonicTheme.darkTheme.chipTheme;
      // The check is painted by the chip itself (not an Icon): what matters is
      // that the theme asks for it, and that only the selected chip shows it.
      expect(raw('On').selected, isTrue);
      expect(raw('On').showCheckmark ?? theme.showCheckmark, isTrue);
      expect(
        raw('On').checkmarkColor ?? theme.checkmarkColor,
        OmnisonicTheme.darkTheme.colorScheme.primary,
      );
      expect(raw('Off').selected, isFalse);
    });

    testWidgets('selected = primaryContainer with a 1 px primary edge', (
      t,
    ) async {
      await pumpPage(t, Material(child: Center(child: chips())), settle: false);
      final chip = t.widget<FilterChip>(find.widgetWithText(FilterChip, 'On'));
      expect(chip.selected, isTrue);
      final scheme = OmnisonicTheme.darkTheme.colorScheme;
      expect(
        OmnisonicTheme.darkTheme.chipTheme.selectedColor,
        scheme.primaryContainer,
      );
    });
  });

  group('input borders are 3:1 against what they sit on', () {
    for (final entry in {
      Brightness.dark: OmnisonicTheme.darkTheme,
      Brightness.light: OmnisonicTheme.lightTheme,
    }.entries) {
      test(entry.key.name, () {
        final theme = entry.value;
        final scheme = theme.colorScheme;
        final border =
            (theme.inputDecorationTheme.enabledBorder as OutlineInputBorder)
                .borderSide
                .color;
        expect(border, scheme.outline);
        final well = over(
          theme.extension<OmnisonicSurfaces>()!.well,
          scheme.surface,
        );
        expect(contrast(border, scheme.surface), greaterThanOrEqualTo(3));
        expect(contrast(border, well), greaterThanOrEqualTo(3));
      });
    }
  });

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets('golden: form controls (${mode.name})', (t) async {
      final controller = TextEditingController(text: 'Kind of');
      final node = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(node.dispose);
      await pumpPage(
        t,
        Builder(
          builder: (context) => Material(
            color: Theme.of(context).colorScheme.surface,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SearchField(
                  controller: controller,
                  hint: 'Search albums',
                  focusNode: node,
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Server URL',
                    helperText: 'Include the port',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  autovalidateMode: AutovalidateMode.always,
                  validator: (_) => 'Enter a valid URL',
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Albums'),
                      selected: true,
                      onSelected: (_) {},
                    ),
                    FilterChip(
                      label: const Text('Artists'),
                      selected: false,
                      onSelected: (_) {},
                    ),
                    ChoiceChip(
                      label: const Text('All servers'),
                      selected: true,
                      onSelected: (_) {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OmnisonicSegmented<int>(
                  selected: 1,
                  onChanged: (_) {},
                  options: const [
                    SegmentOption(
                      value: 0,
                      label: 'Light',
                      icon: Icons.light_mode,
                    ),
                    SegmentOption(
                      value: 1,
                      label: 'Dark',
                      icon: Icons.dark_mode,
                    ),
                    SegmentOption(
                      value: 2,
                      label: 'Auto',
                      icon: Icons.brightness_auto,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RadioGroup<int>(
                  groupValue: 1,
                  onChanged: (_) {},
                  child: Row(
                    children: [
                      Switch(value: true, onChanged: (_) {}),
                      Switch(value: false, onChanged: (_) {}),
                      Checkbox(value: true, onChanged: (_) {}),
                      Checkbox(value: false, onChanged: (_) {}),
                      const Radio<int>(value: 1),
                      const Radio<int>(value: 2),
                    ],
                  ),
                ),
                Slider(value: 0.4, onChanged: (_) {}),
              ],
            ),
          ),
        ),
        themeMode: mode,
        size: const Size(400, 900),
        settle: false,
        disableAnimations: true,
      );
      node.requestFocus();
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(ListView),
        matchesGoldenFile('goldens/form_controls_${mode.name}.png'),
      );
    });
  }
}
