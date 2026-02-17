import '../entities/entities.dart';
import '../errors/result.dart';

abstract class LyricsRepository {
  Future<Result<LyricsData?>> getBestLyrics(
    Track track, {
    LyricsSource? preferredSource,
  });

  Future<Result<LyricsData?>> getLyricsById(
    LyricsSource source,
    String id,
    Track track,
  );

  Future<Result<LyricsData?>> getLyricsByArtistTitle(
    LyricsSource source,
    String artist,
    String title,
    Track track,
  );

  Future<Result<List<LyricsSearchResult>>> searchLyrics({
    required String artist,
    required String title,
    String? album,
    String? query,
  });

  Future<Result<LyricsData?>> getCachedLyrics(String trackId);
  Future<Result<void>> setCachedLyrics(String trackId, LyricsData data);

  Future<Result<LyricsOverride?>> getOverride(String trackId);
  Future<Result<void>> setOverride(String trackId, LyricsOverride? override);

  Future<Result<int>> getOffsetMs(String trackId);
  Future<Result<void>> setOffsetMs(String trackId, int offsetMs);

  Future<Result<LyricsSource?>> getPreferredSource();
  Future<Result<void>> setPreferredSource(LyricsSource? source);
}
