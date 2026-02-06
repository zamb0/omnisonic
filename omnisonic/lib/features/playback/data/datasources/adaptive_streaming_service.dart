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
  AudioQuality _currentRecommendedQuality = AudioQuality.ultra; // Start with best quality
  double _estimatedBandwidth = 100.0; // Mbps - Optimistic default
  int _bufferHealth = 100; // Percentage
  bool _isBuffering = false;

  // Adaptive streaming configuration
  static const Duration _bandwidthTestInterval = Duration(seconds: 30); // Currently unused
  static const Duration _bufferMonitorInterval = Duration(seconds: 5);
  static const int _minBufferHealthPercent = 10;  // More lenient - was 20
  static const int _goodBufferHealthPercent = 40; // More lenient - was 60

  void _init() {
    // Monitor connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results);
    });

    // Start periodic bandwidth estimation - DISABLED: produces inaccurate results
    // The fake latency-based estimation doesn't reflect actual throughput
    // _startBandwidthMonitoring();

    // Start buffer health monitoring
    _startBufferMonitoring();
  }

  /// Handles connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      _estimatedBandwidth = 0.0;
      _updateNetworkCondition(NetworkCondition.offline);
      print('🌐 Connection lost - offline mode');
      return;
    }

    // Log connection type but remain optimistic - start with best quality
    // Only downgrade if we encounter actual buffering issues
    if (results.contains(ConnectivityResult.ethernet)) {
      _estimatedBandwidth = 1000.0;
      print('🌐 Connected via Ethernet');
    } else if (results.contains(ConnectivityResult.wifi)) {
      _estimatedBandwidth = 100.0;
      print('🌐 Connected via WiFi');
    } else if (results.contains(ConnectivityResult.mobile)) {
      _estimatedBandwidth = 10.0;
      print('🌐 Connected via Mobile');
    } else {
      _estimatedBandwidth = 5.0;
      print('🌐 Connected via unknown type');
    }
    
    // Always stay at excellent condition - let buffering drive quality adjustments
    _updateNetworkCondition(NetworkCondition.excellent);
  }

  /// Starts buffer health monitoring
  void _startBufferMonitoring() {
    _bufferMonitorTimer = Timer.periodic(_bufferMonitorInterval, (_) {
      _checkBufferHealth();
    });
  }

  /// Updates the current network condition
  void _updateNetworkCondition(NetworkCondition condition) {
    if (_currentCondition != condition) {
      _currentCondition = condition;
      _networkConditionController.add(condition);
      _updateRecommendedQuality();
    }
  }

  /// Updates recommended audio quality based on network condition
  void _updateRecommendedQuality() {
    // Only handle offline state - otherwise maintain current quality
    // Quality changes are driven by actual buffering events, not predictions
    if (_currentCondition == NetworkCondition.offline) {
      // Offline - don't stream, use cached content only
      return;
    }
    
    // Note: Quality is now adjusted reactively in _checkBufferHealth()
    // based on actual buffering, not predicted network conditions
  }

  /// Checks buffer health and reacts to actual buffering issues
  void _checkBufferHealth() {
    if (_isBuffering) {
      // Actually buffering - this is a real problem, downgrade quality
      _bufferHealth = max(0, _bufferHealth - 15);  // Faster response to problems
      
      if (_bufferHealth < _minBufferHealthPercent) {
        // Immediate downgrade on buffering
        _downgradeQuality();
      }
    } else {
      // Streaming smoothly - gradually recover buffer health
      _bufferHealth = min(100, _bufferHealth + 5);
      
      // If we've been streaming smoothly for a while, try upgrading
      if (_bufferHealth >= _goodBufferHealthPercent && 
          _currentRecommendedQuality != AudioQuality.ultra) {
        _upgradeQuality();
      }
    }
  }

  /// Reports buffering status from the audio player
  void reportBufferingStatus(bool isBuffering) {
    if (isBuffering && !_isBuffering) {
      print('⚠️  Buffering detected - may need to reduce quality');
    }
    _isBuffering = isBuffering;
  }
  
  /// Downgrade quality by one step due to buffering
  void _downgradeQuality() {
    final qualities = AudioQuality.values;
    final currentIndex = qualities.indexOf(_currentRecommendedQuality);
    
    if (currentIndex > 0) {
      final newQuality = qualities[currentIndex - 1];
      print('⬇️  Quality downgrade: ${_currentRecommendedQuality.name} → ${newQuality.name} (due to buffering)');
      _currentRecommendedQuality = newQuality;
      _recommendedQualityController.add(newQuality);
    }
  }
  
  /// Upgrade quality by one step when streaming is smooth
  void _upgradeQuality() {
    final qualities = AudioQuality.values;
    final currentIndex = qualities.indexOf(_currentRecommendedQuality);
    
    if (currentIndex < qualities.length - 1) {
      final newQuality = qualities[currentIndex + 1];
      print('⬆️  Quality upgrade: ${_currentRecommendedQuality.name} → ${newQuality.name} (smooth streaming)');
      _currentRecommendedQuality = newQuality;
      _recommendedQualityController.add(newQuality);
    }
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