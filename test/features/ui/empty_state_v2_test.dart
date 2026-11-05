import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';

import '../../helpers/widget_harness.dart';

/// docs/design-system.md §9.8: empty and error states.
void main() {
  Future<void> pump(
    WidgetTester t,
    Widget w, {
    ThemeMode mode = ThemeMode.dark,
    Size size = TestSizes.phone,
  }) => pumpPage(t, w, themeMode: mode, size: size, settle: false);

  group('EmptyState', () {
    testWidgets(
      'an 80 px well disc with a 40 px icon and the auroraSoft ring',
      (t) async {
        await pump(
          t,
          const EmptyState(icon: Icons.inbox, title: 'Nothing here'),
        );
        final disc = t
            .widgetList<Container>(
              find.descendant(
                of: find.byType(EmptyState),
                matching: find.byType(Container),
              ),
            )
            .firstWhere(
              (c) => (c.decoration as BoxDecoration?)?.shape == BoxShape.circle,
            );
        expect(t.getSize(find.byWidget(disc)), const Size(80, 80));
        expect(
          (disc.decoration as BoxDecoration).color,
          OmnisonicSurfaces.dark.well,
        );
        expect(
          t.widget<Icon>(find.byIcon(Icons.inbox)).size,
          OmnisonicIconSizes.xl,
        );
        expect(find.byType(AuroraRing), findsOneWidget);
        final ring = t.getRect(find.byType(AuroraRing));
        expect(
          ring.width,
          80 + EmptyState.ringGap * 2,
          reason: 'the ring floats just outside the disc',
        );
      },
    );

    testWidgets('the mesh fades out toward its edges', (t) async {
      await pump(t, const EmptyState(icon: Icons.inbox, title: 'Nothing here'));
      expect(t.widget<AuroraMesh>(find.byType(AuroraMesh)).vignette, isTrue);
      expect(
        find.descendant(
          of: find.byType(AuroraMesh),
          matching: find.byType(ShaderMask),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the title is a groupTitle', (t) async {
      await pump(t, const EmptyState(icon: Icons.inbox, title: 'Nothing here'));
      expect(
        t.widget<Text>(find.text('Nothing here')).style!.fontSize,
        OmnisonicTypography.groupTitle.fontSize,
      );
    });

    testWidgets('a soft mesh sits behind, still', (t) async {
      await pump(t, const EmptyState(icon: Icons.inbox, title: 'Nothing here'));
      final mesh = t.widget<AuroraMesh>(find.byType(AuroraMesh));
      expect(mesh.opacity, EmptyState.meshOpacity);
      expect(mesh.drift, isFalse);
    });

    testWidgets('the mesh and ring are decorative: not announced', (t) async {
      final h = t.ensureSemantics();
      await pump(
        t,
        const EmptyState(
          icon: Icons.inbox,
          title: 'Nothing here',
          subtitle: 'Add some.',
        ),
      );
      expect(find.bySemanticsLabel('Nothing here'), findsOneWidget);
      h.dispose();
    });

    testWidgets('the one action can be the Aurora signature', (t) async {
      var taps = 0;
      await pump(
        t,
        EmptyState(
          icon: Icons.dns,
          title: 'No server',
          action: AuroraButton(label: 'Add server', onPressed: () => taps++),
        ),
      );
      await t.tap(find.byType(AuroraButton));
      expect(taps, 1);
    });

    testWidgets('hero: the wordmark above, a drifting full-strength mesh', (
      t,
    ) async {
      await pump(
        t,
        const EmptyState(hero: true, icon: Icons.dns, title: 'No server'),
      );
      expect(find.text('Omnisonic'), findsOneWidget);
      final mesh = t.widget<AuroraMesh>(find.byType(AuroraMesh));
      expect(mesh.opacity, EmptyState.heroMeshOpacity);
      expect(mesh.drift, isTrue);
    });

    testWidgets('fits a short window with long copy at 2x text', (t) async {
      await pumpPage(
        t,
        const EmptyState(
          icon: Icons.dns,
          title: 'No music server yet',
          subtitle:
              'Add a Subsonic-compatible server to start browsing and playing your library.',
        ),
        size: const Size(360, 480),
        textScale: 2,
        settle: false,
      );
      expect(t.takeException(), isNull);
    });
  });

  group('ErrorStateView', () {
    testWidgets('the icon is the error colour, retry is tonal', (t) async {
      var retried = 0;
      await pump(
        t,
        ErrorStateView(message: 'Server said no', onRetry: () => retried++),
      );
      expect(
        t.widget<Icon>(find.byIcon(OmnisonicIcons.errorOutline)).color,
        OmnisonicTheme.darkTheme.colorScheme.error,
      );
      final retry = t.widget<OmnisonicButton>(find.byType(OmnisonicButton));
      expect(retry.variant, OmnisonicButtonVariant.tonal);
      expect(find.byType(AuroraButton), findsNothing);
      await t.tap(find.text('Try again'));
      expect(retried, 1);
    });
  });

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets('golden: empty, hero and error states (${mode.name})', (
      t,
    ) async {
      await pumpPage(
        t,
        Builder(
          builder: (context) => Material(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                Expanded(
                  child: EmptyState(
                    icon: OmnisonicIcons.dnsOutline,
                    title: 'No music server yet',
                    subtitle:
                        'Add a Subsonic-compatible server to start browsing.',
                    action: AuroraButton(
                      label: 'Add server',
                      icon: OmnisonicIcons.add,
                      onPressed: () {},
                    ),
                  ),
                ),
                Expanded(
                  child: ErrorStateView(
                    message: 'Could not reach the server.',
                    onRetry: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
        size: const Size(400, 900),
        themeMode: mode,
        settle: false,
        disableAnimations: true,
      );
      await t.pump();
      await expectLater(
        find.byType(Column).first,
        matchesGoldenFile('goldens/empty_error_${mode.name}.png'),
      );
    });
  }
}
