import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'platform_optimizations.dart';

/// Accessibility preferences manager for respecting user settings
class OmnisonicAccessibilityPreferences extends ChangeNotifier {
  static const String _reducedMotionKey = 'accessibility_reduced_motion';
  static const String _highContrastKey = 'accessibility_high_contrast';
  static const String _largeTextKey = 'accessibility_large_text';
  static const String _screenReaderKey = 'accessibility_screen_reader';
  static const String _hapticFeedbackKey = 'accessibility_haptic_feedback';

  bool _reducedMotionEnabled = false;
  bool _highContrastEnabled = false;
  bool _largeTextEnabled = false;
  bool _screenReaderEnabled = false;
  bool _hapticFeedbackEnabled = true;
  bool _systemReducedMotionEnabled = false;

  SharedPreferences? _prefs;

  /// Singleton instance
  static final OmnisonicAccessibilityPreferences _instance =
      OmnisonicAccessibilityPreferences._internal();

  factory OmnisonicAccessibilityPreferences() => _instance;

  OmnisonicAccessibilityPreferences._internal();

  /// Initialize preferences and system settings
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPreferences();
    await _checkSystemSettings();

    // Listen for system accessibility changes
    WidgetsBinding.instance.addObserver(_AccessibilityObserver(this));
  }

  /// Load saved preferences
  Future<void> _loadPreferences() async {
    _reducedMotionEnabled = _prefs?.getBool(_reducedMotionKey) ?? false;
    _highContrastEnabled = _prefs?.getBool(_highContrastKey) ?? false;
    _largeTextEnabled = _prefs?.getBool(_largeTextKey) ?? false;
    _screenReaderEnabled = _prefs?.getBool(_screenReaderKey) ?? false;
    _hapticFeedbackEnabled = _prefs?.getBool(_hapticFeedbackKey) ?? true;
    notifyListeners();
  }

  /// Check system accessibility settings
  Future<void> _checkSystemSettings() async {
    final binding = WidgetsBinding.instance;
    _systemReducedMotionEnabled =
        binding.platformDispatcher.accessibilityFeatures.reduceMotion;
    notifyListeners();
  }

  /// Save preference to storage
  Future<void> _savePreference(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  // Getters
  bool get reducedMotionEnabled =>
      _reducedMotionEnabled || _systemReducedMotionEnabled;
  bool get highContrastEnabled => _highContrastEnabled;
  bool get largeTextEnabled => _largeTextEnabled;
  bool get screenReaderEnabled => _screenReaderEnabled;
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;
  bool get systemReducedMotionEnabled => _systemReducedMotionEnabled;

  /// Check if animations should be disabled
  bool get shouldDisableAnimations => reducedMotionEnabled;

  /// Get animation scale factor (0.0 to 1.0)
  double get animationScale {
    if (reducedMotionEnabled) return 0.0;
    return 1.0;
  }

  /// Get animation duration with accessibility adjustments
  Duration getAdjustedDuration(Duration originalDuration) {
    if (reducedMotionEnabled) {
      return Duration.zero;
    }
    return originalDuration;
  }

  /// Get animation curve with accessibility adjustments
  Curve getAdjustedCurve(Curve originalCurve) {
    if (reducedMotionEnabled) {
      return Curves.linear;
    }
    return originalCurve;
  }

  // Setters
  Future<void> setReducedMotionEnabled(bool enabled) async {
    _reducedMotionEnabled = enabled;
    await _savePreference(_reducedMotionKey, enabled);
    notifyListeners();
  }

  Future<void> setHighContrastEnabled(bool enabled) async {
    _highContrastEnabled = enabled;
    await _savePreference(_highContrastKey, enabled);
    notifyListeners();
  }

  Future<void> setLargeTextEnabled(bool enabled) async {
    _largeTextEnabled = enabled;
    await _savePreference(_largeTextKey, enabled);
    notifyListeners();
  }

  Future<void> setScreenReaderEnabled(bool enabled) async {
    _screenReaderEnabled = enabled;
    await _savePreference(_screenReaderKey, enabled);
    notifyListeners();
  }

  Future<void> setHapticFeedbackEnabled(bool enabled) async {
    _hapticFeedbackEnabled = enabled;
    await _savePreference(_hapticFeedbackKey, enabled);
    notifyListeners();
  }

  /// Trigger haptic feedback if enabled
  Future<void> triggerHapticFeedback([
    HapticFeedbackType type = HapticFeedbackType.light,
  ]) async {
    if (_hapticFeedbackEnabled) {
      await PlatformOptimizations().triggerHapticFeedback(type);
    }
  }

  /// Update system settings when they change
  void updateSystemSettings() {
    _checkSystemSettings();
  }
}

/// Observer for system accessibility changes
class _AccessibilityObserver extends WidgetsBindingObserver {
  final OmnisonicAccessibilityPreferences preferences;

  _AccessibilityObserver(this.preferences);

  @override
  void didChangeAccessibilityFeatures() {
    preferences.updateSystemSettings();
  }
}

/// Enhanced animation manager that respects accessibility preferences
class AccessibleAnimationManager {
  static final OmnisonicAccessibilityPreferences _preferences =
      OmnisonicAccessibilityPreferences();

  /// Create animation controller with accessibility support
  static AnimationController createController({
    required TickerProvider vsync,
    required Duration duration,
    Duration? reverseDuration,
    String? debugLabel,
    double lowerBound = 0.0,
    double upperBound = 1.0,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
  }) {
    final adjustedDuration = _preferences.getAdjustedDuration(duration);
    final adjustedReverseDuration = reverseDuration != null
        ? _preferences.getAdjustedDuration(reverseDuration)
        : null;

    return AnimationController(
      vsync: vsync,
      duration: adjustedDuration,
      reverseDuration: adjustedReverseDuration,
      debugLabel: debugLabel,
      lowerBound: lowerBound,
      upperBound: upperBound,
      animationBehavior: animationBehavior,
    );
  }

  /// Create curved animation with accessibility support
  static CurvedAnimation createCurvedAnimation({
    required Animation<double> parent,
    required Curve curve,
    Curve? reverseCurve,
  }) {
    final adjustedCurve = _preferences.getAdjustedCurve(curve);
    final adjustedReverseCurve = reverseCurve != null
        ? _preferences.getAdjustedCurve(reverseCurve)
        : null;

    return CurvedAnimation(
      parent: parent,
      curve: adjustedCurve,
      reverseCurve: adjustedReverseCurve,
    );
  }

  /// Create tween animation with accessibility support
  static Animation<T> createTween<T>({
    required Animation<double> parent,
    required Tween<T> tween,
    Curve? curve,
  }) {
    if (curve != null) {
      final curvedAnimation = createCurvedAnimation(
        parent: parent,
        curve: curve,
      );
      return tween.animate(curvedAnimation);
    }
    return tween.animate(parent);
  }

  /// Check if animations should be enabled
  static bool get animationsEnabled => !_preferences.shouldDisableAnimations;

  /// Get animation scale factor
  static double get animationScale => _preferences.animationScale;
}

/// Widget that respects reduced motion preferences
class AccessibleAnimatedWidget extends StatefulWidget {
  final Widget child;
  final Widget? reducedMotionChild;
  final Duration duration;
  final Curve curve;
  final AnimationBuilder builder;

  const AccessibleAnimatedWidget({
    super.key,
    required this.child,
    this.reducedMotionChild,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    required this.builder,
  });

  @override
  State<AccessibleAnimatedWidget> createState() =>
      _AccessibleAnimatedWidgetState();
}

class _AccessibleAnimatedWidgetState extends State<AccessibleAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final OmnisonicAccessibilityPreferences _preferences =
      OmnisonicAccessibilityPreferences();

  @override
  void initState() {
    super.initState();
    _controller = AccessibleAnimationManager.createController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = AccessibleAnimationManager.createCurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _preferences.addListener(_onPreferencesChanged);

    if (AccessibleAnimationManager.animationsEnabled) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _preferences.removeListener(_onPreferencesChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onPreferencesChanged() {
    if (mounted) {
      setState(() {
        if (AccessibleAnimationManager.animationsEnabled) {
          _controller.forward();
        } else {
          _controller.value = 1.0;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_preferences.shouldDisableAnimations &&
        widget.reducedMotionChild != null) {
      return widget.reducedMotionChild!;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) =>
          widget.builder(context, _animation.value, child),
      child: widget.child,
    );
  }
}

/// Typedef for animation builder function
typedef AnimationBuilder =
    Widget Function(BuildContext context, double value, Widget? child);

/// Alternative text and image description system
class OmnisonicAlternativeText {
  /// Generate alternative text for album artwork
  static String albumArtworkAlt({
    required String albumTitle,
    required String artistName,
    bool hasArtwork = true,
  }) {
    if (hasArtwork) {
      return 'Album artwork for $albumTitle by $artistName';
    } else {
      return 'Default album artwork placeholder for $albumTitle by $artistName';
    }
  }

  /// Generate alternative text for artist image
  static String artistImageAlt({
    required String artistName,
    bool hasImage = true,
  }) {
    if (hasImage) {
      return 'Artist photo of $artistName';
    } else {
      return 'Default artist image placeholder for $artistName';
    }
  }

  /// Generate alternative text for playlist cover
  static String playlistCoverAlt({
    required String playlistName,
    String? creatorName,
    bool hasCover = true,
  }) {
    final creator = creatorName != null && creatorName.isNotEmpty
        ? ' by $creatorName'
        : '';

    if (hasCover) {
      return 'Playlist cover for $playlistName$creator';
    } else {
      return 'Default playlist cover placeholder for $playlistName$creator';
    }
  }

  /// Generate alternative text for music visualizations
  static String visualizationAlt({
    required String type,
    bool isAnimated = true,
  }) {
    if (isAnimated) {
      return 'Animated $type visualization showing audio levels';
    } else {
      return 'Static $type visualization';
    }
  }

  /// Generate alternative text for loading states
  static String loadingStateAlt(String contentType) {
    return 'Loading $contentType, please wait';
  }

  /// Generate alternative text for error states
  static String errorStateAlt(String errorType) {
    return 'Error loading content: $errorType';
  }
}

/// Meaningful error messages for accessibility
class OmnisonicErrorMessages {
  /// Network connection error
  static const String networkError =
      'Unable to connect to the music service. Please check your internet connection and try again.';

  /// Server error
  static const String serverError =
      'The music service is temporarily unavailable. Please try again in a few moments.';

  /// Authentication error
  static const String authError =
      'Unable to sign in to your account. Please check your credentials and try again.';

  /// Playback error
  static const String playbackError =
      'Unable to play this track. The file may be corrupted or unavailable.';

  /// Search error
  static const String searchError =
      'Unable to complete your search. Please try again with different terms.';

  /// Library sync error
  static const String syncError =
      'Unable to sync your music library. Please check your connection and try again.';

  /// File not found error
  static const String fileNotFoundError =
      'The requested music file could not be found. It may have been moved or deleted.';

  /// Permission error
  static const String permissionError =
      'Permission denied. Please check your account permissions and try again.';

  /// Storage error
  static const String storageError =
      'Unable to save to device storage. Please check available space and try again.';

  /// Generic error with recovery action
  static String genericErrorWithAction(String action) {
    return 'An unexpected error occurred. Please $action to continue.';
  }

  /// Get error message with recovery suggestions
  static Map<String, dynamic> getErrorWithRecovery(String errorType) {
    switch (errorType) {
      case 'network':
        return {
          'message': networkError,
          'actions': ['Check connection', 'Retry', 'Go offline'],
          'primaryAction': 'Retry',
        };
      case 'server':
        return {
          'message': serverError,
          'actions': ['Retry', 'Check status'],
          'primaryAction': 'Retry',
        };
      case 'auth':
        return {
          'message': authError,
          'actions': ['Sign in again', 'Reset password'],
          'primaryAction': 'Sign in again',
        };
      case 'playback':
        return {
          'message': playbackError,
          'actions': ['Skip track', 'Retry', 'Report issue'],
          'primaryAction': 'Skip track',
        };
      case 'search':
        return {
          'message': searchError,
          'actions': ['Try different terms', 'Clear filters'],
          'primaryAction': 'Try different terms',
        };
      case 'sync':
        return {
          'message': syncError,
          'actions': ['Retry sync', 'Check connection'],
          'primaryAction': 'Retry sync',
        };
      default:
        return {
          'message': genericErrorWithAction('tap retry'),
          'actions': ['Retry'],
          'primaryAction': 'Retry',
        };
    }
  }
}

/// Widget for displaying accessible error states
class AccessibleErrorState extends StatelessWidget {
  final String errorType;
  final VoidCallback? onRetry;
  final VoidCallback? onSecondaryAction;
  final String? customMessage;

  const AccessibleErrorState({
    super.key,
    required this.errorType,
    this.onRetry,
    this.onSecondaryAction,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final errorInfo = OmnisonicErrorMessages.getErrorWithRecovery(errorType);
    final message = customMessage ?? errorInfo['message'] as String;
    final actions = errorInfo['actions'] as List<String>;
    final primaryAction = errorInfo['primaryAction'] as String;

    return Semantics(
      label: 'Error occurred',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
                semanticLabel: 'Error icon',
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
                semanticsLabel: message,
              ),
              const SizedBox(height: 24),
              if (onRetry != null)
                ElevatedButton(onPressed: onRetry, child: Text(primaryAction)),
              if (onSecondaryAction != null && actions.length > 1)
                TextButton(
                  onPressed: onSecondaryAction,
                  child: Text(actions[1]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
