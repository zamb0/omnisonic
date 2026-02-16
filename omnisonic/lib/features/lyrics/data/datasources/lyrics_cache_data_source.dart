import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/entities/entities.dart';

class LyricsCacheDataSource {
  static const String _cachePrefix = 'lyrics_cache_';
  static const String _overridePrefix = 'lyrics_override_';
  static const String _offsetPrefix = 'lyrics_offset_';
  static const String _preferredSourceKey = 'lyrics_preferred_source';

  final Map<String, LyricsData> _lyricsCache = {};
  final Map<String, LyricsOverride?> _overrideCache = {};
  final Map<String, int> _offsetCache = {};

  LyricsSource? _preferredSource;

  Future<LyricsData?> getCachedLyrics(String trackId) async {
    final cached = _lyricsCache[trackId];
    if (cached != null) return cached;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_cachePrefix$trackId');
    if (raw == null) return null;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final lyrics = _decodeLyrics(decoded);
    _lyricsCache[trackId] = lyrics;
    return lyrics;
  }

  Future<void> setCachedLyrics(String trackId, LyricsData data) async {
    _lyricsCache[trackId] = data;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_cachePrefix$trackId', jsonEncode(_encodeLyrics(data)));
  }

  Future<LyricsOverride?> getOverride(String trackId) async {
    if (_overrideCache.containsKey(trackId)) return _overrideCache[trackId];

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_overridePrefix$trackId');
    if (raw == null) return null;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final override = _decodeOverride(decoded);
    _overrideCache[trackId] = override;
    return override;
  }

  Future<void> setOverride(String trackId, LyricsOverride? override) async {
    _overrideCache[trackId] = override;
    final prefs = await SharedPreferences.getInstance();
    if (override == null) {
      await prefs.remove('$_overridePrefix$trackId');
      return;
    }
    await prefs.setString(
      '$_overridePrefix$trackId',
      jsonEncode(_encodeOverride(override)),
    );
  }

  Future<int> getOffsetMs(String trackId) async {
    if (_offsetCache.containsKey(trackId)) return _offsetCache[trackId] ?? 0;

    final prefs = await SharedPreferences.getInstance();
    final offset = prefs.getInt('$_offsetPrefix$trackId') ?? 0;
    _offsetCache[trackId] = offset;
    return offset;
  }

  Future<void> setOffsetMs(String trackId, int offsetMs) async {
    _offsetCache[trackId] = offsetMs;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_offsetPrefix$trackId', offsetMs);
  }

  Future<LyricsSource?> getPreferredSource() async {
    if (_preferredSource != null) return _preferredSource;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_preferredSourceKey);
    if (raw == null || raw.isEmpty) return null;

    _preferredSource = LyricsSource.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => LyricsSource.lrclib,
    );
    return _preferredSource;
  }

  Future<void> setPreferredSource(LyricsSource? source) async {
    _preferredSource = source;
    final prefs = await SharedPreferences.getInstance();
    if (source == null) {
      await prefs.remove(_preferredSourceKey);
      return;
    }
    await prefs.setString(_preferredSourceKey, source.name);
  }

  Map<String, dynamic> _encodeLyrics(LyricsData data) {
    return {
      'title': data.title,
      'artist': data.artist,
      'source': data.source.name,
      'type': data.type.name,
      'raw': data.raw,
      'providerId': data.providerId,
      'offsetMs': data.offsetMs,
      'fetchedAt': data.fetchedAt.toIso8601String(),
    };
  }

  LyricsData _decodeLyrics(Map<String, dynamic> data) {
    return LyricsData(
      title: data['title'] as String? ?? '',
      artist: data['artist'] as String? ?? '',
      source: LyricsSource.values.firstWhere(
        (value) => value.name == data['source'],
        orElse: () => LyricsSource.lrclib,
      ),
      type: LyricsType.values.firstWhere(
        (value) => value.name == data['type'],
        orElse: () => LyricsType.unsynced,
      ),
      raw: data['raw'] as String? ?? '',
      providerId: data['providerId'] as String?,
      offsetMs: data['offsetMs'] as int?,
      fetchedAt: DateTime.tryParse(data['fetchedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> _encodeOverride(LyricsOverride override) {
    return {
      'id': override.id,
      'title': override.title,
      'artist': override.artist,
      'source': override.source.name,
      'isSynced': override.isSynced,
    };
  }

  LyricsOverride _decodeOverride(Map<String, dynamic> data) {
    return LyricsOverride(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      artist: data['artist'] as String? ?? '',
      source: LyricsSource.values.firstWhere(
        (value) => value.name == data['source'],
        orElse: () => LyricsSource.lrclib,
      ),
      isSynced: data['isSynced'] as bool? ?? false,
    );
  }
}
