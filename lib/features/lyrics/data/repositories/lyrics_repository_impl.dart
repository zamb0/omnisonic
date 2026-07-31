import '../../../../core/entities/entities.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/repositories/lyrics_repository.dart';
import '../datasources/lyrics_cache_data_source.dart';
import '../datasources/lyrics_remote_data_source.dart';

class LyricsRepositoryImpl implements LyricsRepository {
  LyricsRepositoryImpl({
    required LyricsRemoteDataSource remoteDataSource,
    required LyricsCacheDataSource cacheDataSource,
  }) : _remote = remoteDataSource,
       _cache = cacheDataSource;

  final LyricsRemoteDataSource _remote;
  final LyricsCacheDataSource _cache;

  @override
  Future<Result<LyricsData?>> getBestLyrics(
    Track track, {
    LyricsSource? preferredSource,
  }) async {
    try {
      LyricsData? data;

      if (preferredSource == LyricsSource.lyricsOvh) {
        data = await _remote.getLyricsOvh(
          artist: track.artist,
          title: track.title,
        );
      } else {
        data = await _remote.getLrclibBySignature(track);
      }

      if (data == null && preferredSource == null) {
        data = await _remote.getLyricsOvh(
          artist: track.artist,
          title: track.title,
        );
      }

      if (data != null && data.raw.trim().isNotEmpty) {
        await _cache.setCachedLyrics(track.id, data);
      }

      return ResultHelper.success(data);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to get lyrics: $e'));
    }
  }

  @override
  Future<Result<LyricsData?>> getLyricsById(
    LyricsSource source,
    String id,
    Track track,
  ) async {
    try {
      if (source != LyricsSource.lrclib) {
        return ResultHelper.failure(
          const ValidationFailure('Only LRCLIB supports lookup by ID'),
        );
      }

      final data = await _remote.getLrclibById(id);
      if (data != null && data.raw.trim().isNotEmpty) {
        await _cache.setCachedLyrics(track.id, data);
      }
      return ResultHelper.success(data);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to get lyrics: $e'));
    }
  }

  @override
  Future<Result<LyricsData?>> getLyricsByArtistTitle(
    LyricsSource source,
    String artist,
    String title,
    Track track,
  ) async {
    try {
      LyricsData? data;
      if (source == LyricsSource.lyricsOvh) {
        data = await _remote.getLyricsOvh(artist: artist, title: title);
      } else {
        data = await _remote.getLrclibBySignature(track);
      }

      if (data != null && data.raw.trim().isNotEmpty) {
        await _cache.setCachedLyrics(track.id, data);
      }
      return ResultHelper.success(data);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to get lyrics: $e'));
    }
  }

  @override
  Future<Result<List<LyricsSearchResult>>> searchLyrics({
    required String artist,
    required String title,
    String? album,
    String? query,
  }) async {
    try {
      final results = await _remote.searchLrclib(
        query: query,
        title: title,
        artist: artist,
        album: album,
      );
      return ResultHelper.success(results);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to search lyrics: $e'),
      );
    }
  }

  @override
  Future<Result<LyricsData?>> getCachedLyrics(String trackId) async {
    try {
      final cached = await _cache.getCachedLyrics(trackId);
      return ResultHelper.success(cached);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to load cache: $e'));
    }
  }

  @override
  Future<Result<void>> setCachedLyrics(String trackId, LyricsData data) async {
    try {
      await _cache.setCachedLyrics(trackId, data);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to write cache: $e'));
    }
  }

  @override
  Future<Result<LyricsOverride?>> getOverride(String trackId) async {
    try {
      final override = await _cache.getOverride(trackId);
      return ResultHelper.success(override);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to load override: $e'),
      );
    }
  }

  @override
  Future<Result<void>> setOverride(
    String trackId,
    LyricsOverride? override,
  ) async {
    try {
      await _cache.setOverride(trackId, override);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to save override: $e'),
      );
    }
  }

  @override
  Future<Result<int>> getOffsetMs(String trackId) async {
    try {
      final offset = await _cache.getOffsetMs(trackId);
      return ResultHelper.success(offset);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to load offset: $e'));
    }
  }

  @override
  Future<Result<void>> setOffsetMs(String trackId, int offsetMs) async {
    try {
      await _cache.setOffsetMs(trackId, offsetMs);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to save offset: $e'));
    }
  }

  @override
  Future<Result<LyricsSource?>> getPreferredSource() async {
    try {
      final source = await _cache.getPreferredSource();
      return ResultHelper.success(source);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to load preference: $e'),
      );
    }
  }

  @override
  Future<Result<void>> setPreferredSource(LyricsSource? source) async {
    try {
      await _cache.setPreferredSource(source);
      return ResultHelper.success(null);
    } catch (e) {
      return ResultHelper.failure(
        UnknownFailure('Failed to save preference: $e'),
      );
    }
  }
}
