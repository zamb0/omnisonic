import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/features/music/presentation/pages/playlist_detail_page.dart';
import 'package:omnisonic/features/music/presentation/widgets/playlist_form_dialog.dart';
import 'package:omnisonic/features/ui/presentation/widgets/track_row.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/widget_harness.dart';

/// #53, #58, #59: the playlist page and its form.
void main() {
  group('PlaylistDetailPage', () {
    Future<TestViewModels> pumpDetail(
      WidgetTester tester, {
      Size size = TestSizes.phone,
    }) async {
      final models = TestViewModels();
      final playlist = testPlaylist(name: 'A rather long playlist name');
      models.playlists.emitSelected(playlist, tracks: testTracks(5));
      await pumpPage(
        tester,
        PlaylistDetailPage(playlistId: playlist.id),
        viewModels: models,
        size: size,
        settle: false,
      );
      await tester.pump();
      return models;
    }

    testWidgets('fits a 360dp phone without overflow', (tester) async {
      await pumpDetail(tester, size: const Size(360, 640));
      expect(tester.takeException(), isNull);
      expect(find.text('Play'), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);
    });

    testWidgets('in reorder mode a tap does not play, and drags start at the '
        'handle only', (tester) async {
      final models = await pumpDetail(tester);

      await tester.tap(find.byTooltip('Reorder tracks'));
      await tester.pump();

      await tester.tap(find.byType(TrackRow).first);
      await tester.pump();
      expect(models.playback.playTrackCalls, isEmpty);

      // One handle per row, and nothing else is a drag listener.
      expect(find.byType(ReorderableDragStartListener), findsNWidgets(5));
      expect(find.byType(ReorderableDelayedDragStartListener), findsNothing);
    });

    testWidgets('a tap plays from that track outside reorder mode', (
      tester,
    ) async {
      final models = await pumpDetail(tester);
      await tester.tap(find.byType(TrackRow).at(2));
      await tester.pump();
      expect(models.playback.playTrackCalls.single.startIndex, 2);
    });
  });

  group('PlaylistFormDialog', () {
    Future<TestViewModels> pumpDialog(WidgetTester tester) async {
      final models = TestViewModels();
      await pumpPage(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showPlaylistFormDialog(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        viewModels: models,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return models;
    }

    testWidgets('refuses an empty name with a message', (tester) async {
      final models = await pumpDialog(tester);
      await tester.tap(find.text('Create'));
      await tester.pump();
      expect(find.text('Enter a name'), findsOneWidget);
      expect(models.playlists.savedNames, isEmpty);
    });

    testWidgets('Enter in the name field submits', (tester) async {
      final models = await pumpDialog(tester);
      await tester.enterText(find.byType(TextFormField).first, 'Road trip');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      expect(models.playlists.savedNames, ['Road trip']);
      expect(find.byType(PlaylistFormDialog), findsNothing);
    });
  });
}
