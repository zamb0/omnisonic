import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/failures.dart';

/// Service that manages adaptive streaming based on network conditions
class AdaptiveStreamingService {
  AdaptiveStreamingService() {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  final BehaviorSubject<NetworkCondition> _networkConditionController = 
      BehaviorSubject<NetworkCondition>.seeded(NetworkCondition.excellent);
  final BehaviorSubject<AudioQuality> _recommendedQualityController = 
      BehaviorSubject<AudioQuality>.seeded(AudioQuality.lossless);

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  Timer? _bandwidthTestTimer;
  Timer? _bufferMonitorTimer;

  // Network monitoring state
  NetworkCondition _currentCondition = NetworkCondition.excellent;
  AudioQuality _currentRecommendedQuality = AudioQuality.lossless;
  double _estimatedBandwidth = 0.0; // Mbps
  int _bufferHealth = 100; // Percentage
  bool _isBuffering = false;

  // Adaptive streaming configuration
  static const Duration _bandwidthTestInterval = Duration(seconds: 30);
  static const Duration _bufferMonitorInterval = Duration(seconds: 5);
  static const int _minBufferHealthPercent = 10;  // More lenient - was 20
  static const int _goodBufferHealthPercent = 40; // More lenient - was 60

  void _init() {
    // Monitor connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results);
    });

    // Start periodic bandwidth estimation
    _startBandwidthMonitoring();

    // Start buffer health monitoring
    _startBufferMonitoring();
  }

  /// Handles connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      _updateNetworkCondition(NetworkCondition.offline);
      return;
    }

    // Determine connection type and update condition accordingly
    if (results.contains(ConnectivityResult.wifi)) {
      _updateNetworkCondition(NetworkCondition.excellent);
    } else if (results.contains(ConnectivityResult.mobile)) {
      // For mobile, we need to estimate the actual speed
      _updateNetworkCondition(NetworkCondition.good);
      _estimateMobileBandwidth();
    } else if (results.contains(ConnectivityResult.ethernet)) {
      _updateNetworkCondition(NetworkCondition.excellent);
    } else {
      _updateNetworkCondition(NetworkCondition.poor);
    }
  }

  /// Starts bandwidth monitoring
  void _startBandwidthMonitoring() {
    _bandwidthTestTimer = Timer.periodic(_bandwidthTestInterval, (_) {
      _performBandwidthTest();
    });
  }

  /// Starts buffer health monitoring
  void _startBufferMonitoring() {
    _bufferMonitorTimer = Timer.periodic(_bufferMonitorInterval, (_) {
      _checkBufferHealth();
    });
  }

  /// Performs a lightweight bandwidth test
  Future<void> _performBandwidthTest() async {
    try {
      // This is a simplified bandwidth test
      // In a real implementation, you might download a small test file
      // or measure actual streaming performance
      final startTime = DateTime.now();
      
      // Simulate a small network request to estimate bandwidth
      // This would be replaced with actual network measurement
      await Future.delayed(Duration(milliseconds: 100 + Random().nextInt(200)));
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      // Estimate bandwidth based on connection type and response time
      _estimatedBandwidth = _calculateBandwidthFromLatency(duration.inMilliseconds);
      
      _updateNetworkConditionFromBandwidth();
    } catch (e) {
      // If bandwidth test fails, assume poor conditions
      _updateNetworkCondition(NetworkCondition.poor);
    }
  }

  /// Estimates mobile bandwidth based on connection type
  void _estimateMobileBandwidth() {
    // This is a simplified estimation
    // In a real app, you might use more sophisticated methods
    _estimatedBandwidth = 5.0; // Assume 5 Mbps for mobile
    _updateNetworkConditionFromBandwidth();
  }

  /// Calculates estimated bandwidth from latency
  double _calculateBandwidthFromLatency(int latencyMs) {
    // Simple heuristic: lower latency generally means better connection
    if (latencyMs < 50) {
      return 50.0; // Excellent connection
    } else if (latencyMs < 100) {
      return 25.0; // Good connection
    } else if (latencyMs < 200) {
      return 10.0; // Fair connection
    } else if (latencyMs < 500) {
      return 5.0; // Poor connection
    } else {
      return 1.0; // Very poor connection
    }
  }

  /// Updates network condition based on estimated bandwidth
  void _updateNetworkConditionFromBandwidth() {
    NetworkCondition newCondition;
    
    if (_estimatedBandwidth >= 25.0) {
      newCondition = NetworkCondition.excellent;
    } else if (_estimatedBandwidth >= 10.0) {
      newCondition = NetworkCondition.good;
    } else if (_estimatedBandwidth >= 2.0) {
      newCondition = NetworkCondition.fair;
    } else if (_estimatedBandwidth >= 0.5) {
      newCondition = NetworkCondition.poor;
    } else {
      newCondition = NetworkCondition.offline;
    }
    
    _updateNetworkCondition(newCondition);
  }

  /// Updates the current network condition
  void _updateNetworkCondition(NetworkCondition condition) {
    if (_currentCondition != condition) {
      _currentCondition = condition;
      _networkConditionController.add(condition);
      _updateRecommendedQuality();
    }
  }

  /// Updates recommended audio quality based on network condition and buffer health
  void _updateRecommendedQuality() {
    AudioQuality newQuality;
    
    // Base quality on network condition - start higher
    switch (_currentCondition) {
      case NetworkCondition.excellent:
        newQuality = AudioQuality.lossless;
        break;
      case NetworkCondition.good:
        newQuality = AudioQuality.high;  // Keep high quality on good connections
        break;
      case NetworkCondition.fair:
        newQuality = AudioQuality.high;  // Still use high on fair - was medium
        break;
      case NetworkCondition.poor:
        newQuality = AudioQuality.medium; // Use medium on poor - was low
        break;
      case NetworkCondition.offline:
        // Don't change quality when offline - use cached content
        return;
    }
    
    // Only adjust based on buffer health if it's critically low
    if (_bufferHealth < _minBufferHealthPercent) {
      // Buffer is critically low, reduce quality by 1 step only
      newQuality = _reduceQuality(newQuality, 1);
    }
    
    // Don't change quality too frequently to avoid jarring transitions
    if (_shouldUpdateQuality(newQuality)) {
      _currentRecommendedQuality = newQuality;
      _recommendedQualityController.add(newQuality);
    }
  }

  /// Reduces audio quality by the specified number of steps
  AudioQuality _reduceQuality(AudioQuality quality, int steps) {
    final qualities = AudioQuality.values;
    final currentIndex = qualities.indexOf(quality);
    final newIndex = (currentIndex - steps).clamp(0, qualities.length - 1);
    return qualities[newIndex];
  }

  /// Determines if quality should be updated to avoid frequent changes
  bool _shouldUpdateQuality(AudioQuality newQuality) {
    // Only update if the quality change is significant or buffer is critical
    final currentIndex = AudioQuality.values.indexOf(_currentRecommendedQuality);
    final newIndex = AudioQuality.values.indexOf(newQuality);
    final qualityDifference = (currentIndex - newIndex).abs();
    
    // Require at least 2 steps difference to change quality, unless buffer is critical
    return qualityDifference >= 2 || _bufferHealth < _minBufferHealthPercent;
  }

  /// Checks buffer health (this would integrate with the actual audio player)
  void _checkBufferHealth() {
    // This is a placeholder implementation
    // In a real app, this would check the actual buffer status from the audio player
    
    if (_isBuffering) {
      _bufferHealth = max(0, _bufferHealth - 5);  // Slower degradation - was 10
    } else {
      _bufferHealth = min(100, _bufferHealth + 10); // Faster recovery - was 5
    }
    
    // Update quality if buffer health changed significantly
    if (_bufferHealth < _minBufferHealthPercent || 
        (_bufferHealth > _goodBufferHealthPercent && _currentRecommendedQuality != AudioQuality.lossless)) {
      _updateRecommendedQuality();
    }
  }

  /// Reports buffering status from the audio player
  void reportBufferingStatus(bool isBuffering) {
    _isBuffering = isBuffering;
  }

  /// Reports actual buffer level from the audio player
  void reportBufferLevel(int bufferPercentage) {
    _bufferHealth = bufferPercentage.clamp(0, 100);
  }

  /// Gets the current network condition
  NetworkCondition get currentNetworkCondition => _currentCondition;

  /// Gets the current recommended quality
  AudioQuality get currentRecommendedQuality => _currentRecommendedQuality;

  /// Gets the estimated bandwidth in Mbps
  double get estimatedBandwidth => _estimatedBandwidth;

  /// Observes network condition changes
  Stream<NetworkCondition> observeNetworkCondition() => _networkConditionController.stream;

  /// Observes recommended quality changes
  Stream<AudioQuality> observeRecommendedQuality() => _recommendedQualityController.stream;

  /// Gets the optimal quality for a given track and current conditions
  Future<Result<AudioQuality>> getOptimalQuality(Track track) async {
    try {
      // Consider track's available quality
      AudioQuality optimalQuality = _currentRecommendedQuality;
      
      // Don't recommend higher quality than what the track supports
      if (track.quality.qualityScore < optimalQuality.qualityScore) {
        optimalQuality = track.quality;
      }
      
      // For cached tracks, always use the cached quality
      if (track.isCached) {
        optimalQuality = track.quality;
      }
      
      return ResultHelper.success(optimalQuality);
    } catch (e) {
      return ResultHelper.failure(UnknownFailure('Failed to determine optimal quality: $e'));
    }
  }

  /// Gets preloading strategy based on current conditions
  PreloadingStrategy getPreloadingStrategy() {
    switch (_currentCondition) {
      case NetworkCondition.excellent:
        return PreloadingStrategy.aggressive;
      case NetworkCondition.good:
        return PreloadingStrategy.moderate;
      case NetworkCondition.fair:
        return PreloadingStrategy.conservative;
      case NetworkCondition.poor:
        return PreloadingStrategy.minimal;
      case NetworkCondition.offline:
        return PreloadingStrategy.none;
    }
  }

  /// Gets buffering strategy based on current conditions
  BufferingStrategy getBufferingStrategy() {
    switch (_currentCondition) {
      case NetworkCondition.excellent:
        return BufferingStrategy(
          initialBufferMs: 2000,
          maxBufferMs: 30000,
          rebufferMs: 1000,
        );
      case NetworkCondition.good:
        return BufferingStrategy(
          initialBufferMs: 3000,
          maxBufferMs: 20000,
          rebufferMs: 1500,
        );
      case NetworkCondition.fair:
        return BufferingStrategy(
          initialBufferMs: 5000,
          maxBufferMs: 15000,
          rebufferMs: 2000,
        );
      case NetworkCondition.poor:
        return BufferingStrategy(
          initialBufferMs: 8000,
          maxBufferMs: 10000,
          rebufferMs: 3000,
        );
      case NetworkCondition.offline:
        return BufferingStrategy(
          initialBufferMs: 0,
          maxBufferMs: 0,
          rebufferMs: 0,
        );
    }
  }

  /// Disposes of resources
  void dispose() {
    _connectivitySubscription.cancel();
    _bandwidthTestTimer?.cancel();
    _bufferMonitorTimer?.cancel();
    _networkConditionController.close();
    _recommendedQualityController.close();
  }
}

/// Represents different network conditions
enum NetworkCondition {
  excellent,
  good,
  fair,
  poor,
  offline;

  @override
  String toString() {
    switch (this) {
      case NetworkCondition.excellent:
        return 'Excellent';
      case NetworkCondition.good:
        return 'Good';
      case NetworkCondition.fair:
        return 'Fair';
      case NetworkCondition.poor:
        return 'Poor';
      case NetworkCondition.offline:
        return 'Offline';
    }
  }
}

/// Represents different preloading strategies
enum PreloadingStrategy {
  aggressive,
  moderate,
  conservative,
  minimal,
  none;

  @override
  String toString() {
    switch (this) {
      case PreloadingStrategy.aggressive:
        return 'Aggressive';
      case PreloadingStrategy.moderate:
        return 'Moderate';
      case PreloadingStrategy.conservative:
        return 'Conservative';
      case PreloadingStrategy.minimal:
        return 'Minimal';
      case PreloadingStrategy.none:
        return 'None';
    }
  }
}

/// Configuration for buffering strategy
class BufferingStrategy {
  const BufferingStrategy({
    required this.initialBufferMs,
    required this.maxBufferMs,
    required this.rebufferMs,
  });

  final int initialBufferMs;
  final int maxBufferMs;
  final int rebufferMs;

  @override
  String toString() => 'BufferingStrategy(initial: ${initialBufferMs}ms, max: ${maxBufferMs}ms, rebuffer: ${rebufferMs}ms)';
}