import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import 'subsonic_image_cache_manager.dart';

/// Extracts a dominant color from track/album cover art, so the now-playing
/// bar and full-screen player can tint themselves to the current cover
/// instead of always using the static brand gradient.
///
/// Results are cached per URL for the process lifetime — palette extraction
/// decodes the full image, so repeating it every rebuild would be wasteful.
class CoverPaletteService {
  CoverPaletteService._();

  static final CoverPaletteService instance = CoverPaletteService._();

  final Map<String, Color?> _cache = {};

  /// Extractions still running, keyed like [_cache]. The shell's wash, the
  /// player bar and Now Playing all ask for the same cover at the same moment
  /// on a track change; without this each of them decoded and quantised it.
  final Map<String, Future<Color?>> _inFlight = {};

  static String? _keyFor(String? coverArtUrl) {
    if (coverArtUrl == null || coverArtUrl.isEmpty) return null;
    return coverArtUrl.withCoverArtSize(200).subsonicCacheKey;
  }

  /// The colour for [coverArtUrl] if it has already been extracted, without
  /// waiting. [extractColor] never completes synchronously, even on a cache
  /// hit, so a widget relying on it alone paints its first frame with the
  /// fallback colour and jumps a frame later.
  Color? cachedColor(String? coverArtUrl) {
    final key = _keyFor(coverArtUrl);
    return key == null ? null : _cache[key];
  }

  /// Returns the dominant (falling back to vibrant, then muted) color for
  /// the cover art at [coverArtUrl], or null if there is no artwork or
  /// extraction fails.
  Future<Color?> extractColor(String? coverArtUrl) {
    final cacheKey = _keyFor(coverArtUrl);
    if (cacheKey == null) return Future.value(null);
    if (_cache.containsKey(cacheKey)) return Future.value(_cache[cacheKey]);
    return _inFlight[cacheKey] ??= _extract(
      coverArtUrl!,
      cacheKey,
    ).whenComplete(() => _inFlight.remove(cacheKey));
  }

  Future<Color?> _extract(String coverArtUrl, String cacheKey) async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(
          coverArtUrl.withCoverArtSize(200),
          cacheKey: cacheKey,
          cacheManager: OmnisonicImageCacheManager.instance,
        ),
        maximumColorCount: 12,
      );

      final color =
          palette.dominantColor?.color ??
          palette.vibrantColor?.color ??
          palette.mutedColor?.color;
      _cache[cacheKey] = color;
      return color;
    } catch (_) {
      _cache[cacheKey] = null;
      return null;
    }
  }
}
