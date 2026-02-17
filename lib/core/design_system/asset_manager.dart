import 'package:flutter/material.dart';
import 'colors.dart';
import 'icons.dart';

/// Asset management system for Omnisonic UI Enhancement
class OmnisonicAssetManager {
  /// Get placeholder image for album artwork
  static Widget albumPlaceholder({
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: OmnisonicColors.subtleGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        OmnisonicIcons.album,
        size: (width ?? 120) * 0.4,
        color: OmnisonicColors.neutralGray400,
      ),
    );
  }
  
  /// Get placeholder image for artist
  static Widget artistPlaceholder({
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: OmnisonicColors.subtleGradient,
        shape: BoxShape.circle,
      ),
      child: Icon(
        OmnisonicIcons.artist,
        size: (width ?? 120) * 0.4,
        color: OmnisonicColors.neutralGray400,
      ),
    );
  }
  
  /// Get placeholder image for playlist
  static Widget playlistPlaceholder({
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: OmnisonicColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        OmnisonicIcons.playlist,
        size: (width ?? 120) * 0.4,
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }
  
  /// Get cached network image with placeholder
  static Widget networkImage({
    required String url,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _buildLoadingPlaceholder(width, height);
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? albumPlaceholder(width: width, height: height);
        },
      ),
    );
  }
  
  /// Build loading placeholder with shimmer effect
  static Widget _buildLoadingPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: OmnisonicColors.neutralGray200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }
  
  /// Check if asset exists
  static Future<bool> assetExists(String assetPath) async {
    try {
      await DefaultAssetBundle.of(
        // This is a workaround since we don't have context here
        WidgetsBinding.instance.rootElement!,
      ).load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Get asset with fallback
  static Widget assetImage({
    required String assetPath,
    String? fallbackAssetPath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? fallbackWidget,
  }) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        if (fallbackAssetPath != null) {
          return Image.asset(
            fallbackAssetPath,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return fallbackWidget ?? albumPlaceholder(width: width, height: height);
            },
          );
        }
        return fallbackWidget ?? albumPlaceholder(width: width, height: height);
      },
    );
  }
}

/// Extension for easy asset access
extension OmnisonicAssetExtension on BuildContext {
  /// Get album artwork with placeholder fallback
  Widget albumArtwork({
    String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return OmnisonicAssetManager.networkImage(
        url: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: OmnisonicAssetManager.albumPlaceholder(
          width: width,
          height: height,
        ),
      );
    }
    
    return OmnisonicAssetManager.albumPlaceholder(
      width: width,
      height: height,
    );
  }
  
  /// Get artist image with placeholder fallback
  Widget artistImage({
    String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return OmnisonicAssetManager.networkImage(
        url: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: OmnisonicAssetManager.artistPlaceholder(
          width: width,
          height: height,
        ),
        borderRadius: BorderRadius.circular((width ?? 120) / 2),
      );
    }
    
    return OmnisonicAssetManager.artistPlaceholder(
      width: width,
      height: height,
    );
  }
  
  /// Get playlist image with placeholder fallback
  Widget playlistImage({
    String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return OmnisonicAssetManager.networkImage(
        url: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: OmnisonicAssetManager.playlistPlaceholder(
          width: width,
          height: height,
        ),
      );
    }
    
    return OmnisonicAssetManager.playlistPlaceholder(
      width: width,
      height: height,
    );
  }
}