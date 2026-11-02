import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/routing/app_router.dart';
import 'package:omnisonic/core/routing/destinations.dart';
import 'package:omnisonic/features/ui/presentation/widgets/account_menu.dart';

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
  });
}
