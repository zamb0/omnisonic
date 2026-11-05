import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';

import '../../helpers/widget_harness.dart';

/// docs/design-system.md §9.7: dialogs, sheets, menus, snackbars, banners.
void main() {
  group('InlineBanner', () {
    Future<void> pumpBanner(
      WidgetTester t,
      BannerKind kind, {
      ThemeMode mode = ThemeMode.dark,
    }) => pumpPage(
      t,
      Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          type: MaterialType.transparency,
          child: InlineBanner(
            kind: kind,
            message: 'Something happened',
            title: 'Title',
          ),
        ),
      ),
      themeMode: mode,
      settle: false,
    );

    for (final kind in BannerKind.values) {
      testWidgets(
        '${kind.name}: a 3 px semantic bar and an icon, never colour alone',
        (t) async {
          await pumpBanner(t, kind);
          final bar = t
              .widgetList<ColoredBox>(
                find.descendant(
                  of: find.byType(InlineBanner),
                  matching: find.byType(ColoredBox),
                ),
              )
              .firstWhere(
                (b) =>
                    t.getSize(find.byWidget(b)).width ==
                    InlineBanner.bannerBarWidth,
              );
          expect(t.getSize(find.byWidget(bar)).width, 3);
          expect(
            find.descendant(
              of: find.byType(InlineBanner),
              matching: find.byType(Icon),
            ),
            findsOneWidget,
          );
          // The bar and the icon share the colour.
          final icon = t.widget<Icon>(
            find.descendant(
              of: find.byType(InlineBanner),
              matching: find.byType(Icon),
            ),
          );
          expect(icon.color, bar.color);
        },
      );
    }

    testWidgets('info takes the aqua role colour, not the accent', (t) async {
      await pumpBanner(t, BannerKind.info);
      final icon = t.widget<Icon>(
        find.descendant(
          of: find.byType(InlineBanner),
          matching: find.byType(Icon),
        ),
      );
      expect(icon.color, OmnisonicColors.info);
    });

    testWidgets('errors and successes are announced', (t) async {
      final handle = t.ensureSemantics();
      await pumpBanner(t, BannerKind.error);
      expect(
        t
            .getSemantics(find.text('Something happened'))
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      handle.dispose();
    });
  });

  group('TintedChip', () {
    testWidgets('fill is the semantic colour at 14 %', (t) async {
      await pumpPage(
        t,
        const Center(
          child: TintedChip(
            color: Color(0xFF4ADE9B),
            icon: Icons.check,
            label: 'Online',
          ),
        ),
        settle: false,
      );
      final box =
          t
                  .widget<Container>(
                    find.descendant(
                      of: find.byType(TintedChip),
                      matching: find.byType(Container),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(box.color!.a, closeTo(0.14, 0.01));
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
    });
  });

  group('showFeedback icons', () {
    Future<Icon> iconFor(
      WidgetTester t,
      FeedbackKind kind,
      ThemeMode mode,
    ) async {
      late BuildContext ctx;
      await pumpPage(
        t,
        Scaffold(
          body: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
        themeMode: mode,
        settle: false,
      );
      showFeedback(ctx, 'Done', kind: kind);
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      return t.widget<Icon>(
        find.descendant(of: find.byType(SnackBar), matching: find.byType(Icon)),
      );
    }

    testWidgets('on the dark theme\'s light bar: accessible semantic colours', (
      t,
    ) async {
      expect(
        (await iconFor(t, FeedbackKind.success, ThemeMode.dark)).color,
        OmnisonicColors.successAccessible,
      );
    });

    testWidgets('on the light theme\'s dark bar: vivid semantic colours', (
      t,
    ) async {
      expect(
        (await iconFor(t, FeedbackKind.success, ThemeMode.light)).color,
        OmnisonicColors.success,
      );
      await t.pumpWidget(const SizedBox());
      expect(
        (await iconFor(t, FeedbackKind.error, ThemeMode.light)).color,
        OmnisonicColors.error,
      );
    });
  });

  group('confirm dialog', () {
    Future<void> open(
      WidgetTester t, {
      required bool destructive,
      Size size = TestSizes.desktop,
    }) async {
      await pumpPage(
        t,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showConfirmDialog(
              context,
              title: 'Delete?',
              message: 'Gone for good.',
              confirmLabel: 'Delete',
              destructive: destructive,
            ),
            child: const Text('open'),
          ),
        ),
        size: size,
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
    }

    testWidgets('destructive confirmation is the error-filled button', (
      t,
    ) async {
      await open(t, destructive: true);
      expect(find.byType(OmnisonicButton), findsOneWidget);
      expect(
        t.widget<OmnisonicButton>(find.byType(OmnisonicButton)).variant,
        OmnisonicButtonVariant.destructive,
      );
    });

    testWidgets('a plain confirmation is the primary button', (t) async {
      await open(t, destructive: false);
      expect(find.byType(OmnisonicButton), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Delete'), findsOneWidget);
    });

    testWidgets('never wider than 440, even on a desktop window', (t) async {
      await open(t, destructive: false, size: const Size(1440, 900));
      final panel = find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(Material),
          )
          .first;
      expect(t.getSize(panel).width, lessThanOrEqualTo(440));
      expect(
        t.getSize(panel).width,
        greaterThan(200),
        reason: 'it is the dialog panel, not a barrier',
      );
    });
  });

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets('golden: dialog (${mode.name})', (t) async {
      await pumpPage(
        t,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showConfirmDialog(
              context,
              title: 'Remove server?',
              message:
                  'Its albums leave your collection. You can add it again later.',
              confirmLabel: 'Remove',
              destructive: true,
            ),
            child: const Text('open'),
          ),
        ),
        themeMode: mode,
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/overlay_dialog_${mode.name}.png'),
      );
    });

    testWidgets('golden: bottom sheet (${mode.name})', (t) async {
      await pumpPage(
        t,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.play_arrow),
                      title: Text('Play next'),
                    ),
                    ListTile(
                      leading: Icon(Icons.queue_music),
                      title: Text('Add to queue'),
                    ),
                    ListTile(
                      leading: Icon(Icons.favorite_border),
                      title: Text('Add to favorites'),
                    ),
                  ],
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
        themeMode: mode,
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/overlay_sheet_${mode.name}.png'),
      );
    });

    testWidgets('golden: snackbar and banners (${mode.name})', (t) async {
      late BuildContext ctx;
      await pumpPage(
        t,
        Scaffold(
          body: Builder(
            builder: (c) {
              ctx = c;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  InlineBanner(
                    kind: BannerKind.info,
                    title: 'Offline copy',
                    message: 'Showing what was cached.',
                  ),
                  SizedBox(height: 8),
                  InlineBanner(
                    kind: BannerKind.success,
                    message: 'Connected to Living Room.',
                  ),
                  SizedBox(height: 8),
                  InlineBanner(
                    kind: BannerKind.warning,
                    message: 'Backup is slow to answer.',
                  ),
                  SizedBox(height: 8),
                  InlineBanner(
                    kind: BannerKind.error,
                    message: 'Could not reach Attic.',
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TintedChip(
                        color: Color(0xFF4ADE9B),
                        icon: Icons.check_circle,
                        label: 'Online',
                      ),
                      TintedChip(
                        color: Color(0xFFFFC25C),
                        icon: Icons.sync,
                        label: 'Connecting',
                      ),
                      TintedChip(
                        color: Color(0xFFFF6B7F),
                        icon: Icons.cloud_off,
                        label: 'Offline',
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        themeMode: mode,
        settle: false,
      );
      showFeedback(
        ctx,
        'Playlist saved',
        kind: FeedbackKind.success,
        actionLabel: 'Undo',
        onAction: () {},
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/overlay_feedback_${mode.name}.png'),
      );
    });
  }
}
