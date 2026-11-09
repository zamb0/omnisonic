import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/routing/app_router.dart';
import 'package:omnisonic/features/ui/presentation/pages/album_detail_page.dart';
import 'package:omnisonic/features/ui/presentation/widgets/widgets.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/view_model_fakes.dart';
import '../../helpers/widget_harness.dart';

/// Visual artifacts on the desktop album page and the shell around it.
void main() {
  const wide = Size(2000, 1063);

  final album = testAlbum(id: 'zambo_a1', serverId: 'zambo');
  final copy = testAlbum(id: 'pusi_a1', serverId: 'pusi');

  List<Track> tracksOn(
    String server,
    String albumId,
    AudioQuality quality, {
    int count = 4,
  }) => [
    for (var i = 1; i <= count; i++)
      testTrack(
        id: '${server}_t$i',
        serverId: server,
        albumId: albumId,
        trackNumber: i,
        quality: quality,
      ),
  ];

  Future<TestViewModels> pumpAlbum(
    WidgetTester tester, {
    bool merged = false,
    int trackCount = 4,
  }) async {
    final library = _AlbumTracksLibrary([
      ...tracksOn('zambo', album.id, AudioQuality.lossless, count: trackCount),
      if (merged) ...tracksOn('pusi', copy.id, AudioQuality.high),
    ]);
    library.emitCollection(albums: [album, if (merged) copy]);
    final models = TestViewModels(library: library);
    models.servers.emitServers([
      testServer(id: 'zambo', name: 'zambo'),
      testServer(id: 'pusi', name: 'pusi'),
      testServer(
        id: '1a2b3c943021',
        name: 'memo',
        status: ServerStatus.offline,
      ),
    ]);
    await pumpShell(
      tester,
      location: AppRouter.albumDetailLocation(album.id),
      size: wide,
      viewModels: models,
      settle: false,
      routes: testShellRoutes(
        builders: {
          AppRouter.albumDetail: (_, _) => AlbumDetailPage(album: album),
        },
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return models;
  }

  testWidgets('the header takes the whole column, not just its text', (
    tester,
  ) async {
    await pumpAlbum(tester);
    // Inside a start-aligned column the header used to shrink to its title,
    // and the tint behind it stopped in a hard edge just past it.
    final header = tester.getSize(find.byType(DetailHeader));
    final table = tester.getSize(find.text('TITLE').hitTestable());
    expect(header.width, greaterThan(1000));
    expect(table.width, lessThan(header.width));
  });

  testWidgets('the shell carries the header tint above the scroll view', (
    tester,
  ) async {
    await pumpAlbum(tester, trackCount: 60);
    final strip = tester.widget<TopWashStrip>(find.byType(TopWashStrip));
    expect(strip.wash.color, isNotNull);
    expect(strip.wash.color!.a, greaterThan(0));

    // Scrolled far past the header, nothing is left to carry.
    await tester.drag(find.text('TITLE'), const Offset(0, -2000));
    await tester.pump();
    expect(strip.wash.color, isNull);
  });

  testWidgets('a single-server album has no SOURCE column of dashes', (
    tester,
  ) async {
    await pumpAlbum(tester);
    expect(find.text('SOURCE'), findsNothing);
    expect(find.text('—'), findsNothing);
  });

  testWidgets('a merged album names every server that has the track', (
    tester,
  ) async {
    await pumpAlbum(tester, merged: true);
    expect(find.text('SOURCE'), findsWidgets);
    expect(find.textContaining('zambo · pusi'), findsWidgets);
  });

  testWidgets('the FORMAT column fits "FLAC · Lossless"', (tester) async {
    await pumpAlbum(tester);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.text(AudioQuality.lossless.displayName).first,
    );
    expect(paragraph.didExceedMaxLines, isFalse);
  });

  testWidgets('sidebar servers show status, not an ID fragment', (
    tester,
  ) async {
    await pumpAlbum(tester);
    // The last six characters of the ID read as a track count.
    expect(find.text('943021'), findsNothing);
    expect(find.text('offline'), findsOneWidget);
  });

  testWidgets('a wide header puts [below] under the cover, not beside it', (
    tester,
  ) async {
    await pumpPage(
      tester,
      SingleChildScrollView(
        child: DetailHeader(
          title: 'A title',
          artwork: const ColoredBox(key: Key('art'), color: Colors.black),
          below: const SizedBox(key: Key('below'), height: 300),
        ),
      ),
      size: TestSizes.desktop,
    );
    // In the text column it made the column taller than the cover, and the
    // bottom-aligned cover sank, leaving a hole above it.
    expect(
      tester.getTopLeft(find.byKey(const Key('below'))).dy,
      greaterThan(tester.getBottomLeft(find.byKey(const Key('art'))).dy),
    );
  });
}

class _AlbumTracksLibrary extends FakeMusicLibraryViewModel {
  _AlbumTracksLibrary(this._tracks);

  final List<Track> _tracks;

  @override
  Future<List<Track>> getAlbumTracks(String albumId) async =>
      _tracks.where((t) => t.albumId == albumId).toList();
}
