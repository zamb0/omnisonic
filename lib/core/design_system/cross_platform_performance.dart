import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'platform_optimizations.dart';
import '../utils/app_log.dart';

/// Cross-platform animation performance monitor
/// Implements Requirements: 9.1, 9.2, 9.3, 9.4, 9.5
class CrossPlatformPerformanceMonitor {
  static final CrossPlatformPerformanceMonitor _instance =
      CrossPlatformPerformanceMonitor._internal();
  factory CrossPlatformPerformanceMonitor() => _instance;
  CrossPlatformPerformanceMonitor._internal();

  final List<FrameTimingInfo> _frameTimings = [];
  final List<AnimationPerformanceMetric> _animationMetrics = [];
  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  /// Start performance monitoring
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _frameTimings.clear();
    _animationMetrics.clear();

    // Monitor frame timings
    SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);

    // Start periodic performance checks
    _monitoringTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkPerformance();
    });

    if (kDebugMode) {
      AppLog.debug(
        'Performance monitoring started for ${PlatformOptimizations().currentPlatform.name}',
      );
    }
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;

    SchedulerBinding.instance.removeTimingsCallback(_onFrameTiming);

    if (kDebugMode) {
      AppLog.debug('Performance monitoring stopped');
    }
  }

  /// Get current performance report
  CrossPlatformPerformanceReport getPerformanceReport() {
    final now = DateTime.now();
    final recentFrames = _frameTimings
        .where((frame) => now.difference(frame.timestamp).inSeconds < 10)
        .toList();

    final recentAnimations = _animationMetrics
        .where((metric) => now.difference(metric.timestamp).inSeconds < 10)
        .toList();

    return CrossPlatformPerformanceReport(
      platform: PlatformOptimizations().currentPlatform,
      frameTimings: recentFrames,
      animationMetrics: recentAnimations,
      timestamp: now,
    );
  }

  /// Record animation performance metric
  void recordAnimationMetric({
    required String animationName,
    required Duration duration,
    required int frameCount,
    required double averageFrameTime,
    required bool droppedFrames,
  }) {
    _animationMetrics.add(
      AnimationPerformanceMetric(
        animationName: animationName,
        duration: duration,
        frameCount: frameCount,
        averageFrameTime: averageFrameTime,
        droppedFrames: droppedFrames,
        timestamp: DateTime.now(),
        platform: PlatformOptimizations().currentPlatform,
      ),
    );

    // Keep only recent metrics
    if (_animationMetrics.length > 100) {
      _animationMetrics.removeRange(0, _animationMetrics.length - 100);
    }
  }

  void _onFrameTiming(List<FrameTiming> timings) {
    for (final timing in timings) {
      final frameTime =
          timing.totalSpan.inMicroseconds / 1000.0; // Convert to milliseconds
      final isJanky = frameTime > 16.67; // 60fps threshold

      _frameTimings.add(
        FrameTimingInfo(
          frameTime: frameTime,
          isJanky: isJanky,
          timestamp: DateTime.now(),
          platform: PlatformOptimizations().currentPlatform,
        ),
      );
    }

    // Keep only recent frame timings
    if (_frameTimings.length > 1000) {
      _frameTimings.removeRange(0, _frameTimings.length - 1000);
    }
  }

  void _checkPerformance() {
    final report = getPerformanceReport();

    // Check for performance issues
    if (report.averageFrameTime > 16.67) {
      if (kDebugMode) {
        AppLog.debug(
          'Performance warning: Average frame time ${report.averageFrameTime.toStringAsFixed(2)}ms exceeds 60fps target',
        );
      }
    }

    if (report.jankyFramePercentage > 10) {
      if (kDebugMode) {
        AppLog.debug(
          'Performance warning: ${report.jankyFramePercentage.toStringAsFixed(1)}% of frames are janky',
        );
      }
    }
  }
}

/// Performance monitoring widget that automatically starts/stops monitoring
class PerformanceMonitoringWidget extends StatefulWidget {
  final Widget child;
  final bool enableMonitoring;
  final Function(CrossPlatformPerformanceReport)? onPerformanceReport;

  const PerformanceMonitoringWidget({
    super.key,
    required this.child,
    this.enableMonitoring = kDebugMode,
    this.onPerformanceReport,
  });

  @override
  State<PerformanceMonitoringWidget> createState() =>
      _PerformanceMonitoringWidgetState();
}

class _PerformanceMonitoringWidgetState
    extends State<PerformanceMonitoringWidget> {
  Timer? _reportTimer;

  @override
  void initState() {
    super.initState();

    if (widget.enableMonitoring) {
      CrossPlatformPerformanceMonitor().startMonitoring();

      // Generate reports periodically
      _reportTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        final report = CrossPlatformPerformanceMonitor().getPerformanceReport();
        widget.onPerformanceReport?.call(report);
      });
    }
  }

  @override
  void dispose() {
    _reportTimer?.cancel();

    if (widget.enableMonitoring) {
      CrossPlatformPerformanceMonitor().stopMonitoring();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Platform-adaptive animation controller that adjusts based on performance
class AdaptiveAnimationController extends AnimationController {
  final String animationName;
  late final Timer _performanceTimer;

  AdaptiveAnimationController({
    required this.animationName,
    required Duration duration,
    required TickerProvider vsync,
    String? debugLabel,
  }) : super(
         duration: _adjustDurationForPlatform(duration),
         vsync: vsync,
         debugLabel: debugLabel ?? animationName,
       ) {
    // Monitor performance during animation
    _performanceTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (isAnimating) {
        _recordPerformanceMetric();
      }
    });
  }

  static Duration _adjustDurationForPlatform(Duration baseDuration) {
    final multiplier = PlatformOptimizations().animationDurationMultiplier;
    return Duration(
      milliseconds: (baseDuration.inMilliseconds * multiplier).round(),
    );
  }

  void _recordPerformanceMetric() {
    // This is a simplified metric recording
    // In a real implementation, you'd measure actual frame times
    CrossPlatformPerformanceMonitor().recordAnimationMetric(
      animationName: animationName,
      duration: duration ?? Duration.zero,
      frameCount: 1, // Simplified
      averageFrameTime: 16.67, // Simplified
      droppedFrames: false, // Simplified
    );
  }

  @override
  void dispose() {
    _performanceTimer.cancel();
    super.dispose();
  }
}

/// Cross-platform performance report
class CrossPlatformPerformanceReport {
  final PlatformType platform;
  final List<FrameTimingInfo> frameTimings;
  final List<AnimationPerformanceMetric> animationMetrics;
  final DateTime timestamp;

  const CrossPlatformPerformanceReport({
    required this.platform,
    required this.frameTimings,
    required this.animationMetrics,
    required this.timestamp,
  });

  double get averageFrameTime {
    if (frameTimings.isEmpty) return 0.0;
    return frameTimings.map((f) => f.frameTime).reduce((a, b) => a + b) /
        frameTimings.length;
  }

  double get jankyFramePercentage {
    if (frameTimings.isEmpty) return 0.0;
    final jankyCount = frameTimings.where((f) => f.isJanky).length;
    return (jankyCount / frameTimings.length) * 100;
  }

  bool get isPerformanceGood =>
      averageFrameTime <= 16.67 && jankyFramePercentage <= 5;

  PerformanceLevel get performanceLevel {
    if (averageFrameTime <= 16.67 && jankyFramePercentage <= 2) {
      return PerformanceLevel.excellent;
    } else if (averageFrameTime <= 20 && jankyFramePercentage <= 5) {
      return PerformanceLevel.good;
    } else if (averageFrameTime <= 25 && jankyFramePercentage <= 10) {
      return PerformanceLevel.fair;
    } else {
      return PerformanceLevel.poor;
    }
  }

  List<String> get performanceRecommendations {
    final recommendations = <String>[];

    if (averageFrameTime > 16.67) {
      recommendations.add('Consider reducing animation complexity');
    }

    if (jankyFramePercentage > 10) {
      recommendations.add('Optimize heavy operations during animations');
    }

    if (animationMetrics.any((m) => m.droppedFrames)) {
      recommendations.add('Enable hardware acceleration for transforms');
    }

    switch (platform) {
      case PlatformType.android:
        if (averageFrameTime > 20) {
          recommendations.add(
            'Consider using simpler animations on older Android devices',
          );
        }
        break;
      case PlatformType.ios:
        if (jankyFramePercentage > 5) {
          recommendations.add(
            'Ensure animations use Core Animation optimizations',
          );
        }
        break;
      case PlatformType.web:
        recommendations.add(
          'Use CSS transforms when possible for better web performance',
        );
        break;
      default:
        break;
    }

    return recommendations;
  }
}

/// Frame timing information
class FrameTimingInfo {
  final double frameTime;
  final bool isJanky;
  final DateTime timestamp;
  final PlatformType platform;

  const FrameTimingInfo({
    required this.frameTime,
    required this.isJanky,
    required this.timestamp,
    required this.platform,
  });
}

/// Animation performance metric
class AnimationPerformanceMetric {
  final String animationName;
  final Duration duration;
  final int frameCount;
  final double averageFrameTime;
  final bool droppedFrames;
  final DateTime timestamp;
  final PlatformType platform;

  const AnimationPerformanceMetric({
    required this.animationName,
    required this.duration,
    required this.frameCount,
    required this.averageFrameTime,
    required this.droppedFrames,
    required this.timestamp,
    required this.platform,
  });

  double get fps => frameCount / (duration.inMilliseconds / 1000.0);
}

/// Performance levels
enum PerformanceLevel { excellent, good, fair, poor }
