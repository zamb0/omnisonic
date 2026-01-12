import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'accessibility_preferences.dart';
import 'adaptive_performance.dart';
import 'gesture_feedback.dart';

/// Animation priority levels for coordination
enum AnimationPriority {
  low,
  normal,
  high,
  critical,
}

/// Represents a single step in an animation sequence
abstract class AnimationStep {
  Future<void> execute();
}

/// Animation coordination system to prevent performance degradation
/// when multiple animations run simultaneously
class AnimationCoordinator {
  final Map<AnimationController, AnimationPriority> _registeredControllers = {};
  final Set<AnimationController> _runningAnimations = {};
  final Queue<_CoordinatedAnimation> _animationQueue = Queue();
  bool _isProcessingQueue = false;
  int _maxConcurrentAnimations = 3;
  bool _performanceIssueDetected = false;
  
  /// Register a controller with the coordinator
  void registerController(AnimationController controller, AnimationPriority priority) {
    _registeredControllers[controller] = priority;
    
    // Add listener to track running state
    controller.addStatusListener((status) {
      if (status == AnimationStatus.forward || status == AnimationStatus.reverse) {
        _runningAnimations.add(controller);
      } else if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        _runningAnimations.remove(controller);
        _processQueue();
      }
    });
  }
  
  /// Unregister a controller from the coordinator
  void unregisterController(AnimationController controller) {
    _registeredControllers.remove(controller);
    _runningAnimations.remove(controller);
  }
  
  /// Coordinate animation execution to prevent performance issues
  Future<void> coordinateExecution(
    AnimationController controller,
    Future<void> Function() animationFunction,
  ) async {
    final priority = _registeredControllers[controller] ?? AnimationPriority.normal;
    
    // Check if we can run immediately
    if (_canRunImmediately(priority)) {
      await animationFunction();
    } else {
      // Queue the animation
      final coordinatedAnimation = _CoordinatedAnimation(
        controller: controller,
        priority: priority,
        animationFunction: animationFunction,
        completer: Completer<void>(),
      );
      
      _animationQueue.add(coordinatedAnimation);
      _processQueue();
      
      // Wait for the animation to complete
      await coordinatedAnimation.completer.future;
    }
  }
  
  /// Handle performance issues by reducing concurrent animations
  void handlePerformanceIssue() {
    _performanceIssueDetected = true;
    _maxConcurrentAnimations = (_maxConcurrentAnimations - 1).clamp(1, 3);
    
    developer.log('Performance issue detected, reducing max concurrent animations to $_maxConcurrentAnimations', name: 'AnimationCoordinator');
    
    // Reset performance issue flag after a delay
    Timer(const Duration(seconds: 10), () {
      _performanceIssueDetected = false;
      _maxConcurrentAnimations = (_maxConcurrentAnimations + 1).clamp(1, 3);
    });
  }
  
  /// Check if an animation can run immediately based on priority and current load
  bool _canRunImmediately(AnimationPriority priority) {
    // Critical animations always run immediately
    if (priority == AnimationPriority.critical) {
      return true;
    }
    
    // Check current load
    final currentLoad = _runningAnimations.length;
    
    // Adjust threshold based on performance issues
    final threshold = _performanceIssueDetected 
        ? (_maxConcurrentAnimations * 0.7).floor()
        : _maxConcurrentAnimations;
    
    if (currentLoad < threshold) {
      return true;
    }
    
    // High priority animations can preempt low priority ones
    if (priority == AnimationPriority.high) {
      final lowPriorityCount = _runningAnimations
          .where((controller) => _registeredControllers[controller] == AnimationPriority.low)
          .length;
      return lowPriorityCount > 0;
    }
    
    return false;
  }
  
  /// Process the animation queue
  void _processQueue() {
    if (_isProcessingQueue || _animationQueue.isEmpty) {
      return;
    }
    
    _isProcessingQueue = true;
    
    // Sort queue by priority
    final sortedQueue = _animationQueue.toList()
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
    
    _animationQueue.clear();
    _animationQueue.addAll(sortedQueue);
    
    // Process animations that can run now
    final animationsToRun = <_CoordinatedAnimation>[];
    
    while (_animationQueue.isNotEmpty) {
      final animation = _animationQueue.first;
      
      if (_canRunImmediately(animation.priority)) {
        animationsToRun.add(_animationQueue.removeFirst());
      } else {
        break;
      }
    }
    
    // Execute animations
    for (final animation in animationsToRun) {
      _executeCoordinatedAnimation(animation);
    }
    
    _isProcessingQueue = false;
  }
  
  /// Execute a coordinated animation
  Future<void> _executeCoordinatedAnimation(_CoordinatedAnimation animation) async {
    try {
      await animation.animationFunction();
      animation.completer.complete();
    } catch (e) {
      animation.completer.completeError(e);
    }
  }
  
  /// Set maximum concurrent animations
  void setMaxConcurrentAnimations(int max) {
    _maxConcurrentAnimations = max.clamp(1, 10);
  }
  
  /// Get maximum concurrent animations
  int get maxConcurrentAnimations => _maxConcurrentAnimations;
  
  /// Get current coordination statistics
  Map<String, dynamic> getCoordinationStats() {
    return {
      'registeredControllers': _registeredControllers.length,
      'runningAnimations': _runningAnimations.length,
      'queuedAnimations': _animationQueue.length,
      'maxConcurrentAnimations': _maxConcurrentAnimations,
      'performanceIssueDetected': _performanceIssueDetected,
    };
  }
  
  /// Dispose the coordinator
  void dispose() {
    _registeredControllers.clear();
    _runningAnimations.clear();
    
    // Complete any pending animations with error
    while (_animationQueue.isNotEmpty) {
      final animation = _animationQueue.removeFirst();
      animation.completer.completeError('Coordinator disposed');
    }
  }
}

/// Internal class for coordinated animations
class _CoordinatedAnimation {
  final AnimationController controller;
  final AnimationPriority priority;
  final Future<void> Function() animationFunction;
  final Completer<void> completer;
  
  _CoordinatedAnimation({
    required this.controller,
    required this.priority,
    required this.animationFunction,
    required this.completer,
  });
}

/// A step that runs an animation controller
class ControllerAnimationStep extends AnimationStep {
  final AnimationController controller;
  final bool forward;
  
  ControllerAnimationStep(this.controller, {this.forward = true});
  
  @override
  Future<void> execute() async {
    if (forward) {
      await controller.forward();
    } else {
      await controller.reverse();
    }
  }
}

/// A step that waits for a specified duration
class DelayAnimationStep extends AnimationStep {
  final Duration duration;
  
  DelayAnimationStep(this.duration);
  
  @override
  Future<void> execute() async {
    await Future.delayed(duration);
  }
}

/// Comprehensive animation management system for Omnisonic UI Enhancement
/// Provides standardized durations, curves, and performance monitoring
/// with full accessibility support including reduced motion preferences
/// Enhanced with hardware acceleration, coordination system, and efficient cleanup
class AnimationManager {
  static final AnimationManager _instance = AnimationManager._internal();
  factory AnimationManager() => _instance;
  AnimationManager._internal();
  
  // Accessibility preferences
  final OmnisonicAccessibilityPreferences _accessibilityPreferences = 
      OmnisonicAccessibilityPreferences();
  
  // Adaptive performance manager
  final AdaptivePerformanceManager _adaptivePerformance = AdaptivePerformanceManager();
  
  // Performance monitoring and optimization
  final List<AnimationController> _activeControllers = [];
  final Map<String, AnimationPerformanceData> _performanceData = {};
  final Set<AnimationController> _hardwareAcceleratedControllers = {};
  final AnimationCoordinator _coordinator = AnimationCoordinator();
  Timer? _performanceMonitorTimer;
  Timer? _cleanupTimer;
  bool _performanceMonitoringEnabled = false;
  bool _hardwareAccelerationEnabled = true;
  int _frameDropThreshold = 3;
  int _frameDropCount = 0;
  double _currentFrameRate = 60.0;
  
  // Animation durations - standardized across the app
  static const Duration fastDuration = Duration(milliseconds: 150);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);
  static const Duration extraSlowDuration = Duration(milliseconds: 800);
  
  // Micro-interaction durations
  static const Duration tapDuration = Duration(milliseconds: 100);
  static const Duration hoverDuration = Duration(milliseconds: 200);
  static const Duration rippleDuration = Duration(milliseconds: 300);
  
  // Page transition durations
  static const Duration pageTransitionDuration = Duration(milliseconds: 350);
  static const Duration modalTransitionDuration = Duration(milliseconds: 400);
  
  // Loading animation durations
  static const Duration shimmerDuration = Duration(milliseconds: 1500);
  static const Duration pulsingDuration = Duration(milliseconds: 1000);
  static const Duration progressDuration = Duration(milliseconds: 250);
  
  // Standard animation curves
  static const Curve standardCurve = Curves.easeInOutCubic;
  static const Curve fastCurve = Curves.easeOutQuart;
  static const Curve slowCurve = Curves.easeInOutQuint;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve springCurve = Curves.bounceOut;
  
  // Micro-interaction curves
  static const Curve tapCurve = Curves.easeOutCirc;
  static const Curve hoverCurve = Curves.easeInOutCubic;
  static const Curve rippleCurve = Curves.easeOutQuart;
  
  // Page transition curves
  static const Curve slideInCurve = Curves.easeOutCubic;
  static const Curve slideOutCurve = Curves.easeInCubic;
  static const Curve fadeInCurve = Curves.easeIn;
  static const Curve fadeOutCurve = Curves.easeOut;
  
  // Loading animation curves
  static const Curve shimmerCurve = Curves.easeInOut;
  static const Curve pulsingCurve = Curves.easeInOutSine;
  static const Curve progressCurve = Curves.easeInOutCubic;
  
  /// Initialize the animation manager with performance monitoring and accessibility
  Future<void> initialize({
    bool enablePerformanceMonitoring = false,
    bool enableHardwareAcceleration = true,
    int frameDropThreshold = 3,
  }) async {
    _performanceMonitoringEnabled = enablePerformanceMonitoring;
    _hardwareAccelerationEnabled = enableHardwareAcceleration;
    _frameDropThreshold = frameDropThreshold;
    
    // Initialize accessibility preferences
    await _accessibilityPreferences.initialize();
    
    // Initialize adaptive performance manager
    await _adaptivePerformance.initialize();
    
    // Set up adaptive performance callbacks
    _adaptivePerformance.addPerformanceLevelChangeCallback(_onPerformanceLevelChanged);
    _adaptivePerformance.addBatteryOptimizationCallback(_onBatteryOptimizationChanged);
    
    if (_performanceMonitoringEnabled) {
      _startPerformanceMonitoring();
    }
    
    // Start cleanup timer for efficient memory management
    _startCleanupTimer();
    
    // Initialize frame rate monitoring
    _initializeFrameRateMonitoring();
  }
  
  /// Enable hardware acceleration for transforms and opacity animations
  void enableHardwareAcceleration(AnimationController controller) {
    if (_hardwareAccelerationEnabled && !kIsWeb) {
      _hardwareAcceleratedControllers.add(controller);
      
      // Add listener to ensure proper cleanup
      controller.addStatusListener((status) {
        if (status == AnimationStatus.dismissed || status == AnimationStatus.completed) {
          _hardwareAcceleratedControllers.remove(controller);
        }
      });
    }
  }
  
  /// Check if hardware acceleration is available and enabled
  bool get isHardwareAccelerationEnabled => _hardwareAccelerationEnabled && !kIsWeb;
  
  /// Get current frame rate
  double get currentFrameRate => _currentFrameRate;
  
  /// Get duration adjusted for accessibility preferences and adaptive performance
  Duration getAccessibleDuration(Duration originalDuration) {
    Duration adjustedDuration = _accessibilityPreferences.getAdjustedDuration(originalDuration);
    
    // Apply adaptive performance adjustments
    final performanceMultiplier = _adaptivePerformance.animationDurationMultiplier;
    final finalDuration = Duration(
      milliseconds: (adjustedDuration.inMilliseconds * performanceMultiplier).round(),
    );
    
    return finalDuration;
  }
  
  /// Get curve adjusted for accessibility preferences
  Curve getAccessibleCurve(Curve originalCurve) {
    return _accessibilityPreferences.getAdjustedCurve(originalCurve);
  }
  
  /// Check if animations should be enabled based on accessibility and performance
  bool get animationsEnabled => 
      !_accessibilityPreferences.shouldDisableAnimations && 
      !_adaptivePerformance.shouldDisableAnimations;
  
  /// Get animation scale factor from accessibility preferences and adaptive performance
  double get animationScale => 
      _accessibilityPreferences.animationScale * _adaptivePerformance.animationComplexityMultiplier;
  
  /// Create a managed animation controller with automatic cleanup and monitoring
  /// Respects accessibility preferences for reduced motion
  /// Enhanced with hardware acceleration and coordination
  AnimationController createController({
    required Duration duration,
    required TickerProvider vsync,
    String? debugLabel,
    double? value,
    Duration? reverseDuration,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    bool enableHardwareAcceleration = true,
    AnimationPriority priority = AnimationPriority.normal,
  }) {
    // Adjust duration and reverse duration for accessibility
    final adjustedDuration = getAccessibleDuration(duration);
    final adjustedReverseDuration = reverseDuration != null 
        ? getAccessibleDuration(reverseDuration)
        : null;
    
    final controller = AnimationController(
      duration: adjustedDuration,
      vsync: vsync,
      debugLabel: debugLabel,
      value: value,
      reverseDuration: adjustedReverseDuration,
      animationBehavior: animationBehavior,
    );
    
    // If animations are disabled, set to final value immediately
    if (!animationsEnabled) {
      controller.value = 1.0;
    }
    
    // Add to active controllers for monitoring
    _activeControllers.add(controller);
    
    // Enable hardware acceleration if requested and available
    if (enableHardwareAcceleration) {
      this.enableHardwareAcceleration(controller);
    }
    
    // Register with coordinator for timing coordination
    _coordinator.registerController(controller, priority);
    
    // Add performance tracking
    if (_performanceMonitoringEnabled && debugLabel != null) {
      _trackControllerPerformance(controller, debugLabel);
    }
    
    // Auto-cleanup when disposed
    controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed || status == AnimationStatus.completed) {
        // Remove from active controllers when animation completes
        _activeControllers.remove(controller);
        _hardwareAcceleratedControllers.remove(controller);
        _coordinator.unregisterController(controller);
      }
    });
    
    return controller;
  }
  
  /// Create a tween animation with standardized configuration and accessibility support
  Animation<T> createTween<T>({
    required AnimationController controller,
    required T begin,
    required T end,
    Curve curve = standardCurve,
  }) {
    // Adjust curve for accessibility
    final adjustedCurve = getAccessibleCurve(curve);
    
    return Tween<T>(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: adjustedCurve),
    );
  }
  
  /// Create a color tween animation with accessibility support
  Animation<Color?> createColorTween({
    required AnimationController controller,
    required Color begin,
    required Color end,
    Curve curve = standardCurve,
  }) {
    // Adjust curve for accessibility
    final adjustedCurve = getAccessibleCurve(curve);
    
    return ColorTween(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: adjustedCurve),
    );
  }
  
  /// Create a size tween animation with accessibility support
  Animation<Size?> createSizeTween({
    required AnimationController controller,
    required Size begin,
    required Size end,
    Curve curve = standardCurve,
  }) {
    // Adjust curve for accessibility
    final adjustedCurve = getAccessibleCurve(curve);
    
    return SizeTween(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: adjustedCurve),
    );
  }
  
  /// Create a staggered animation sequence with accessibility support
  List<Animation<double>> createStaggeredAnimations({
    required AnimationController controller,
    required int count,
    Duration staggerDelay = const Duration(milliseconds: 50),
    Curve curve = standardCurve,
  }) {
    final animations = <Animation<double>>[];
    final totalDuration = controller.duration!.inMilliseconds;
    final adjustedDelay = getAccessibleDuration(staggerDelay);
    final delayMs = adjustedDelay.inMilliseconds;
    final adjustedCurve = getAccessibleCurve(curve);
    
    // If animations are disabled, return simple animations
    if (!animationsEnabled) {
      for (int i = 0; i < count; i++) {
        animations.add(
          Tween<double>(begin: 1.0, end: 1.0).animate(controller),
        );
      }
      return animations;
    }
    
    for (int i = 0; i < count; i++) {
      final startTime = (i * delayMs) / totalDuration;
      final endTime = 1.0;
      
      animations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(startTime, endTime, curve: adjustedCurve),
          ),
        ),
      );
    }
    
    return animations;
  }
  
  /// Execute an animation with automatic cleanup and error handling
  /// Enhanced with coordination and performance monitoring
  Future<void> executeAnimation({
    required AnimationController controller,
    bool forward = true,
    bool autoReverse = false,
    int repeatCount = 1,
    VoidCallback? onComplete,
    VoidCallback? onError,
    bool coordinateWithOthers = true,
  }) async {
    try {
      // Coordinate with other animations if requested
      if (coordinateWithOthers) {
        await _coordinator.coordinateExecution(controller, () async {
          await _executeAnimationInternal(
            controller: controller,
            forward: forward,
            autoReverse: autoReverse,
            repeatCount: repeatCount,
          );
        });
      } else {
        await _executeAnimationInternal(
          controller: controller,
          forward: forward,
          autoReverse: autoReverse,
          repeatCount: repeatCount,
        );
      }
      
      onComplete?.call();
    } catch (e) {
      developer.log('Animation execution error: $e', name: 'AnimationManager');
      onError?.call();
      
      // Attempt to reset controller to safe state
      try {
        controller.reset();
      } catch (resetError) {
        developer.log('Failed to reset controller: $resetError', name: 'AnimationManager');
      }
    }
  }
  
  /// Internal animation execution method
  Future<void> _executeAnimationInternal({
    required AnimationController controller,
    required bool forward,
    required bool autoReverse,
    required int repeatCount,
  }) async {
    for (int i = 0; i < repeatCount; i++) {
      if (forward) {
        await controller.forward();
      } else {
        await controller.reverse();
      }
      
      if (autoReverse && i < repeatCount - 1) {
        if (forward) {
          await controller.reverse();
        } else {
          await controller.forward();
        }
      }
    }
  }
  
  /// Create a haptic feedback animation with accessibility support
  Future<void> triggerHapticFeedback({
    HapticFeedbackType type = HapticFeedbackType.light,
    bool respectUserSettings = true,
  }) async {
    if (respectUserSettings) {
      await _accessibilityPreferences.triggerHapticFeedback(type);
    } else {
      // Force haptic feedback regardless of user settings
      await OmnisonicGestureFeedback.hapticFeedback(type);
    }
  }
  
  /// Dispose all active controllers and cleanup resources
  /// Enhanced with comprehensive cleanup and coordination disposal
  void dispose() {
    _performanceMonitorTimer?.cancel();
    _cleanupTimer?.cancel();
    
    // Remove adaptive performance callbacks
    _adaptivePerformance.removePerformanceLevelChangeCallback(_onPerformanceLevelChanged);
    _adaptivePerformance.removeBatteryOptimizationCallback(_onBatteryOptimizationChanged);
    
    // Dispose coordinator
    _coordinator.dispose();
    
    // Dispose all active controllers with error handling
    for (final controller in List.from(_activeControllers)) {
      try {
        if (!controller.isCompleted && !controller.isDismissed) {
          controller.dispose();
        }
      } catch (e) {
        developer.log('Error disposing controller: $e', name: 'AnimationManager');
      }
    }
    
    // Clear all collections
    _activeControllers.clear();
    _hardwareAcceleratedControllers.clear();
    _performanceData.clear();
  }
  
  /// Force cleanup of completed animations and unused resources
  void forceCleanup() {
    final now = DateTime.now();
    final controllersToRemove = <AnimationController>[];
    
    // Find controllers that should be cleaned up
    for (final controller in _activeControllers) {
      if (controller.isCompleted || controller.isDismissed) {
        controllersToRemove.add(controller);
      }
    }
    
    // Remove completed controllers
    for (final controller in controllersToRemove) {
      _activeControllers.remove(controller);
      _hardwareAcceleratedControllers.remove(controller);
      _coordinator.unregisterController(controller);
    }
    
    // Clean up old performance data
    final dataToRemove = <String>[];
    for (final entry in _performanceData.entries) {
      if (entry.value.endTime != null) {
        final age = now.difference(entry.value.endTime!);
        if (age > const Duration(minutes: 5)) {
          dataToRemove.add(entry.key);
        }
      }
    }
    
    for (final key in dataToRemove) {
      _performanceData.remove(key);
    }
    
    developer.log('Cleanup completed: removed ${controllersToRemove.length} controllers, ${dataToRemove.length} performance entries', name: 'AnimationManager');
  }
  
  /// Get performance statistics for debugging
  Map<String, AnimationPerformanceData> getPerformanceData() {
    return Map.unmodifiable(_performanceData);
  }
  
  /// Get current active animation count
  int get activeAnimationCount => _activeControllers.length;
  
  /// Check if performance monitoring is enabled
  bool get isPerformanceMonitoringEnabled => _performanceMonitoringEnabled;
  
  // Private methods
  
  void _startPerformanceMonitoring() {
    _performanceMonitorTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _logPerformanceMetrics(),
    );
  }
  
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => forceCleanup(),
    );
  }
  
  void _initializeFrameRateMonitoring() {
    if (_performanceMonitoringEnabled) {
      SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    }
  }
  
  void _onFrameTimings(List<FrameTiming> timings) {
    if (timings.isEmpty) return;
    
    // Calculate average frame rate from recent timings
    double totalFrameTime = 0;
    int validFrames = 0;
    
    for (final timing in timings) {
      final frameTime = timing.totalSpan.inMicroseconds / 1000.0; // Convert to milliseconds
      if (frameTime > 0 && frameTime < 100) { // Filter out invalid timings
        totalFrameTime += frameTime;
        validFrames++;
      }
    }
    
    if (validFrames > 0) {
      final averageFrameTime = totalFrameTime / validFrames;
      _currentFrameRate = 1000.0 / averageFrameTime; // Convert to FPS
      
      // Report frame rate to adaptive performance manager
      _adaptivePerformance.reportFrameRate(_currentFrameRate);
      
      // Check for frame drops
      if (_currentFrameRate < 55.0 && _activeControllers.isNotEmpty) {
        _frameDropCount++;
        if (_frameDropCount >= _frameDropThreshold) {
          _handleFrameDrops();
        }
      } else {
        // Reset frame drop count when performance is good
        _frameDropCount = 0;
      }
    }
  }
  
  void _handleFrameDrops() {
    developer.log('Frame drops detected: ${_currentFrameRate.toStringAsFixed(1)} FPS with ${_activeControllers.length} active animations', name: 'AnimationManager');
    
    // Report frame drop to adaptive performance manager
    _adaptivePerformance.reportFrameDrop();
    
    // Notify coordinator about performance issues
    _coordinator.handlePerformanceIssue();
    
    // Consider reducing animation complexity if frame drops persist
    if (_currentFrameRate < 45.0) {
      developer.log('Severe frame drops detected, consider reducing animation complexity', name: 'AnimationManager');
    }
  }
  
  void _onPerformanceLevelChanged() {
    developer.log('Performance level changed to: ${_adaptivePerformance.currentPerformanceLevel.name}', name: 'AnimationManager');
    
    // Update coordinator max concurrent animations
    _coordinator.setMaxConcurrentAnimations(_adaptivePerformance.maxConcurrentAnimations);
    
    // Force cleanup if performance is low
    if (_adaptivePerformance.currentPerformanceLevel == DevicePerformanceLevel.low) {
      forceCleanup();
    }
  }
  
  void _onBatteryOptimizationChanged() {
    developer.log('Battery optimization changed to: ${_adaptivePerformance.batteryOptimizationLevel.name}', name: 'AnimationManager');
    
    // Adjust performance monitoring frequency based on battery optimization
    if (_adaptivePerformance.batteryOptimizationLevel == BatteryOptimizationLevel.aggressive) {
      // Reduce monitoring frequency to save battery
      _performanceMonitorTimer?.cancel();
      _performanceMonitorTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => _logPerformanceMetrics(),
      );
    }
  }
  
  void _trackControllerPerformance(AnimationController controller, String label) {
    final data = AnimationPerformanceData(
      label: label,
      startTime: DateTime.now(),
      duration: controller.duration!,
    );
    
    _performanceData[label] = data;
    
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        data.endTime = DateTime.now();
        data.completedSuccessfully = true;
      }
    });
  }
  
  void _logPerformanceMetrics() {
    if (_activeControllers.isEmpty) return;
    
    final activeCount = _activeControllers.length;
    final completedCount = _performanceData.values
        .where((data) => data.completedSuccessfully)
        .length;
    
    developer.log(
      'Animation Performance: $activeCount active, $completedCount completed',
      name: 'AnimationManager',
    );
    
    // Log any controllers that have been running for too long
    final now = DateTime.now();
    for (final data in _performanceData.values) {
      if (data.endTime == null) {
        final runningTime = now.difference(data.startTime);
        if (runningTime > const Duration(seconds: 10)) {
          developer.log(
            'Long-running animation detected: ${data.label} (${runningTime.inSeconds}s)',
            name: 'AnimationManager',
          );
        }
      }
    }
  }
}

/// Performance data tracking for animations
class AnimationPerformanceData {
  final String label;
  final DateTime startTime;
  final Duration duration;
  DateTime? endTime;
  bool completedSuccessfully = false;
  
  AnimationPerformanceData({
    required this.label,
    required this.startTime,
    required this.duration,
  });
  
  Duration? get actualDuration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }
  
  bool get isRunning => endTime == null;
  
  double? get performanceRatio {
    final actual = actualDuration;
    if (actual == null) return null;
    return actual.inMilliseconds / duration.inMilliseconds;
  }
}

/// Animation utilities for common patterns
class AnimationUtilities {
  /// Create a bounce animation
  static Animation<double> createBounceAnimation({
    required AnimationController controller,
    double bounceHeight = 0.1,
  }) {
    return Tween<double>(
      begin: 0.0,
      end: bounceHeight,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: AnimationManager.bounceCurve,
    ));
  }
  
  /// Create a scale animation for micro-interactions
  static Animation<double> createScaleAnimation({
    required AnimationController controller,
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return Tween<double>(
      begin: minScale,
      end: maxScale,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: AnimationManager.tapCurve,
    ));
  }
  
  /// Create a rotation animation
  static Animation<double> createRotationAnimation({
    required AnimationController controller,
    double turns = 1.0,
  }) {
    return Tween<double>(
      begin: 0.0,
      end: turns,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: AnimationManager.standardCurve,
    ));
  }
  
  /// Create a slide animation
  static Animation<Offset> createSlideAnimation({
    required AnimationController controller,
    Offset begin = const Offset(0.0, 1.0),
    Offset end = Offset.zero,
    Curve curve = AnimationManager.slideInCurve,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }
  
  /// Create a fade animation
  static Animation<double> createFadeAnimation({
    required AnimationController controller,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = AnimationManager.fadeInCurve,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }
}

/// Extension for easy access to animation manager from theme
class OmnisonicAnimationExtension extends ThemeExtension<OmnisonicAnimationExtension> {
  final Duration fastDuration;
  final Duration normalDuration;
  final Duration slowDuration;
  final Curve standardCurve;
  final Curve fastCurve;
  final Curve slowCurve;
  final bool enableMicroInteractions;
  final bool enablePageTransitions;
  final bool enableLoadingAnimations;
  final double animationScale;
  
  const OmnisonicAnimationExtension({
    this.fastDuration = AnimationManager.fastDuration,
    this.normalDuration = AnimationManager.normalDuration,
    this.slowDuration = AnimationManager.slowDuration,
    this.standardCurve = AnimationManager.standardCurve,
    this.fastCurve = AnimationManager.fastCurve,
    this.slowCurve = AnimationManager.slowCurve,
    this.enableMicroInteractions = true,
    this.enablePageTransitions = true,
    this.enableLoadingAnimations = true,
    this.animationScale = 1.0,
  });
  
  @override
  ThemeExtension<OmnisonicAnimationExtension> copyWith({
    Duration? fastDuration,
    Duration? normalDuration,
    Duration? slowDuration,
    Curve? standardCurve,
    Curve? fastCurve,
    Curve? slowCurve,
    bool? enableMicroInteractions,
    bool? enablePageTransitions,
    bool? enableLoadingAnimations,
    double? animationScale,
  }) {
    return OmnisonicAnimationExtension(
      fastDuration: fastDuration ?? this.fastDuration,
      normalDuration: normalDuration ?? this.normalDuration,
      slowDuration: slowDuration ?? this.slowDuration,
      standardCurve: standardCurve ?? this.standardCurve,
      fastCurve: fastCurve ?? this.fastCurve,
      slowCurve: slowCurve ?? this.slowCurve,
      enableMicroInteractions: enableMicroInteractions ?? this.enableMicroInteractions,
      enablePageTransitions: enablePageTransitions ?? this.enablePageTransitions,
      enableLoadingAnimations: enableLoadingAnimations ?? this.enableLoadingAnimations,
      animationScale: animationScale ?? this.animationScale,
    );
  }
  
  @override
  ThemeExtension<OmnisonicAnimationExtension> lerp(
    ThemeExtension<OmnisonicAnimationExtension>? other,
    double t,
  ) {
    if (other is! OmnisonicAnimationExtension) {
      return this;
    }
    
    return OmnisonicAnimationExtension(
      fastDuration: Duration(
        milliseconds: (fastDuration.inMilliseconds * (1 - t) + 
                     other.fastDuration.inMilliseconds * t).round(),
      ),
      normalDuration: Duration(
        milliseconds: (normalDuration.inMilliseconds * (1 - t) + 
                     other.normalDuration.inMilliseconds * t).round(),
      ),
      slowDuration: Duration(
        milliseconds: (slowDuration.inMilliseconds * (1 - t) + 
                     other.slowDuration.inMilliseconds * t).round(),
      ),
      standardCurve: t < 0.5 ? standardCurve : other.standardCurve,
      fastCurve: t < 0.5 ? fastCurve : other.fastCurve,
      slowCurve: t < 0.5 ? slowCurve : other.slowCurve,
      enableMicroInteractions: t < 0.5 ? enableMicroInteractions : other.enableMicroInteractions,
      enablePageTransitions: t < 0.5 ? enablePageTransitions : other.enablePageTransitions,
      enableLoadingAnimations: t < 0.5 ? enableLoadingAnimations : other.enableLoadingAnimations,
      animationScale: animationScale * (1 - t) + other.animationScale * t,
    );
  }
}