import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/features/ui/presentation/pages/album_detail_page.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/view_model_fakes.dart';
import '../../helpers/widget_harness.dart';

/// The desktop layout used to be a Row inside a single SliverToBoxAdapter,
/// which forced the track table to be an eager `for` loop over a Column: a
/// 500-track album built 500 rows before the first frame was shown, on a
/// page most of which is off screen.
void main() {
  /// A library fake whose getAlbumTracks answers with [tracks].
  ///
  /// The page loads its own tracks in initState rather than reading them off
  /// the view model, so the fake has to serve that call.
  FakeMusicLibraryViewModel libraryWith(List<Track> tracks) {
    final library = _TrackServingLibrary(tracks);
    library.emitCollection(albums: [testAlbum()]);
    return library;
  }

  testWidgets('a 500-track album builds only what fits on screen', (
    tester,
  ) async {
    final tracks = testTracks(500);
    final models = TestViewModels(library: libraryWith(tracks));
    models.servers.emitServers([testServer()]);

    await pumpPage(
      tester,
      AlbumDetailPage(album: testAlbum()),
      viewModels: models,
      size: TestSizes.desktop,
      settle: false,
    );
    await tester.pump();

    // Rows are InkWells; so are a few header controls, hence the loose
    // lower bound. What matters is that the count is a screenful plus the
    // viewport's cache extent, and nowhere near 500.
    final rows = find.byType(InkWell).evaluate().length;
    expect(rows, greaterThan(5), reason: 'the table did not render at all');
    expect(rows, lessThan(60), reason: 'the table is building eagerly again');
  });

  testWidgets('the column labels stay put while the rows scroll', (
    tester,
  ) async {
    final models = TestViewModels(library: libraryWith(testTracks(80)));
    models.servers.emitServers([testServer()]);

    await pumpPage(
      tester,
      AlbumDetailPage(album: testAlbum()),
      viewModels: models,
      size: TestSizes.desktop,
      settle: false,
    );
    await tester.pump();

    expect(find.text('TITLE'), findsOneWidget);

    await tester.drag(find.text('TITLE'), const Offset(0, -600));
    await tester.pump();

    expect(find.text('TITLE'), findsOneWidget);
  });

  testWidgets('the mobile layout still renders its track list', (tester) async {
    final models = TestViewModels(library: libraryWith(testTracks(30)));
    models.servers.emitServers([testServer()]);

    await pumpPage(
      tester,
      AlbumDetailPage(album: testAlbum()),
      viewModels: models,
      settle: false,
    );
    await tester.pump();

    expect(find.byType(TrackTile), findsWidgets);
    expect(find.byType(TrackTile).evaluate().length, lessThan(30));
  });
}

class _TrackServingLibrary extends FakeMusicLibraryViewModel {
  _TrackServingLibrary(this._tracks);

  final List<Track> _tracks;

  @override
  Future<List<Track>> getAlbumTracks(String albumId) async => _tracks;
}
