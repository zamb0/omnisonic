import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/platform_info.dart';

/// Adaptive performance system that automatically adjusts animation complexity
/// based on device capabilities, battery level, and thermal state
class AdaptivePerformanceManager {
  static final AdaptivePerformanceManager _instance =
      AdaptivePerformanceManager._internal();
  factory AdaptivePerformanceManager() => _instance;
  AdaptivePerformanceManager._internal();

  // Performance monitoring
  DevicePerformanceLevel _currentPerformanceLevel = DevicePerformanceLevel.high;
  BatteryOptimizationLevel _batteryOptimizationLevel =
      BatteryOptimizationLevel.none;
  final ThermalState _thermalState = ThermalState.normal;

  // Performance metrics
  double _averageFrameRate = 60.0;
  int _frameDropCount = 0;
  int _memoryUsageMB = 0;
  final bool _isLowPowerModeEnabled = false;

  // Timers and monitoring
  Timer? _performanceMonitorTimer;
  Timer? _batteryMonitorTimer;
  Timer? _memoryMonitorTimer;

  // Callbacks
  final List<VoidCallback> _performanceLevelChangeCallbacks = [];
  final List<VoidCallback> _batteryOptimizationCallbacks = [];

  /// Initialize the adaptive performance manager
  Future<void> initialize() async {
    await _detectDeviceCapabilities();
    await _initializeBatteryMonitoring();
    await _initializeMemoryMonitoring();
    _startPerformanceMonitoring();

    developer.log(
      'Adaptive performance initialized: ${_currentPerformanceLevel.name}',
      name: 'AdaptivePerformance',
    );
  }

  /// Get current device performance level
  DevicePerformanceLevel get currentPerformanceLevel =>
      _currentPerformanceLevel;

  /// Get current battery optimization level
  BatteryOptimizationLevel get batteryOptimizationLevel =>
      _batteryOptimizationLevel;

  /// Get current thermal state
  ThermalState get thermalState => _thermalState;

  /// Get current frame rate
  double get averageFrameRate => _averageFrameRate;

  /// Get memory usage in MB
  int get memoryUsageMB => _memoryUsageMB;

  /// Check if low power mode is enabled
  bool get isLowPowerModeEnabled => _isLowPowerModeEnabled;

  /// Get animation complexity multiplier based on current performance level
  double get animationComplexityMultiplier {
    switch (_currentPerformanceLevel) {
      case DevicePerformanceLevel.low:
        return 0.3;
      case DevicePerformanceLevel.medium:
        return 0.6;
      case DevicePerformanceLevel.high:
        return 1.0;
    }
  }

  /// Get animation duration multiplier based on performance and battery optimization
  double get animationDurationMultiplier {
    double multiplier = 1.0;

    // Adjust for performance level
    switch (_currentPerformanceLevel) {
      case DevicePerformanceLevel.low:
        multiplier *= 0.7; // Faster animations on low-end devices
        break;
      case DevicePerformanceLevel.medium:
        multiplier *= 0.85;
        break;
      case DevicePerformanceLevel.high:
        multiplier *= 1.0;
        break;
    }

    // Adjust for battery optimization
    switch (_batteryOptimizationLevel) {
      case BatteryOptimizationLevel.none:
        break;
      case BatteryOptimizationLevel.moderate:
        multiplier *= 0.8;
        break;
      case BatteryOptimizationLevel.aggressive:
        multiplier *= 0.5;
        break;
    }

    return multiplier;
  }

  /// Check if animations should be disabled entirely
  bool get shouldDisableAnimations {
    return _batteryOptimizationLevel == BatteryOptimizationLevel.aggressive ||
        _thermalState == ThermalState.critical ||
        (_currentPerformanceLevel == DevicePerformanceLevel.low &&
            _frameDropCount > 10);
  }

  /// Get maximum concurrent animations based on performance level
  int get maxConcurrentAnimations {
    switch (_currentPerformanceLevel) {
      case DevicePerformanceLevel.low:
        return 1;
      case DevicePerformanceLevel.medium:
        return 2;
      case DevicePerformanceLevel.high:
        return _batteryOptimizationLevel == BatteryOptimizationLevel.none
            ? 4
            : 3;
    }
  }

  /// Add callback for performance level changes
  void addPerformanceLevelChangeCallback(VoidCallback callback) {
    _performanceLevelChangeCallbacks.add(callback);
  }

  /// Remove callback for performance level changes
  void removePerformanceLevelChangeCallback(VoidCallback callback) {
    _performanceLevelChangeCallbacks.remove(callback);
  }

  /// Add callback for battery optimization changes
  void addBatteryOptimizationCallback(VoidCallback callback) {
    _batteryOptimizationCallbacks.add(callback);
  }

  /// Remove callback for battery optimization changes
  void removeBatteryOptimizationCallback(VoidCallback callback) {
    _batteryOptimizationCallbacks.remove(callback);
  }

  /// Report frame drop to update performance metrics
  void reportFrameDrop() {
    _frameDropCount++;

    // Check if we need to reduce performance level
    if (_frameDropCount > 5 &&
        _currentPerformanceLevel != DevicePerformanceLevel.low) {
      _reducePerformanceLevel();
    }
  }

  /// Report frame rate measurement
  void reportFrameRate(double frameRate) {
    _averageFrameRate =
        (_averageFrameRate * 0.9) +
        (frameRate * 0.1); // Exponential moving average

    // Check if performance has improved and we can increase level
    if (_averageFrameRate > 55.0 && _frameDropCount == 0) {
      Timer(const Duration(seconds: 5), () {
        if (_averageFrameRate > 55.0 && _frameDropCount == 0) {
          _increasePerformanceLevel();
        }
      });
    }
  }

  /// Get adaptive animation configuration
  AdaptiveAnimationConfig getAnimationConfig() {
    return AdaptiveAnimationConfig(
      enableMicroInteractions:
          _currentPerformanceLevel != DevicePerformanceLevel.low,
      enablePageTransitions: !shouldDisableAnimations,
      enableLoadingAnimations:
          _batteryOptimizationLevel != BatteryOptimizationLevel.aggressive,
      enableParticleEffects:
          _currentPerformanceLevel == DevicePerformanceLevel.high &&
          _batteryOptimizationLevel == BatteryOptimizationLevel.none,
      enableComplexAnimations:
          _currentPerformanceLevel == DevicePerformanceLevel.high,
      maxAnimationLayers: _getMaxAnimationLayers(),
      animationQuality: _getAnimationQuality(),
    );
  }

  /// Dispose the adaptive performance manager
  void dispose() {
    _performanceMonitorTimer?.cancel();
    _batteryMonitorTimer?.cancel();
    _memoryMonitorTimer?.cancel();
    _performanceLevelChangeCallbacks.clear();
    _batteryOptimizationCallbacks.clear();
  }

  // Private methods

  Future<void> _detectDeviceCapabilities() async {
    try {
      // Detect device performance level based on available information
      if (kIsWeb) {
        _currentPerformanceLevel = DevicePerformanceLevel.medium;
      } else if (AppPlatform.isIOS || AppPlatform.isAndroid) {
        // Use a heuristic based on initial frame rate and memory
        await Future.delayed(const Duration(milliseconds: 100));

        // Start with high performance and adjust based on actual performance
        _currentPerformanceLevel = DevicePerformanceLevel.high;
      } else {
        // Desktop platforms generally have good performance
        _currentPerformanceLevel = DevicePerformanceLevel.high;
      }
    } catch (e) {
      developer.log(
        'Error detecting device capabilities: $e',
        name: 'AdaptivePerformance',
      );
      _currentPerformanceLevel = DevicePerformanceLevel.medium; // Safe default
    }
  }

  Future<void> _initializeBatteryMonitoring() async {
    if (kIsWeb) return; // Battery API not available on web

    try {
      // Check initial battery state
      await _updateBatteryState();

      // Start periodic battery monitoring
      _batteryMonitorTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _updateBatteryState(),
      );
    } catch (e) {
      developer.log(
        'Battery monitoring not available: $e',
        name: 'AdaptivePerformance',
      );
    }
  }

  Future<void> _updateBatteryState() async {
    try {
      // This would typically use a battery plugin in a real implementation
      // For now, we'll simulate battery optimization based on performance

      if (_frameDropCount > 15 || _averageFrameRate < 45.0) {
        _setBatteryOptimizationLevel(BatteryOptimizationLevel.aggressive);
      } else if (_frameDropCount > 5 || _averageFrameRate < 55.0) {
        _setBatteryOptimizationLevel(BatteryOptimizationLevel.moderate);
      } else {
        _setBatteryOptimizationLevel(BatteryOptimizationLevel.none);
      }
    } catch (e) {
      developer.log(
        'Error updating battery state: $e',
        name: 'AdaptivePerformance',
      );
    }
  }

  Future<void> _initializeMemoryMonitoring() async {
    _memoryMonitorTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _updateMemoryUsage(),
    );
  }

  void _updateMemoryUsage() {
    try {
      // In a real implementation, this would use platform-specific memory APIs
      // For now, we'll estimate based on performance metrics

      if (_frameDropCount > 10) {
        _memoryUsageMB = 150; // High memory usage
      } else if (_frameDropCount > 5) {
        _memoryUsageMB = 100; // Medium memory usage
      } else {
        _memoryUsageMB = 50; // Low memory usage
      }

      // Adjust performance level based on memory pressure
      if (_memoryUsageMB > 200 &&
          _currentPerformanceLevel != DevicePerformanceLevel.low) {
        _reducePerformanceLevel();
      }
    } catch (e) {
      developer.log(
        'Error updating memory usage: $e',
        name: 'AdaptivePerformance',
      );
    }
  }

  void _startPerformanceMonitoring() {
    _performanceMonitorTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _evaluatePerformance(),
    );
  }

  void _evaluatePerformance() {
    // Reset frame drop count periodically
    if (_frameDropCount > 0) {
      _frameDropCount = (_frameDropCount * 0.8).round();
    }

    // Log current performance metrics
    developer.log(
      'Performance: Level=${_currentPerformanceLevel.name}, FPS=${_averageFrameRate.toStringAsFixed(1)}, Drops=$_frameDropCount, Memory=${_memoryUsageMB}MB',
      name: 'AdaptivePerformance',
    );
  }

  void _reducePerformanceLevel() {
    final oldLevel = _currentPerformanceLevel;

    switch (_currentPerformanceLevel) {
      case DevicePerformanceLevel.high:
        _currentPerformanceLevel = DevicePerformanceLevel.medium;
        break;
      case DevicePerformanceLevel.medium:
        _currentPerformanceLevel = DevicePerformanceLevel.low;
        break;
      case DevicePerformanceLevel.low:
        return; // Already at lowest level
    }

    developer.log(
      'Performance level reduced: ${oldLevel.name} -> ${_currentPerformanceLevel.name}',
      name: 'AdaptivePerformance',
    );
    _notifyPerformanceLevelChange();
  }

  void _increasePerformanceLevel() {
    final oldLevel = _currentPerformanceLevel;

    switch (_currentPerformanceLevel) {
      case DevicePerformanceLevel.low:
        _currentPerformanceLevel = DevicePerformanceLevel.medium;
        break;
      case DevicePerformanceLevel.medium:
        _currentPerformanceLevel = DevicePerformanceLevel.high;
        break;
      case DevicePerformanceLevel.high:
        return; // Already at highest level
    }

    developer.log(
      'Performance level increased: ${oldLevel.name} -> ${_currentPerformanceLevel.name}',
      name: 'AdaptivePerformance',
    );
    _notifyPerformanceLevelChange();
  }

  void _setBatteryOptimizationLevel(BatteryOptimizationLevel level) {
    if (_batteryOptimizationLevel != level) {
      final oldLevel = _batteryOptimizationLevel;
      _batteryOptimizationLevel = level;

      developer.log(
        'Battery optimization level changed: ${oldLevel.name} -> ${level.name}',
        name: 'AdaptivePerformance',
      );
      _notifyBatteryOptimizationChange();
    }
  }

  void _notifyPerformanceLevelChange() {
    for (final callback in _performanceLevelChangeCallbacks) {
      try {
        callback();
      } catch (e) {
        developer.log(
          'Error in performance level change callback: $e',
          name: 'AdaptivePerformance',
        );
      }
    }
  }

  void _notifyBatteryOptimizationChange() {
    for (final callback in _batteryOptimizationCallbacks) {
      try {
        callback();
      } catch (e) {
        developer.log(
          'Error in battery optimization change callback: $e',
          name: 'AdaptivePerformance',
        );
      }
    }
  }

  int _getMaxAnimationLayers() {
    switch (_currentPerformanceLevel) {
      case DevicePerformanceLevel.low:
        return 1;
      case DevicePerformanceLevel.medium:
        return 2;
      case DevicePerformanceLevel.high:
        return _batteryOptimizationLevel == BatteryOptimizationLevel.none
            ? 4
            : 3;
    }
  }

  AnimationQuality _getAnimationQuality() {
    if (_batteryOptimizationLevel == BatteryOptimizationLevel.aggressive) {
      return AnimationQuality.low;
    }

    switch (_currentPerformanceLevel) {
      case DevicePerformanceLevel.low:
        return AnimationQuality.low;
      case DevicePerformanceLevel.medium:
        return AnimationQuality.medium;
      case DevicePerformanceLevel.high:
        return AnimationQuality.high;
    }
  }
}

/// Device performance levels
enum DevicePerformanceLevel { low, medium, high }

/// Battery optimization levels
enum BatteryOptimizationLevel { none, moderate, aggressive }

/// Thermal states
enum ThermalState { normal, warm, hot, critical }

/// Animation quality levels
enum AnimationQuality { low, medium, high }

/// Adaptive animation configuration
class AdaptiveAnimationConfig {
  final bool enableMicroInteractions;
  final bool enablePageTransitions;
  final bool enableLoadingAnimations;
  final bool enableParticleEffects;
  final bool enableComplexAnimations;
  final int maxAnimationLayers;
  final AnimationQuality animationQuality;

  const AdaptiveAnimationConfig({
    required this.enableMicroInteractions,
    required this.enablePageTransitions,
    required this.enableLoadingAnimations,
    required this.enableParticleEffects,
    required this.enableComplexAnimations,
    required this.maxAnimationLayers,
    required this.animationQuality,
  });

  /// Create a configuration for low performance devices
  factory AdaptiveAnimationConfig.lowPerformance() {
    return const AdaptiveAnimationConfig(
      enableMicroInteractions: false,
      enablePageTransitions: true,
      enableLoadingAnimations: true,
      enableParticleEffects: false,
      enableComplexAnimations: false,
      maxAnimationLayers: 1,
      animationQuality: AnimationQuality.low,
    );
  }

  /// Create a configuration for high performance devices
  factory AdaptiveAnimationConfig.highPerformance() {
    return const AdaptiveAnimationConfig(
      enableMicroInteractions: true,
      enablePageTransitions: true,
      enableLoadingAnimations: true,
      enableParticleEffects: true,
      enableComplexAnimations: true,
      maxAnimationLayers: 4,
      animationQuality: AnimationQuality.high,
    );
  }

  @override
  String toString() {
    return 'AdaptiveAnimationConfig('
        'microInteractions: $enableMicroInteractions, '
        'pageTransitions: $enablePageTransitions, '
        'loadingAnimations: $enableLoadingAnimations, '
        'particleEffects: $enableParticleEffects, '
        'complexAnimations: $enableComplexAnimations, '
        'maxLayers: $maxAnimationLayers, '
        'quality: ${animationQuality.name})';
  }
}

/// Widget that adapts its animation behavior based on device performance
class AdaptiveAnimationBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, AdaptiveAnimationConfig config)
  builder;

  const AdaptiveAnimationBuilder({super.key, required this.builder});

  @override
  State<AdaptiveAnimationBuilder> createState() =>
      _AdaptiveAnimationBuilderState();
}

class _AdaptiveAnimationBuilderState extends State<AdaptiveAnimationBuilder> {
  late AdaptiveAnimationConfig _config;

  @override
  void initState() {
    super.initState();
    _config = AdaptivePerformanceManager().getAnimationConfig();

    // Listen for performance changes
    AdaptivePerformanceManager().addPerformanceLevelChangeCallback(
      _updateConfig,
    );
    AdaptivePerformanceManager().addBatteryOptimizationCallback(_updateConfig);
  }

  @override
  void dispose() {
    AdaptivePerformanceManager().removePerformanceLevelChangeCallback(
      _updateConfig,
    );
    AdaptivePerformanceManager().removeBatteryOptimizationCallback(
      _updateConfig,
    );
    super.dispose();
  }

  void _updateConfig() {
    if (mounted) {
      setState(() {
        _config = AdaptivePerformanceManager().getAnimationConfig();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _config);
  }
}
