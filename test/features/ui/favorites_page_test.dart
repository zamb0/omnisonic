import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:omnisonic/core/entities/audio_quality.dart';
import 'package:omnisonic/core/entities/track.dart';
import 'package:omnisonic/features/music/presentation/viewmodels/music_library_view_model.dart';
import 'package:omnisonic/features/playback/presentation/viewmodels/playback_view_model.dart';
import 'package:omnisonic/features/ui/presentation/pages/favorites_page.dart';
import 'package:provider/provider.dart';

import 'favorites_page_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<PlaybackViewModel>(),
  MockSpec<MusicLibraryViewModel>(),
])
void main() {
  late MockPlaybackViewModel playback;
  late MockMusicLibraryViewModel library;

  Track track(String id) => Track(
    id: id,
    title: 'Song $id',
    artist: 'Artist',
    album: 'Album',
    duration: const Duration(minutes: 3),
    serverId: 'server1',
    streamUrl: 'http://example.com/$id',
    quality: AudioQuality.high,
    lastModified: DateTime(2026),
  );

  final tracks = [track('t1'), track('t2'), track('t3')];

  setUp(() {
    playback = MockPlaybackViewModel();
    library = MockMusicLibraryViewModel();

    when(library.isLoading).thenReturn(false);
    when(library.starredAlbums).thenReturn([]);
    when(library.starredArtists).thenReturn([]);
    when(library.starredTracks).thenReturn(tracks);
    when(
      playback.playTrack(
        any,
        queue: anyNamed('queue'),
        startIndex: anyNamed('startIndex'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PlaybackViewModel>.value(value: playback),
          ChangeNotifierProvider<MusicLibraryViewModel>.value(value: library),
        ],
        child: const MaterialApp(home: FavoritesPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a starred track plays it with the full list as queue', (
    tester,
  ) async {
    await pumpPage(tester);

    // Tracks are the third tab.
    await tester.tap(find.text('Tracks'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Song t2'));
    await tester.pump();

    // This used to be an empty method body with a TODO, so nothing happened.
    final call = verify(
      playback.playTrack(
        captureAny,
        queue: captureAnyNamed('queue'),
        startIndex: captureAnyNamed('startIndex'),
      ),
    )..called(1);

    expect((call.captured[0] as Track).id, 't2');
    expect((call.captured[1] as List<Track>).map((t) => t.id), [
      't1',
      't2',
      't3',
    ]);
    expect(call.captured[2], 1);
  });
}
