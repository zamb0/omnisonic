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

  /// Returns the dominant (falling back to vibrant, then muted) color for
  /// the cover art at [coverArtUrl], or null if there is no artwork or
  /// extraction fails.
  Future<Color?> extractColor(String? coverArtUrl) async {
    if (coverArtUrl == null || coverArtUrl.isEmpty) return null;

    final cacheKey = coverArtUrl.withCoverArtSize(200).subsonicCacheKey;
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

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
