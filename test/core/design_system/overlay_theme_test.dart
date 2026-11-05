import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';

import 'package:omnisonic/features/ui/presentation/widgets/chips.dart';

import 'contrast_test.dart' show contrast, over;

/// docs/design-system.md §9.7, in both themes.
void main() {
  for (final entry in {
    Brightness.dark: OmnisonicTheme.darkTheme,
    Brightness.light: OmnisonicTheme.lightTheme,
  }.entries) {
    final theme = entry.value;
    final scheme = theme.colorScheme;
    final surfaces = theme.extension<OmnisonicSurfaces>()!;

    group(entry.key.name, () {
      test('dialog: L3, opaque, radius 24, hairline, at most 440 wide', () {
        final d = theme.dialogTheme;
        expect(d.backgroundColor, scheme.surfaceContainerHigh);
        expect(d.backgroundColor!.a, 1);
        expect(d.constraints!.maxWidth, 440);
        final shape = d.shape as RoundedRectangleBorder;
        expect(
          shape.borderRadius,
          BorderRadius.circular(OmnisonicRadius.overlay),
        );
        expect(shape.side.color, surfaces.hairline);
        expect(
          d.titleTextStyle!.fontSize,
          OmnisonicTypography.overlayTitle.fontSize,
        );
        expect(d.shadowColor, OmnisonicColors.overlayShadow);
      });

      test(
        'bottom sheet: L3, 24 on top, 36 x 4 handle in the outline colour',
        () {
          final b = theme.bottomSheetTheme;
          expect(b.backgroundColor, scheme.surfaceContainerHigh);
          expect(b.backgroundColor!.a, 1);
          expect(
            (b.shape as RoundedRectangleBorder).borderRadius,
            const BorderRadius.vertical(
              top: Radius.circular(OmnisonicRadius.overlay),
            ),
          );
          expect(b.showDragHandle, isTrue);
          expect(b.dragHandleSize, const Size(36, 4));
          expect(b.dragHandleColor, scheme.outline);
        },
      );

      test('menu and popup: L3, radius 12, items 44 tall, hover = well', () {
        final m = theme.menuTheme.style!;
        expect(m.backgroundColor!.resolve({}), scheme.surfaceContainerHigh);
        final shape = m.shape!.resolve({}) as RoundedRectangleBorder;
        expect(
          shape.borderRadius,
          BorderRadius.circular(OmnisonicRadius.control),
        );

        final item = theme.menuButtonTheme.style!;
        expect(item.minimumSize!.resolve({})!.height, 44);
        expect(
          item.overlayColor!.resolve({WidgetState.hovered}),
          surfaces.well,
        );
        expect(
          item.overlayColor!.resolve({WidgetState.focused}),
          surfaces.well,
        );
        expect(
          item.overlayColor!.resolve({WidgetState.pressed}),
          surfaces.wellHover,
        );
        expect(item.overlayColor!.resolve({}), isNull);

        final p = theme.popupMenuTheme;
        expect(p.color, scheme.surfaceContainerHigh);
        expect(
          (p.shape as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(OmnisonicRadius.control),
        );
      });

      test(
        'snackbar: inverse surface, radius 12, floating, inversePrimary action',
        () {
          final s = theme.snackBarTheme;
          expect(s.backgroundColor, scheme.inverseSurface);
          expect(s.behavior, SnackBarBehavior.floating);
          expect(
            (s.shape as RoundedRectangleBorder).borderRadius,
            BorderRadius.circular(OmnisonicRadius.control),
          );
          expect(s.actionTextColor, scheme.inversePrimary);
        },
      );

      test('tooltip: inverse surface, radius 8, bodySmall, 500 ms', () {
        final t = theme.tooltipTheme;
        expect((t.decoration as BoxDecoration).color, scheme.inverseSurface);
        expect(
          (t.decoration as BoxDecoration).borderRadius,
          BorderRadius.circular(OmnisonicRadius.sm),
        );
        expect(t.textStyle!.fontSize, OmnisonicTypography.bodySmall.fontSize);
        expect(t.waitDuration, const Duration(milliseconds: 500));
      });
    });
  }

  group('semantic colours (§2.3) are readable where overlays put them', () {
    for (final entry in {
      Brightness.dark: OmnisonicColors.darkColorScheme,
      Brightness.light: OmnisonicColors.lightColorScheme,
    }.entries) {
      final b = entry.key;
      final scheme = entry.value;
      final dark = b == Brightness.dark;
      final canvas = scheme.surface;
      final surfaces = dark ? OmnisonicSurfaces.dark : OmnisonicSurfaces.light;
      final semantics = <String, Color>{
        'success': dark
            ? OmnisonicColors.success
            : OmnisonicColors.successAccessible,
        'warning': dark
            ? OmnisonicColors.warning
            : OmnisonicColors.warningAccessible,
        'error': dark ? OmnisonicColors.error : OmnisonicColors.errorAccessible,
        'info': dark ? OmnisonicColors.info : OmnisonicColors.infoAccessible,
      };

      for (final MapEntry(key: name, value: color) in semantics.entries) {
        test('${b.name} $name text on the canvas >= 4.5', () {
          expect(contrast(color, canvas), greaterThanOrEqualTo(4.5));
        });
        test('${b.name} $name label on its 14 % tinted chip >= 4.5', () {
          final fill = over(color.withValues(alpha: 0.14), canvas);
          expect(
            contrast(TintedChip.labelColorFor(color, scheme), fill),
            greaterThanOrEqualTo(4.5),
          );
        });
        test('${b.name} $name icon on a banner well >= 3', () {
          final well = over(surfaces.well, canvas);
          expect(contrast(color, well), greaterThanOrEqualTo(3));
        });
      }

      test('${b.name} snackbar icons and action read on the inverse bar', () {
        final bar = scheme.inverseSurface;
        final success = dark
            ? OmnisonicColors.successAccessible
            : OmnisonicColors.success;
        final error = dark
            ? OmnisonicColors.errorAccessible
            : OmnisonicColors.error;
        final info = dark
            ? OmnisonicColors.infoAccessible
            : OmnisonicColors.info;
        for (final c in [success, error, info]) {
          expect(contrast(c, bar), greaterThanOrEqualTo(3));
        }
        expect(
          contrast(scheme.onInverseSurface, bar),
          greaterThanOrEqualTo(4.5),
        );
        expect(contrast(scheme.inversePrimary, bar), greaterThanOrEqualTo(4.5));
      });

      test('${b.name} the sheet handle is visible enough on L3', () {
        expect(
          contrast(scheme.outline, scheme.surfaceContainerHigh),
          greaterThanOrEqualTo(3),
        );
      });
    }
  });
}
