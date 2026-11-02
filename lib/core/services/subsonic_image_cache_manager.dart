import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/widgets.dart';

/// Shared cache manager for album/artist artwork
class OmnisonicImageCacheManager {
  static const String _cacheKey = 'omnisonicImageCache';

  static final CacheManager instance = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 2000,
    ),
  );
}

Widget coverArtErrorWidget(Widget placeholder, String url, Object error) {
  debugPrint('Cover art load failed: $url -> $error');
  return placeholder;
}

/// A cover art URL sized for a particular slot, together with its cache key.
///
/// Both are derived with `Uri.parse` + `Uri.replace`, and every
/// `CachedNetworkImage` in the app used to recompute them inline in `build` —
/// four parses per image widget per rebuild, at the rate the now-playing bar
/// rebuilds. [SubsonicCoverArt.of] memoizes them per (url, size).
class SubsonicCoverArt {
  const SubsonicCoverArt({required this.url, required this.cacheKey});

  final String url;
  final String cacheKey;

  static final Map<String, SubsonicCoverArt> _cache = {};

  /// Maximum number of memoized entries, so a long scroll cannot grow this
  /// without bound.
  static const int _maxEntries = 512;

  static SubsonicCoverArt of(String url, int size) {
    final key = '$size|$url';
    final cached = _cache[key];
    if (cached != null) return cached;

    final sized = url.withCoverArtSize(size);
    final art = SubsonicCoverArt(
      url: sized,
      cacheKey: SubsonicImageCache.getCacheKey(sized),
    );

    if (_cache.length >= _maxEntries) _cache.clear();
    _cache[key] = art;
    return art;
  }
}

/// Helper functions for Subsonic image caching
class SubsonicImageCache {
  /// Gets a stable cache key from a Subsonic URL by removing auth tokens
  static String getCacheKey(String url) {
    try {
      final uri = Uri.parse(url);

      // Remove dynamic auth parameters (salt and token)
      final filteredParams = Map<String, String>.from(uri.queryParameters)
        ..remove('t') // token
        ..remove('s'); // salt

      // Create stable URL without auth params
      final stableUrl = uri.replace(queryParameters: filteredParams).toString();

      return stableUrl;
    } catch (e) {
      // If parsing fails, return original URL
      return url;
    }
  }
}

/// Extension to get cache key from URL string
extension SubsonicCacheKey on String {
  /// Gets a normalized cache key for Subsonic URLs
  String get subsonicCacheKey => SubsonicImageCache.getCacheKey(this);
}

/// Extension to request server-side resized cover art when supported
extension SubsonicCoverArtSize on String {
  /// Adds or replaces the cover art size query parameter
  String withCoverArtSize(int size) {
    try {
      final uri = Uri.parse(this);
      if (!uri.path.contains('getCoverArt')) {
        return this;
      }

      if (!uri.queryParameters.containsKey('size')) {
        return this;
      }

      const maxSize = 512;
      final params = Map<String, String>.from(uri.queryParameters);
      final requestedSize = size.clamp(32, maxSize);
      final existingSize = int.tryParse(params['size'] ?? '');
      final effectiveSize = existingSize != null
          ? existingSize.clamp(32, maxSize).clamp(32, requestedSize)
          : requestedSize;
      params['size'] = effectiveSize.toString();
      return uri.replace(queryParameters: params).toString();
    } catch (_) {
      return this;
    }
  }
}
