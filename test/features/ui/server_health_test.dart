import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/features/ui/presentation/widgets/account_menu.dart';
import 'package:omnisonic/features/ui/presentation/widgets/chips.dart';
import 'package:omnisonic/features/ui/presentation/widgets/server_health.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

void main() {
  group('ServerHealth.of', () {
    test('no servers -> none', () {
      expect(ServerHealth.of(const []), ServerHealth.none);
      expect(ServerHealth.none.status, isNull);
    });
    test('online and syncing -> healthy', () {
      expect(
        ServerHealth.of([ServerStatus.online, ServerStatus.syncing]),
        ServerHealth.healthy,
      );
    });
    test('one unreachable or still connecting -> degraded', () {
      expect(
        ServerHealth.of([ServerStatus.online, ServerStatus.offline]),
        ServerHealth.degraded,
      );
      expect(
        ServerHealth.of([ServerStatus.online, ServerStatus.connecting]),
        ServerHealth.degraded,
      );
      expect(
        ServerHealth.of([ServerStatus.online, ServerStatus.error]),
        ServerHealth.degraded,
      );
    });
    test('all unreachable -> down', () {
      expect(
        ServerHealth.of([ServerStatus.offline, ServerStatus.error]),
        ServerHealth.down,
      );
    });
  });

  group('account avatar ring', () {
    Future<void> pumpWith(
      WidgetTester tester,
      List<MusicServer> servers,
    ) async {
      final models = TestViewModels();
      models.servers.emitServers(servers);
      models.library.emitCollection(
        albums: testAlbums(2),
        artists: testArtists(1),
      );
      await pumpShell(tester, size: TestSizes.phone, viewModels: models);
    }

    Border? ringOf(WidgetTester tester) {
      final box = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(AccountButton),
          matching: find.byType(Container),
        ),
      );
      for (final c in box) {
        final d = c.decoration;
        if (d is BoxDecoration && d.shape == BoxShape.circle) {
          return d.border as Border?;
        }
      }
      return null;
    }

    testWidgets('no servers: no ring, and the label says so', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpWith(tester, const []);
      expect(ringOf(tester), isNull);
      expect(
        find.bySemanticsLabel('Account and settings, no servers configured'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('healthy: success ring, announced', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpWith(tester, [testServer(status: ServerStatus.online)]);
      final ring = ringOf(tester)!;
      expect(
        ring.top.color,
        ServerStatusVisuals.of(
          tester.element(find.byType(AccountButton)),
          ServerStatus.online,
        ).color,
      );
      expect(
        find.bySemanticsLabel('Account and settings, all servers online'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('offline server: error ring, announced', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpWith(tester, [testServer(status: ServerStatus.offline)]);
      expect(
        ringOf(tester)!.top.color,
        ServerStatusVisuals.of(
          tester.element(find.byType(AccountButton)),
          ServerStatus.offline,
        ).color,
      );
      expect(
        find.bySemanticsLabel('Account and settings, no server reachable'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
