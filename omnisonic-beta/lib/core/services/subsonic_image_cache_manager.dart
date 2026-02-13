import 'dart:convert';
import 'package:crypto/crypto.dart';

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
