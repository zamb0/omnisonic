import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/core/routing/app_router.dart';
import 'package:omnisonic/core/routing/destinations.dart';
import 'package:omnisonic/features/ui/presentation/widgets/account_menu.dart';
import 'package:omnisonic/features/ui/presentation/widgets/desktop_top_bar.dart';
import 'package:omnisonic/features/ui/presentation/widgets/nav_selection.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// The bottom bar and the sidebar used to declare their own destination
/// lists, and they disagreed about what existed. These tests pin the two to
/// the same source and cover the selection rules that used to lie.
void main() {
  TestViewModels models() {
    final vms = TestViewModels();
    vms.servers.emitServers([testServer()]);
    vms.library.emitCollection(albums: testAlbums(4), artists: testArtists(2));
    return vms;
  }

  group('destination table', () {
    test('every primary route is a real route constant', () {
      expect(AppDestinations.primary.map((d) => d.route), [
        AppRouter.home,
        AppRouter.search,
        AppRouter.library,
        AppRouter.playlistManagement,
      ]);
    });

    test('primary and secondary do not overlap', () {
      final primary = AppDestinations.primary.map((d) => d.route).toSet();
      final secondary = AppDestinations.secondary.map((d) => d.route).toSet();
      expect(primary.intersection(secondary), isEmpty);
    });

    test('detail routes keep their parent destination lit', () {
      expect(
        AppDestinations.selectedPrimaryIndex(AppRouter.albumDetail),
        AppDestinations.primary.indexWhere((d) => d.route == AppRouter.library),
      );
      expect(
        AppDestinations.selectedPrimaryIndex(AppRouter.artistDetail),
        AppDestinations.primary.indexWhere((d) => d.route == AppRouter.library),
      );
      expect(
        AppDestinations.selectedPrimaryIndex(AppRouter.playlistDetail),
        AppDestinations.primary.indexWhere(
          (d) => d.route == AppRouter.playlistManagement,
        ),
      );
    });

    test('a route outside the four selects nothing', () {
      // /queue used to fall through to the switch's default and light Home,
      // telling the user they were somewhere they weren't.
      expect(AppDestinations.selectedPrimaryIndex(AppRouter.queue), isNull);
      expect(
        AppDestinations.selectedPrimaryIndex(AppRouter.nowPlaying),
        isNull,
      );
    });

    test('secondary destinations are recognised as such', () {
      for (final route in [
        AppRouter.favorites,
        AppRouter.downloads,
        AppRouter.servers,
        AppRouter.settings,
      ]) {
        expect(
          AppDestinations.isSecondary(route),
          isTrue,
          reason: '$route should sit behind the account affordance',
        );
        expect(AppDestinations.selectedPrimaryIndex(route), isNull);
      }
    });
  });

  group('bottom bar', () {
    testWidgets('renders every primary destination plus the account button', (
      tester,
    ) async {
      await pumpShell(tester, size: TestSizes.phone, viewModels: models());

      for (final destination in AppDestinations.primary) {
        expect(
          find.text(destination.label),
          findsOneWidget,
          reason: '${destination.label} missing from the bottom bar',
        );
      }
      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets('on /queue no tab is selected', (tester) async {
      await pumpShell(
        tester,
        location: AppRouter.queue,
        size: TestSizes.phone,
        viewModels: models(),
      );

      for (final destination in AppDestinations.primary) {
        expect(
          tester
              .getSemantics(find.text(destination.label))
              .flagsCollection
              .isSelected,
          Tristate.isFalse,
          reason: '${destination.label} should not be lit on the queue page',
        );
      }
    });

    // Counterpart to the /queue case: without this, that test would pass
    // just as well if the pills never reported selection at all.
    testWidgets('on a detail route the parent tab is lit', (tester) async {
      await pumpShell(
        tester,
        location: AppRouter.albumDetail,
        size: TestSizes.phone,
        viewModels: models(),
      );

      expect(
        tester.getSemantics(find.text('Library')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(
        tester.getSemantics(find.text('Home')).flagsCollection.isSelected,
        Tristate.isFalse,
      );
    });

    testWidgets('the account sheet reaches every secondary destination', (
      tester,
    ) async {
      await pumpShell(tester, size: TestSizes.phone, viewModels: models());

      await tester.tap(find.byType(AccountButton));
      await tester.pumpAndSettle();

      for (final destination in AppDestinations.secondary) {
        expect(
          find.text(destination.label),
          findsOneWidget,
          reason: '${destination.label} missing from the account sheet',
        );
      }
    });
  });

  group('bottom bar indicator', () {
    // The animated position, not the widget's `left`, which is the target.
    Finder pill() => find.descendant(
      of: find.byType(AnimatedPositioned),
      matching: find.byType(DecoratedBox),
    );
    double pillCenter(WidgetTester t) => t.getCenter(pill()).dx;
    double labelCenter(WidgetTester t, String label) =>
        t.getCenter(find.text(label)).dx;
    double opacity(WidgetTester t) => t
        .widget<AnimatedOpacity>(
          find.descendant(
            of: find.byType(AnimatedPositioned),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

    testWidgets('is centred on the current item, then slides', (tester) async {
      await pumpShell(tester, size: TestSizes.phone, viewModels: models());
      expect(pillCenter(tester), closeTo(labelCenter(tester, 'Home'), 0.5));
      expect(opacity(tester), 1);
      final start = pillCenter(tester);

      await tester.tap(find.text('Library'));
      await tester.pump(); // navigation rebuilds; the slide starts here
      await tester.pump(const Duration(milliseconds: 80));
      final midway = pillCenter(tester);
      await tester.pumpAndSettle();
      final end = pillCenter(tester);

      expect(end, closeTo(labelCenter(tester, 'Library'), 0.5));
      expect(midway, greaterThan(start), reason: 'it has left Home');
      expect(midway, lessThan(end), reason: 'and is not there yet: it slides');
    });

    testWidgets('fades out where no slot is current', (tester) async {
      await pumpShell(
        tester,
        location: AppRouter.queue,
        size: TestSizes.phone,
        viewModels: models(),
      );
      expect(opacity(tester), 0);
    });

    testWidgets('a secondary page lights the Account slot', (tester) async {
      await pumpShell(
        tester,
        location: AppRouter.settings,
        size: TestSizes.phone,
        viewModels: models(),
      );
      expect(pillCenter(tester), closeTo(labelCenter(tester, 'Account'), 0.5));
      expect(opacity(tester), 1);
    });

    testWidgets('does not animate with reduce motion', (tester) async {
      await pumpShell(
        tester,
        size: TestSizes.phone,
        viewModels: models(),
        disableAnimations: true,
      );
      expect(
        tester
            .widget<AnimatedPositioned>(find.byType(AnimatedPositioned))
            .duration,
        Duration.zero,
      );
    });
  });

  group('desktop top bar', () {
    double glass(WidgetTester t) => t
        .widget<AnimatedOpacity>(
          find.descendant(
            of: find.byType(DesktopTopBar),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

    Future<void> pumpScrolling(WidgetTester tester) => pumpShell(
      tester,
      size: TestSizes.desktop,
      viewModels: models(),
      routes: testShellRoutes(
        builders: {
          AppRouter.home: (context, state) => ListView(
            children: [
              for (var i = 0; i < 60; i++)
                SizedBox(height: 56, child: Text('row $i')),
            ],
          ),
        },
      ),
    );

    testWidgets('is transparent at rest and turns to glass past 8 px', (
      tester,
    ) async {
      await pumpScrolling(tester);
      expect(glass(tester), 0);

      await tester.drag(find.byType(ListView), const Offset(0, -6));
      await tester.pumpAndSettle();
      expect(glass(tester), 0, reason: '6 px is under the threshold');

      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(glass(tester), 1);

      await tester.drag(find.byType(ListView), const Offset(0, 1000));
      await tester.pumpAndSettle();
      expect(glass(tester), 0, reason: 'back at the top it is bare again');
    });

    testWidgets('a carousel scrolling sideways does not trigger it', (
      tester,
    ) async {
      await pumpShell(
        tester,
        size: TestSizes.desktop,
        viewModels: models(),
        routes: testShellRoutes(
          builders: {
            AppRouter.home: (context, state) => ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < 60; i++)
                  SizedBox(width: 120, child: Text('c $i')),
              ],
            ),
          },
        ),
      );
      await tester.drag(find.byType(ListView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(glass(tester), 0);
    });
  });

  group('sidebar', () {
    // The account affordance has to exist in the rail too. Settings was
    // previously only reachable through DesktopTopBar, which is hidden below
    // 1024px, so 768-1023px had no route to it at all.
    for (final (name, size) in [
      ('rail', TestSizes.tablet),
      ('extended', TestSizes.desktop),
    ]) {
      testWidgets('$name mode can reach the account sheet', (tester) async {
        await pumpShell(tester, size: size, viewModels: models());

        await tester.tap(find.byType(AccountButton));
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Downloads'), findsOneWidget);
      });
    }

    testWidgets('extended mode shows the primary destinations', (tester) async {
      await pumpShell(tester, size: TestSizes.desktop, viewModels: models());

      // Library is unfolded into Albums/Artists here, which is the one
      // deliberate difference from the bottom bar.
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsWidgets);
      expect(find.text('Albums'), findsOneWidget);
      expect(find.text('Artists'), findsOneWidget);
      expect(find.text('Playlists'), findsOneWidget);
    });

    // The same grammar on the extended sidebar and the rail: a wellHover
    // pill, a filled icon and the 3 x 20 Aurora bar — never the ink pill.
    for (final (name, size) in [
      ('rail', TestSizes.tablet),
      ('extended', TestSizes.desktop),
    ]) {
      testWidgets('$name: only the current item shows the Aurora bar', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await pumpShell(tester, size: size, viewModels: models());

        final bars = tester
            .widgetList<AnimatedScale>(
              find.descendant(
                of: find.byType(AuroraBar),
                matching: find.byType(AnimatedScale),
              ),
            )
            .where((b) => b.scale == 1);
        expect(bars, hasLength(1), reason: 'exactly one item is current');
        expect(
          tester.getSemantics(find.text('Home')).flagsCollection.isSelected,
          Tristate.isTrue,
        );
        semantics.dispose();
      });

      testWidgets('$name: the selection is not the ink pill', (tester) async {
        await pumpShell(tester, size: size, viewModels: models());
        final surfaces = OmnisonicSurfaces.of(
          tester.element(find.text('Home').first),
        );
        final inked = tester
            .widgetList<Material>(find.byType(Material))
            .where((m) => m.color == surfaces.ink);
        expect(inked, isEmpty);
      });
    }
  });

  for (final (mode, expected) in [
    (ThemeMode.light, SystemUiOverlayStyle.dark),
    (ThemeMode.dark, SystemUiOverlayStyle.light),
  ]) {
    testWidgets('the status bar follows the ${mode.name} theme on every page', (
      tester,
    ) async {
      // Only AppBars set it otherwise: closing the always-dark Now Playing
      // left white status-bar text over Pearl on pages with their own title.
      await pumpShell(tester, viewModels: models(), themeMode: mode);
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
      );
      expect(region.value, expected);
    });
  }
}
