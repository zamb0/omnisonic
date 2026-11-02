import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:omnisonic/core/entities/audio_quality.dart';
import 'package:omnisonic/core/entities/track.dart';
import 'package:omnisonic/core/errors/result.dart';
import 'package:omnisonic/core/repositories/music_repository.dart';
import 'package:omnisonic/core/usecases/search_music_use_case.dart';

import 'search_music_use_case_test.mocks.dart';

@GenerateMocks([MusicRepository])
void main() {
  late MockMusicRepository repository;
  late SearchMusicUseCase useCase;

  Track track(
    String id, {
    String genre = 'Rock',
    int year = 2020,
    String serverId = 'server1',
    AudioQuality quality = AudioQuality.high,
  }) => Track(
    id: id,
    title: 'Song $id',
    artist: 'Artist',
    album: 'Album',
    duration: const Duration(minutes: 3),
    serverId: serverId,
    streamUrl: 'http://example.com/$id',
    quality: quality,
    lastModified: DateTime(2026),
    genre: genre,
    year: year,
  );

  setUp(() {
    repository = MockMusicRepository();
    useCase = SearchMusicUseCase(repository);

    when(
      repository.searchAlbums(any),
    ).thenAnswer((_) async => ResultHelper.success([]));
    when(
      repository.searchArtists(any),
    ).thenAnswer((_) async => ResultHelper.success([]));
  });

  test(
    'returns empty results for a blank query without hitting the repository',
    () async {
      final result = await useCase(const SearchMusicParams(query: '   '));

      expect(result.isRight(), isTrue);
      verifyNever(repository.searchTracks(any));
    },
  );

  test('searches the local library even with no server reachable', () async {
    // The use case used to bail out with a ServerFailure whenever
    // getOnlineServers came back empty, which broke search offline.
    when(
      repository.searchTracks('rock'),
    ).thenAnswer((_) async => ResultHelper.success([track('t1')]));

    final result = await useCase(const SearchMusicParams(query: 'rock'));

    final results = result.getOrElse(
      () => throw StateError('expected results'),
    );
    expect(results.tracks.map((t) => t.id), ['t1']);
  });

  test('applies the genre, year, server and quality filters', () async {
    when(repository.searchTracks('rock')).thenAnswer(
      (_) async => ResultHelper.success([
        track('keep'),
        track('wrong-genre', genre: 'Jazz'),
        track('wrong-year', year: 1999),
        track('wrong-server', serverId: 'server2'),
        track('too-low', quality: AudioQuality.low),
      ]),
    );

    final result = await useCase(
      const SearchMusicParams(
        query: 'rock',
        genre: 'Rock',
        year: 2020,
        serverId: 'server1',
        minQuality: AudioQuality.high,
      ),
    );

    final results = result.getOrElse(
      () => throw StateError('expected results'),
    );
    expect(results.tracks.map((t) => t.id), ['keep']);
  });

  test('caps each result type at maxResults', () async {
    when(repository.searchTracks('rock')).thenAnswer(
      (_) async =>
          ResultHelper.success([for (var i = 0; i < 10; i++) track('t$i')]),
    );

    final result = await useCase(
      const SearchMusicParams(query: 'rock', maxResults: 3),
    );

    final results = result.getOrElse(
      () => throw StateError('expected results'),
    );
    expect(results.tracks, hasLength(3));
    expect(results.totalResults, 3);
  });
}
