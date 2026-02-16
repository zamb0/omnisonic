import 'package:dio/dio.dart';

import '../../../../core/entities/entities.dart';

class LyricsRemoteDataSource {
  LyricsRemoteDataSource({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const String _lrclibBaseUrl = 'https://lrclib.net/api';
  static const String _lyricsOvhBaseUrl = 'https://api.lyrics.ovh/v1';

  Future<LyricsData?> getLrclibBySignature(Track track) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_lrclibBaseUrl/get',
      queryParameters: {
        'track_name': track.title,
        'artist_name': track.artist,
        'album_name': track.album,
        'duration': track.duration.inSeconds,
      },
      options: Options(
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        headers: {
          'User-Agent': 'Omnisonic (https://github.com/zambo/omnisonic)',
        },
      ),
    );

    final data = response.data;
    if (data == null) return null;

    return _mapLrclibTrackResponse(data);
  }

  Future<LyricsData?> getLrclibById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_lrclibBaseUrl/get/$id',
      options: Options(
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        headers: {
          'User-Agent': 'Omnisonic (https://github.com/zambo/omnisonic)',
        },
      ),
    );

    final data = response.data;
    if (data == null) return null;

    return _mapLrclibTrackResponse(data);
  }

  Future<List<LyricsSearchResult>> searchLrclib({
    String? query,
    String? title,
    String? artist,
    String? album,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (query != null && query.isNotEmpty) {
      queryParameters['q'] = query;
    } else {
      if (title != null && title.isNotEmpty) {
        queryParameters['track_name'] = title;
      }
      if (artist != null && artist.isNotEmpty) {
        queryParameters['artist_name'] = artist;
      }
      if (album != null && album.isNotEmpty) {
        queryParameters['album_name'] = album;
      }
    }

    if (queryParameters.isEmpty) {
      return [];
    }

    final response = await _dio.get<List<dynamic>>(
      '$_lrclibBaseUrl/search',
      queryParameters: queryParameters,
      options: Options(
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        headers: {
          'User-Agent': 'Omnisonic (https://github.com/zambo/omnisonic)',
        },
      ),
    );

    final data = response.data;
    if (data == null) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(_mapLrclibSearchResponse)
        .toList();
  }

  Future<LyricsData?> getLyricsOvh({
    required String artist,
    required String title,
  }) async {
    final encodedArtist = Uri.encodeComponent(artist);
    final encodedTitle = Uri.encodeComponent(title);

    final response = await _dio.get<Map<String, dynamic>>(
      '$_lyricsOvhBaseUrl/$encodedArtist/$encodedTitle',
      options: Options(
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
      ),
    );

    final data = response.data;
    if (data == null) return null;

    final lyrics = data['lyrics'] as String?;
    if (lyrics == null || lyrics.trim().isEmpty) return null;

    return LyricsData(
      title: title,
      artist: artist,
      source: LyricsSource.lyricsOvh,
      type: LyricsType.unsynced,
      raw: lyrics.trim(),
      fetchedAt: DateTime.now(),
    );
  }

  LyricsData _mapLrclibTrackResponse(Map<String, dynamic> data) {
    final syncedLyrics = data['syncedLyrics'] as String?;
    final plainLyrics = data['plainLyrics'] as String?;
    final lyrics = syncedLyrics?.trim().isNotEmpty == true
        ? syncedLyrics!.trim()
        : plainLyrics?.trim();

    if (lyrics == null || lyrics.isEmpty) {
      return LyricsData(
        title: data['trackName'] as String? ?? '',
        artist: data['artistName'] as String? ?? '',
        source: LyricsSource.lrclib,
        type: LyricsType.unsynced,
        raw: '',
        fetchedAt: DateTime.now(),
        providerId: (data['id'] as num?)?.toString(),
      );
    }

    return LyricsData(
      title: data['trackName'] as String? ?? '',
      artist: data['artistName'] as String? ?? '',
      source: LyricsSource.lrclib,
      type: syncedLyrics?.trim().isNotEmpty == true
          ? LyricsType.synced
          : LyricsType.unsynced,
      raw: lyrics,
      fetchedAt: DateTime.now(),
      providerId: (data['id'] as num?)?.toString(),
    );
  }

  LyricsSearchResult _mapLrclibSearchResponse(Map<String, dynamic> data) {
    final syncedLyrics = data['syncedLyrics'] as String?;
    return LyricsSearchResult(
      id: (data['id'] as num?)?.toString() ?? '',
      title: data['trackName'] as String? ?? '',
      artist: data['artistName'] as String? ?? '',
      source: LyricsSource.lrclib,
      isSynced: syncedLyrics != null && syncedLyrics.trim().isNotEmpty,
    );
  }
}
