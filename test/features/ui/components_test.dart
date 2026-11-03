import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/repositories/playback_repository.dart' as repo;
import 'package:omnisonic/features/playback/presentation/widgets/transport_controls.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// #60: each shared component, on its own.
void main() {
  group('CoverArt', () {
    testWidgets('shows the placeholder with no URL, at the given size', (
      tester,
    ) async {
      await pumpPage(
        tester,
        const Center(
          child: CoverArt(url: null, size: 48, fallbackIcon: Icons.person),
        ),
        settle: false,
      );
      expect(tester.getSize(find.byType(CoverArt)), const Size(48, 48));
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('is excluded from semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPage(
        tester,
        const Center(child: CoverArt(url: null, size: 48)),
        settle: false,
      );
      expect(
        find.descendant(
          of: find.byType(CoverArt),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      handle.dispose();
    });
  });

  group('TrackRow', () {
    testWidgets('announces title, artist and length as one button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpPage(
        tester,
        Material(
          child: TrackRow(
            track: testTrack(title: 'So What', artist: 'Miles Davis'),
            onTap: () {},
          ),
        ),
        settle: false,
      );
      expect(
        find.bySemanticsLabel(RegExp('So What, Miles Davis, 3:24')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('long press, right-click and the more button show actions', (
      tester,
    ) async {
      var shown = 0;
      await pumpPage(
        tester,
        Material(
          child: TrackRow(
            track: testTrack(),
            onTap: () {},
            onShowActions: () => shown++,
          ),
        ),
        settle: false,
      );
      await tester.longPress(find.byType(TrackRow));
      await tester.tap(find.byType(TrackRow), buttons: kSecondaryButton);
      await tester.tap(find.byTooltip('More actions for Test Track'));
      await tester.pump();
      expect(shown, 3);
    });
  });

  testWidgets('StatusChip carries the label, not just a colour', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpPage(
      tester,
      const Center(child: StatusChip(status: ServerStatus.offline)),
      settle: false,
    );
    expect(find.text('Offline'), findsOneWidget);
    expect(find.bySemanticsLabel('Status: Offline'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('InlineBanner shows its title, message and action', (
    tester,
  ) async {
    await pumpPage(
      tester,
      Center(
        child: InlineBanner(
          kind: BannerKind.error,
          title: 'Failed',
          message: 'Could not connect.',
          action: TextButton(onPressed: () {}, child: const Text('Retry')),
        ),
      ),
      settle: false,
    );
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Could not connect.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  group('DetailHeader', () {
    Widget header() => SingleChildScrollView(
      child: DetailHeader(
        title: 'A title',
        artwork: const ColoredBox(color: Color(0xFF000000)),
        actions: [
          FilledButton(onPressed: () {}, child: const Text('Play')),
          OutlinedButton(onPressed: () {}, child: const Text('Shuffle')),
          OutlinedButton(onPressed: () {}, child: const Text('Download')),
        ],
      ),
    );

    testWidgets('stacks with the smaller title on a phone', (tester) async {
      await pumpPage(tester, header(), size: const Size(360, 640));
      final title = tester.widget<Text>(find.text('A title'));
      expect(title.style!.fontSize, OmnisonicTypography.sectionTitle.fontSize);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sits beside the artwork with the page title when wide', (
      tester,
    ) async {
      await pumpPage(tester, header(), size: TestSizes.desktop);
      final title = tester.widget<Text>(find.text('A title'));
      expect(title.style!.fontSize, OmnisonicTypography.pageTitle.fontSize);
    });
  });

  testWidgets('showConfirmDialog resolves true only on confirm', (
    tester,
  ) async {
    bool? result;
    await pumpPage(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showConfirmDialog(
            context,
            title: 'Delete?',
            message: 'Gone for good.',
            confirmLabel: 'Delete',
            destructive: true,
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  test('repeat modes differ by icon, not only by colour', () {
    final icons = {
      for (final mode in repo.RepeatMode.values)
        PlaybackModeVisuals.repeatIcon(mode),
    };
    expect(icons, hasLength(repo.RepeatMode.values.length));
    expect(
      PlaybackModeVisuals.shuffleIcon(true),
      isNot(PlaybackModeVisuals.shuffleIcon(false)),
    );
  });
}
