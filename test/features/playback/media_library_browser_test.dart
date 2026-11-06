import 'package:audio_service/audio_service.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/errors/failures.dart';
import 'package:omnisonic/core/repositories/music_repository.dart';
import 'package:omnisonic/core/repositories/playlist_repository.dart';
import 'package:omnisonic/core/usecases/play_track_use_case.dart';
import 'package:omnisonic/features/playback/data/datasources/media_library_browser.dart';

import 'media_library_browser_test.mocks.dart';

@GenerateMocks([MusicRepository, PlaylistRepository, PlayTrackUseCase])
void main() {
  late MockMusicRepository music;
  late MockPlaylistRepository playlists;
  late MockPlayTrackUseCase playTrack;
  late MediaLibraryBrowser browser;

  final now = DateTime(2026);

  Track track(String id) => Track(
    id: id,
    title: 'Title $id',
    artist: 'Artist',
    album: 'Album',
    duration: const Duration(minutes: 3),
    serverId: 's1',
    streamUrl: 'http://x/$id',
    quality: AudioQuality.high,
    lastModified: now,
  );

  // IDs with `/` and `_` must survive the media-ID round trip.
  const albumId = 's1_al/1';
  final albumTracks = [track('s1_a'), track('s1_b/2'), track('s1_c')];

  setUp(() {
    music = MockMusicRepository();
    playlists = MockPlaylistRepository();
    playTrack = MockPlayTrackUseCase();
    browser = MediaLibraryBrowser(
      musicRepository: music,
      playlistRepository: playlists,
      playTrackUseCase: playTrack,
    );
    when(
      music.getAlbumTracks(albumId),
    ).thenAnswer((_) async => Right(albumTracks));
    when(playTrack(any)).thenAnswer((_) async => const Right(null));
  });

  test('root exposes at most four browsable tabs', () async {
    final items = await browser.getChildren(AudioService.browsableRootId);
    expect(items.map((i) => i.id), [
      MediaLibraryBrowser.home,
      MediaLibraryBrowser.albums,
      MediaLibraryBrowser.artists,
      MediaLibraryBrowser.playlists,
    ]);
    expect(items.every((i) => i.playable == false), isTrue);
  });

  test('albums tab lists albums sorted by title as browsable items', () async {
    when(music.getAllAlbums()).thenAnswer(
      (_) async => Right([
        Album(
          id: 'b',
          title: 'beta',
          artist: 'x',
          serverId: 's1',
          lastModified: now,
        ),
        Album(
          id: albumId,
          title: 'Alpha',
          artist: 'x',
          serverId: 's1',
          lastModified: now,
        ),
      ]),
    );

    final items = await browser.getChildren(MediaLibraryBrowser.albums);

    expect(items.map((i) => i.title), ['Alpha', 'beta']);
    final children = await browser.getChildren(items.first.id);
    expect(children, hasLength(3));
    expect(children.every((i) => i.playable == true), isTrue);
  });

  test(
    'playing an album track queues the whole album from that track',
    () async {
      final items = await browser.getChildren(
        MediaLibraryBrowser.encodeId(['album', albumId]),
      );

      final ok = await browser.playFromMediaId(items[1].id);

      expect(ok, isTrue);
      final params =
          verify(playTrack(captureAny)).captured.single as PlayTrackParams;
      expect(params.track.id, 's1_b/2');
      expect(params.queue, albumTracks);
      expect(params.startIndex, 1);
    },
  );

  test('unknown or non-track media IDs do not start playback', () async {
    expect(await browser.playFromMediaId(MediaLibraryBrowser.albums), isFalse);
    expect(
      await browser.playFromMediaId(
        MediaLibraryBrowser.trackMediaId('album', albumId, 'missing'),
      ),
      isFalse,
    );
    verifyNever(playTrack(any));
  });

  test(
    'voice search plays the first matching track with results as queue',
    () async {
      when(
        music.searchTracks('beta'),
      ).thenAnswer((_) async => Right(albumTracks));

      expect(await browser.playFromSearch('beta'), isTrue);

      final params =
          verify(playTrack(captureAny)).captured.single as PlayTrackParams;
      expect(params.startIndex, 0);
      expect(params.queue, albumTracks);
    },
  );

  test('repository failures yield an empty list instead of throwing', () async {
    when(
      music.getAllArtists(),
    ).thenAnswer((_) async => const Left(DatabaseFailure('boom')));
    expect(await browser.getChildren(MediaLibraryBrowser.artists), isEmpty);
    expect(await browser.getChildren('nonsense'), isEmpty);
  });
}
