import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'spacing.dart';

/// Comprehensive accessibility system for WCAG 2.1 AA compliance
class OmnisonicAccessibility {
  /// Color contrast ratios for WCAG compliance
  static const double minimumContrastRatio = 4.5; // AA standard
  static const double enhancedContrastRatio = 7.0; // AAA standard

  /// Calculate color contrast ratio between two colors
  static double calculateContrastRatio(Color foreground, Color background) {
    final foregroundLuminance = _calculateLuminance(foreground);
    final backgroundLuminance = _calculateLuminance(background);

    final lighter = foregroundLuminance > backgroundLuminance
        ? foregroundLuminance
        : backgroundLuminance;
    final darker = foregroundLuminance > backgroundLuminance
        ? backgroundLuminance
        : foregroundLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calculate relative luminance of a color
  static double _calculateLuminance(Color color) {
    final r = _linearizeColorComponent((color.r * 255.0).round() / 255.0);
    final g = _linearizeColorComponent((color.g * 255.0).round() / 255.0);
    final b = _linearizeColorComponent((color.b * 255.0).round() / 255.0);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Linearize color component for luminance calculation
  static double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    } else {
      return ((component + 0.055) / 1.055).pow(2.4);
    }
  }

  /// Check if color combination meets WCAG AA standards
  static bool meetsWCAGAA(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >=
        minimumContrastRatio;
  }

  /// Check if color combination meets WCAG AAA standards
  static bool meetsWCAGAAA(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >=
        enhancedContrastRatio;
  }

  /// Get accessible text color for given background
  static Color getAccessibleTextColor(Color background) {
    final whiteContrast = calculateContrastRatio(Colors.white, background);
    final blackContrast = calculateContrastRatio(Colors.black, background);

    return whiteContrast >= blackContrast ? Colors.white : Colors.black;
  }

  /// Validate all theme colors for accessibility compliance
  static Map<String, bool> validateThemeAccessibility(ColorScheme colorScheme) {
    return {
      'primary_on_surface': meetsWCAGAA(
        colorScheme.primary,
        colorScheme.surface,
      ),
      'on_primary_primary': meetsWCAGAA(
        colorScheme.onPrimary,
        colorScheme.primary,
      ),
      'secondary_on_surface': meetsWCAGAA(
        colorScheme.secondary,
        colorScheme.surface,
      ),
      'on_secondary_secondary': meetsWCAGAA(
        colorScheme.onSecondary,
        colorScheme.secondary,
      ),
      'error_on_surface': meetsWCAGAA(colorScheme.error, colorScheme.surface),
      'on_error_error': meetsWCAGAA(colorScheme.onError, colorScheme.error),
      'on_surface_surface': meetsWCAGAA(
        colorScheme.onSurface,
        colorScheme.surface,
      ),
      'outline_surface': meetsWCAGAA(colorScheme.outline, colorScheme.surface),
    };
  }
}

/// Screen reader support and semantic labels
class OmnisonicSemantics {
  /// Create semantic label for music track
  static String trackSemanticLabel({
    required String title,
    required String artist,
    String? album,
    Duration? duration,
    bool isPlaying = false,
    bool isFavorite = false,
  }) {
    final buffer = StringBuffer();

    if (isPlaying) {
      buffer.write('Now playing: ');
    }

    buffer.write('$title by $artist');

    if (album != null && album.isNotEmpty) {
      buffer.write(' from album $album');
    }

    if (duration != null) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      buffer.write(', duration $minutes minutes and $seconds seconds');
    }

    if (isFavorite) {
      buffer.write(', marked as favorite');
    }

    return buffer.toString();
  }

  /// Create semantic label for album
  static String albumSemanticLabel({
    required String title,
    required String artist,
    int? trackCount,
    int? year,
  }) {
    final buffer = StringBuffer();
    buffer.write('Album $title by $artist');

    if (year != null) {
      buffer.write(' from $year');
    }

    if (trackCount != null) {
      buffer.write(', contains $trackCount tracks');
    }

    return buffer.toString();
  }

  /// Create semantic label for artist
  static String artistSemanticLabel({
    required String name,
    int? albumCount,
    int? trackCount,
  }) {
    final buffer = StringBuffer();
    buffer.write('Artist $name');

    if (albumCount != null && trackCount != null) {
      buffer.write(' with $albumCount albums and $trackCount tracks');
    } else if (albumCount != null) {
      buffer.write(' with $albumCount albums');
    } else if (trackCount != null) {
      buffer.write(' with $trackCount tracks');
    }

    return buffer.toString();
  }

  /// Create semantic label for playlist
  static String playlistSemanticLabel({
    required String name,
    int? trackCount,
    Duration? totalDuration,
    String? creator,
  }) {
    final buffer = StringBuffer();
    buffer.write('Playlist $name');

    if (creator != null && creator.isNotEmpty) {
      buffer.write(' by $creator');
    }

    if (trackCount != null) {
      buffer.write(', contains $trackCount tracks');
    }

    if (totalDuration != null) {
      final hours = totalDuration.inHours;
      final minutes = totalDuration.inMinutes % 60;
      if (hours > 0) {
        buffer.write(', total duration $hours hours and $minutes minutes');
      } else {
        buffer.write(', total duration $minutes minutes');
      }
    }

    return buffer.toString();
  }

  /// Create semantic label for playback controls
  static String playbackControlSemanticLabel({
    required String action,
    String? trackTitle,
    bool isEnabled = true,
  }) {
    if (!isEnabled) {
      return '$action button, disabled';
    }

    if (trackTitle != null && trackTitle.isNotEmpty) {
      return '$action $trackTitle';
    }

    return '$action button';
  }

  /// Create semantic label for progress/seek bar
  static String progressBarSemanticLabel({
    required Duration current,
    required Duration total,
    double? percentage,
  }) {
    final currentMinutes = current.inMinutes;
    final currentSeconds = current.inSeconds % 60;
    final totalMinutes = total.inMinutes;
    final totalSeconds = total.inSeconds % 60;

    final buffer = StringBuffer();
    buffer.write('Progress: $currentMinutes minutes $currentSeconds seconds');
    buffer.write(' of $totalMinutes minutes $totalSeconds seconds');

    if (percentage != null) {
      buffer.write(', ${(percentage * 100).round()}% complete');
    }

    return buffer.toString();
  }

  /// Create semantic label for volume control
  static String volumeSemanticLabel(double volume) {
    final volumePercent = (volume * 100).round();
    return 'Volume $volumePercent percent';
  }

  /// Create semantic hint for interactive elements
  static String interactionHint(String action) {
    return 'Double tap to $action';
  }
}

/// Keyboard navigation support
class OmnisonicKeyboardNavigation {
  /// Focus node manager for keyboard navigation
  static final Map<String, FocusNode> _focusNodes = {};

  /// Get or create focus node for a given key
  static FocusNode getFocusNode(String key) {
    return _focusNodes.putIfAbsent(key, () => FocusNode());
  }

  /// Dispose focus node
  static void disposeFocusNode(String key) {
    _focusNodes[key]?.dispose();
    _focusNodes.remove(key);
  }

  /// Dispose all focus nodes
  static void disposeAllFocusNodes() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _focusNodes.clear();
  }

  /// Create keyboard shortcuts for music player
  static Map<LogicalKeySet, Intent> get musicPlayerShortcuts => {
    LogicalKeySet(LogicalKeyboardKey.space): const PlayPauseIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): const NextTrackIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): const PreviousTrackIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): const VolumeUpIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): const VolumeDownIntent(),
    LogicalKeySet(LogicalKeyboardKey.keyF): const ToggleFavoriteIntent(),
    LogicalKeySet(LogicalKeyboardKey.keyS): const ToggleShuffleIntent(),
    LogicalKeySet(LogicalKeyboardKey.keyR): const ToggleRepeatIntent(),
    LogicalKeySet(LogicalKeyboardKey.escape): const ClosePlayerIntent(),
  };

  /// Create keyboard actions for music player
  static Map<Type, Action<Intent>> get musicPlayerActions => {
    PlayPauseIntent: PlayPauseAction(),
    NextTrackIntent: NextTrackAction(),
    PreviousTrackIntent: PreviousTrackAction(),
    VolumeUpIntent: VolumeUpAction(),
    VolumeDownIntent: VolumeDownAction(),
    ToggleFavoriteIntent: ToggleFavoriteAction(),
    ToggleShuffleIntent: ToggleShuffleAction(),
    ToggleRepeatIntent: ToggleRepeatAction(),
    ClosePlayerIntent: ClosePlayerAction(),
  };
}

/// Intent classes for keyboard shortcuts
class PlayPauseIntent extends Intent {
  const PlayPauseIntent();
}

class NextTrackIntent extends Intent {
  const NextTrackIntent();
}

class PreviousTrackIntent extends Intent {
  const PreviousTrackIntent();
}

class VolumeUpIntent extends Intent {
  const VolumeUpIntent();
}

class VolumeDownIntent extends Intent {
  const VolumeDownIntent();
}

class ToggleFavoriteIntent extends Intent {
  const ToggleFavoriteIntent();
}

class ToggleShuffleIntent extends Intent {
  const ToggleShuffleIntent();
}

class ToggleRepeatIntent extends Intent {
  const ToggleRepeatIntent();
}

class ClosePlayerIntent extends Intent {
  const ClosePlayerIntent();
}

/// Action classes for keyboard shortcuts
class PlayPauseAction extends Action<PlayPauseIntent> {
  @override
  Object? invoke(PlayPauseIntent intent) {
    // Implementation will be connected to actual playback service
    return null;
  }
}

class NextTrackAction extends Action<NextTrackIntent> {
  @override
  Object? invoke(NextTrackIntent intent) {
    // Implementation will be connected to actual playback service
    return null;
  }
}

class PreviousTrackAction extends Action<PreviousTrackIntent> {
  @override
  Object? invoke(PreviousTrackIntent intent) {
    // Implementation will be connected to actual playback service
    return null;
  }
}

class VolumeUpAction extends Action<VolumeUpIntent> {
  @override
  Object? invoke(VolumeUpIntent intent) {
    // Implementation will be connected to actual playback service
    return null;
  }
}

class VolumeDownAction extends Action<VolumeDownIntent> {
  @override
  Object? invoke(VolumeDownIntent intent) {
    // Implementation will be connected to actual playback service
    return null;
  }
}

class ToggleFavoriteAction extends Action<ToggleFavoriteIntent> {
  @override
  Object? invoke(ToggleFavoriteIntent intent) {
    // Implementation will be connected to actual favorite service
    return null;
  }
}

class ToggleShuffleAction extends Action<ToggleShuffleIntent> {
  @override
  Object? invoke(ToggleShuffleIntent intent) {
    // Implementation will be connected to actual playback service
    return null;
  }
}

class ToggleRepeatAction extends Action<ToggleRepeatIntent> {
  @override
  Object? invoke(ToggleRepeatIntent intent) {
    // Implementation will be connected to actual playback service
    return null;
  }
}

class ClosePlayerAction extends Action<ClosePlayerIntent> {
  @override
  Object? invoke(ClosePlayerIntent intent) {
    // Implementation will close the player
    return null;
  }
}

/// Focus management utilities
class OmnisonicFocusManager {
  /// Create focus traversal policy for music app
  static FocusTraversalPolicy get musicAppTraversalPolicy {
    return OrderedTraversalPolicy();
  }

  /// Create focus highlight strategy
  static FocusHighlightStrategy get focusHighlightStrategy {
    return FocusHighlightStrategy.alwaysTraditional;
  }

  /// Create focus highlight mode
  static FocusHighlightMode get focusHighlightMode {
    return FocusHighlightMode.traditional;
  }

  /// Custom focus border for accessibility
  static BoxDecoration get accessibleFocusBorder {
    return BoxDecoration(
      border: Border.all(color: OmnisonicColors.primaryBlue, width: 2.0),
      borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
    );
  }

  /// Create accessible focus indicator widget
  static Widget buildFocusIndicator({
    required Widget child,
    required bool hasFocus,
    Color? focusColor,
    double borderWidth = 2.0,
    BorderRadius? borderRadius,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: hasFocus
          ? BoxDecoration(
              border: Border.all(
                color: focusColor ?? OmnisonicColors.primaryBlue,
                width: borderWidth,
              ),
              borderRadius:
                  borderRadius ?? BorderRadius.circular(OmnisonicRadius.sm),
            )
          : null,
      child: child,
    );
  }
}

/// Touch target size validation and adjustment
class OmnisonicTouchTargetValidator {
  /// Minimum touch target size for accessibility
  static const double minimumTouchTarget = OmnisonicTouchTargets.minimum;

  /// Validate if a size meets accessibility requirements
  static bool isAccessibleSize(Size size) {
    return size.width >= minimumTouchTarget &&
        size.height >= minimumTouchTarget;
  }

  /// Adjust size to meet accessibility requirements
  static Size adjustToAccessibleSize(Size originalSize) {
    return Size(
      originalSize.width < minimumTouchTarget
          ? minimumTouchTarget
          : originalSize.width,
      originalSize.height < minimumTouchTarget
          ? minimumTouchTarget
          : originalSize.height,
    );
  }

  /// Create accessible button constraints
  static BoxConstraints get accessibleButtonConstraints {
    return const BoxConstraints(
      minWidth: minimumTouchTarget,
      minHeight: minimumTouchTarget,
    );
  }

  /// Wrap widget with accessible touch target
  static Widget wrapWithAccessibleTouchTarget({
    required Widget child,
    VoidCallback? onTap,
    String? semanticLabel,
    String? semanticHint,
    bool excludeSemantics = false,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: onTap != null,
      excludeSemantics: excludeSemantics,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
        child: ConstrainedBox(
          constraints: accessibleButtonConstraints,
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Extension for adding accessibility features to widgets
extension AccessibilityExtension on Widget {
  /// Add semantic label to widget
  Widget withSemanticLabel(String label) {
    return Semantics(label: label, child: this);
  }

  /// Add semantic hint to widget
  Widget withSemanticHint(String hint) {
    return Semantics(hint: hint, child: this);
  }

  /// Mark widget as button for screen readers
  Widget asSemanticButton({String? label, String? hint, VoidCallback? onTap}) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      onTap: onTap,
      child: this,
    );
  }

  /// Mark widget as header for screen readers
  Widget asSemanticHeader({String? label}) {
    return Semantics(label: label, header: true, child: this);
  }

  /// Add focus support to widget
  Widget withFocus({
    required String focusKey,
    VoidCallback? onFocusChange,
    bool autofocus = false,
  }) {
    final focusNode = OmnisonicKeyboardNavigation.getFocusNode(focusKey);

    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      onFocusChange: onFocusChange != null ? (_) => onFocusChange() : null,
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return OmnisonicFocusManager.buildFocusIndicator(
            hasFocus: hasFocus,
            child: this,
          );
        },
      ),
    );
  }

  /// Ensure widget meets minimum touch target size
  Widget withAccessibleTouchTarget({
    VoidCallback? onTap,
    String? semanticLabel,
    String? semanticHint,
  }) {
    return OmnisonicTouchTargetValidator.wrapWithAccessibleTouchTarget(
      onTap: onTap,
      semanticLabel: semanticLabel,
      semanticHint: semanticHint,
      child: this,
    );
  }
}

/// Utility extension for math operations
extension on double {
  double pow(double exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= this;
    }
    return result;
  }
}
