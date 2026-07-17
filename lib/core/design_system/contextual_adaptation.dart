import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Contextual UI adaptation system that detects usage context and adapts
/// the interface for optimal usability in different scenarios
class ContextualAdaptationManager {
  static final ContextualAdaptationManager _instance =
      ContextualAdaptationManager._internal();
  factory ContextualAdaptationManager() => _instance;
  ContextualAdaptationManager._internal();

  // Current context state
  UsageContext _currentContext = UsageContext.stationary;
  AmbientLightLevel _ambientLightLevel = AmbientLightLevel.normal;
  DeviceCharacteristics _deviceCharacteristics = const DeviceCharacteristics();

  // Monitoring timers
  Timer? _contextMonitorTimer;
  Timer? _lightSensorTimer;

  // Callbacks
  final List<VoidCallback> _contextChangeCallbacks = [];
  final List<VoidCallback> _lightLevelChangeCallbacks = [];

  // Context detection state
  double _lastAccelerometerReading = 0.0;
  int _stationaryCount = 0;
  int _movementCount = 0;
  bool _isInitialized = false;

  /// Initialize the contextual adaptation manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _detectDeviceCharacteristics();
    await _initializeContextDetection();
    await _initializeAmbientLightDetection();

    _isInitialized = true;
    developer.log(
      'Contextual adaptation initialized',
      name: 'ContextualAdaptation',
    );
  }

  /// Get current usage context
  UsageContext get currentContext => _currentContext;

  /// Get current ambient light level
  AmbientLightLevel get ambientLightLevel => _ambientLightLevel;

  /// Get device characteristics
  DeviceCharacteristics get deviceCharacteristics => _deviceCharacteristics;

  /// Get adaptive UI configuration based on current context
  ContextualUIConfig getUIConfig() {
    return ContextualUIConfig(
      context: _currentContext,
      lightLevel: _ambientLightLevel,
      deviceCharacteristics: _deviceCharacteristics,
      touchTargetSize: _getAdaptiveTouchTargetSize(),
      spacing: _getAdaptiveSpacing(),
      fontSize: _getAdaptiveFontSize(),
      contrast: _getAdaptiveContrast(),
      colorIntensity: _getAdaptiveColorIntensity(),
      buttonSize: _getAdaptiveButtonSize(),
      cardElevation: _getAdaptiveCardElevation(),
      animationSpeed: _getAdaptiveAnimationSpeed(),
    );
  }

  /// Add callback for context changes
  void addContextChangeCallback(VoidCallback callback) {
    _contextChangeCallbacks.add(callback);
  }

  /// Remove callback for context changes
  void removeContextChangeCallback(VoidCallback callback) {
    _contextChangeCallbacks.remove(callback);
  }

  /// Add callback for light level changes
  void addLightLevelChangeCallback(VoidCallback callback) {
    _lightLevelChangeCallbacks.add(callback);
  }

  /// Remove callback for light level changes
  void removeLightLevelChangeCallback(VoidCallback callback) {
    _lightLevelChangeCallbacks.remove(callback);
  }

  /// Manually set usage context (for testing or user override)
  void setUsageContext(UsageContext context) {
    if (_currentContext != context) {
      final oldContext = _currentContext;
      _currentContext = context;
      developer.log(
        'Usage context changed: ${oldContext.name} -> ${context.name}',
        name: 'ContextualAdaptation',
      );
      _notifyContextChange();
    }
  }

  /// Manually set ambient light level (for testing or user override)
  void setAmbientLightLevel(AmbientLightLevel level) {
    if (_ambientLightLevel != level) {
      final oldLevel = _ambientLightLevel;
      _ambientLightLevel = level;
      developer.log(
        'Ambient light level changed: ${oldLevel.name} -> ${level.name}',
        name: 'ContextualAdaptation',
      );
      _notifyLightLevelChange();
    }
  }

  /// Dispose the contextual adaptation manager
  void dispose() {
    _contextMonitorTimer?.cancel();
    _lightSensorTimer?.cancel();
    _contextChangeCallbacks.clear();
    _lightLevelChangeCallbacks.clear();
    _isInitialized = false;
  }

  // Private methods

  Future<void> _detectDeviceCharacteristics() async {
    try {
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final size = view.physicalSize / view.devicePixelRatio;
      final pixelRatio = view.devicePixelRatio;

      // Determine device type based on screen size
      DeviceType deviceType;
      if (kIsWeb) {
        deviceType = size.width > 768 ? DeviceType.desktop : DeviceType.mobile;
      } else if (Platform.isIOS || Platform.isAndroid) {
        deviceType = size.shortestSide > 600
            ? DeviceType.tablet
            : DeviceType.mobile;
      } else {
        deviceType = DeviceType.desktop;
      }

      // Determine screen density category
      ScreenDensity screenDensity;
      if (pixelRatio <= 1.5) {
        screenDensity = ScreenDensity.low;
      } else if (pixelRatio <= 2.5) {
        screenDensity = ScreenDensity.medium;
      } else {
        screenDensity = ScreenDensity.high;
      }

      _deviceCharacteristics = DeviceCharacteristics(
        deviceType: deviceType,
        screenSize: size,
        pixelRatio: pixelRatio,
        screenDensity: screenDensity,
        hasPhysicalKeyboard: deviceType == DeviceType.desktop,
        supportsTouchInput: deviceType != DeviceType.desktop,
        supportsHover: deviceType == DeviceType.desktop,
        hasAmbientLightSensor: Platform.isIOS || Platform.isAndroid,
        hasAccelerometer: Platform.isIOS || Platform.isAndroid,
      );

      developer.log(
        'Device characteristics detected: ${_deviceCharacteristics.deviceType.name}, ${size.width}x${size.height}, ${pixelRatio}x',
        name: 'ContextualAdaptation',
      );
    } catch (e) {
      developer.log(
        'Error detecting device characteristics: $e',
        name: 'ContextualAdaptation',
      );
      _deviceCharacteristics = const DeviceCharacteristics(); // Use defaults
    }
  }

  Future<void> _initializeContextDetection() async {
    if (!_deviceCharacteristics.hasAccelerometer) {
      developer.log(
        'Accelerometer not available, using stationary context',
        name: 'ContextualAdaptation',
      );
      return;
    }

    try {
      // Start context monitoring
      _contextMonitorTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _updateUsageContext(),
      );

      // Simulate accelerometer readings for demo purposes
      // In a real implementation, this would use actual sensor data
      _simulateAccelerometerData();
    } catch (e) {
      developer.log(
        'Error initializing context detection: $e',
        name: 'ContextualAdaptation',
      );
    }
  }

  void _simulateAccelerometerData() {
    // Simulate different movement patterns for demo
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isInitialized) {
        timer.cancel();
        return;
      }

      // Generate simulated accelerometer data
      final random = math.Random();
      final baseMovement = random.nextDouble() * 0.5;

      // Add some variation to simulate different contexts
      final now = DateTime.now();
      final timeOfDay = now.hour;

      double movement;
      if (timeOfDay >= 7 && timeOfDay <= 9) {
        // Morning commute - more movement
        movement = baseMovement + random.nextDouble() * 2.0;
      } else if (timeOfDay >= 17 && timeOfDay <= 19) {
        // Evening commute - more movement
        movement = baseMovement + random.nextDouble() * 1.5;
      } else {
        // Regular day - less movement
        movement = baseMovement + random.nextDouble() * 0.3;
      }

      _lastAccelerometerReading = movement;
    });
  }

  void _updateUsageContext() {
    try {
      // Analyze accelerometer data to determine context
      if (_lastAccelerometerReading < 0.2) {
        _stationaryCount++;
        _movementCount = 0;
      } else if (_lastAccelerometerReading < 1.0) {
        _movementCount++;
        _stationaryCount = 0;
      } else {
        _movementCount += 2; // Higher movement gets more weight
        _stationaryCount = 0;
      }

      // Determine context based on movement patterns
      UsageContext newContext;
      if (_stationaryCount >= 3) {
        newContext = UsageContext.stationary;
      } else if (_movementCount >= 2 && _lastAccelerometerReading < 1.0) {
        newContext = UsageContext.walking;
      } else if (_movementCount >= 1 && _lastAccelerometerReading >= 1.0) {
        newContext = UsageContext.driving;
      } else {
        newContext = _currentContext; // Keep current context
      }

      if (newContext != _currentContext) {
        _currentContext = newContext;
        developer.log(
          'Usage context updated: ${newContext.name} (movement: ${_lastAccelerometerReading.toStringAsFixed(2)})',
          name: 'ContextualAdaptation',
        );
        _notifyContextChange();
      }
    } catch (e) {
      developer.log(
        'Error updating usage context: $e',
        name: 'ContextualAdaptation',
      );
    }
  }

  Future<void> _initializeAmbientLightDetection() async {
    if (!_deviceCharacteristics.hasAmbientLightSensor) {
      developer.log(
        'Ambient light sensor not available, using normal light level',
        name: 'ContextualAdaptation',
      );
      return;
    }

    try {
      // Start light level monitoring
      _lightSensorTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _updateAmbientLightLevel(),
      );

      // Simulate light sensor readings for demo purposes
      _simulateLightSensorData();
    } catch (e) {
      developer.log(
        'Error initializing ambient light detection: $e',
        name: 'ContextualAdaptation',
      );
    }
  }

  void _simulateLightSensorData() {
    // Simulate light level changes based on time of day
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isInitialized) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final hour = now.hour;

      AmbientLightLevel newLevel;
      if (hour >= 6 && hour <= 8) {
        newLevel = AmbientLightLevel.dim; // Dawn
      } else if (hour >= 9 && hour <= 17) {
        newLevel = AmbientLightLevel.bright; // Daytime
      } else if (hour >= 18 && hour <= 20) {
        newLevel = AmbientLightLevel.normal; // Dusk
      } else {
        newLevel = AmbientLightLevel.dark; // Night
      }

      if (newLevel != _ambientLightLevel) {
        _ambientLightLevel = newLevel;
        developer.log(
          'Ambient light level updated: ${newLevel.name}',
          name: 'ContextualAdaptation',
        );
        _notifyLightLevelChange();
      }
    });
  }

  void _updateAmbientLightLevel() {
    // This would typically read from actual light sensor
    // For now, the simulation handles this
  }

  void _notifyContextChange() {
    for (final callback in _contextChangeCallbacks) {
      try {
        callback();
      } catch (e) {
        developer.log(
          'Error in context change callback: $e',
          name: 'ContextualAdaptation',
        );
      }
    }
  }

  void _notifyLightLevelChange() {
    for (final callback in _lightLevelChangeCallbacks) {
      try {
        callback();
      } catch (e) {
        developer.log(
          'Error in light level change callback: $e',
          name: 'ContextualAdaptation',
        );
      }
    }
  }

  // Adaptive UI calculations

  double _getAdaptiveTouchTargetSize() {
    double baseSize = 44.0; // WCAG minimum

    switch (_currentContext) {
      case UsageContext.driving:
        baseSize *= 1.5; // Larger targets for driving
        break;
      case UsageContext.walking:
        baseSize *= 1.2; // Slightly larger for walking
        break;
      case UsageContext.stationary:
        baseSize *= 1.0; // Standard size
        break;
    }

    // Adjust for device characteristics
    if (_deviceCharacteristics.deviceType == DeviceType.tablet) {
      baseSize *= 1.1;
    }

    return baseSize;
  }

  EdgeInsets _getAdaptiveSpacing() {
    double baseSpacing = 16.0;

    switch (_currentContext) {
      case UsageContext.driving:
        baseSpacing *= 1.5; // More spacing for driving
        break;
      case UsageContext.walking:
        baseSpacing *= 1.2; // Slightly more spacing
        break;
      case UsageContext.stationary:
        baseSpacing *= 1.0; // Standard spacing
        break;
    }

    // Adjust for screen density
    switch (_deviceCharacteristics.screenDensity) {
      case ScreenDensity.low:
        baseSpacing *= 0.8;
        break;
      case ScreenDensity.medium:
        baseSpacing *= 1.0;
        break;
      case ScreenDensity.high:
        baseSpacing *= 1.2;
        break;
    }

    return EdgeInsets.all(baseSpacing);
  }

  double _getAdaptiveFontSize() {
    double multiplier = 1.0;

    switch (_currentContext) {
      case UsageContext.driving:
        multiplier = 1.3; // Larger text for driving
        break;
      case UsageContext.walking:
        multiplier = 1.1; // Slightly larger text
        break;
      case UsageContext.stationary:
        multiplier = 1.0; // Standard text
        break;
    }

    // Adjust for ambient light
    switch (_ambientLightLevel) {
      case AmbientLightLevel.dark:
        multiplier *= 1.1; // Slightly larger in dark
        break;
      case AmbientLightLevel.dim:
        multiplier *= 1.05;
        break;
      case AmbientLightLevel.normal:
        multiplier *= 1.0;
        break;
      case AmbientLightLevel.bright:
        multiplier *= 0.95; // Slightly smaller in bright light
        break;
    }

    return multiplier;
  }

  double _getAdaptiveContrast() {
    double contrast = 1.0;

    switch (_ambientLightLevel) {
      case AmbientLightLevel.dark:
        contrast = 0.8; // Lower contrast in dark
        break;
      case AmbientLightLevel.dim:
        contrast = 0.9;
        break;
      case AmbientLightLevel.normal:
        contrast = 1.0;
        break;
      case AmbientLightLevel.bright:
        contrast = 1.2; // Higher contrast in bright light
        break;
    }

    // Increase contrast for movement contexts
    if (_currentContext != UsageContext.stationary) {
      contrast *= 1.1;
    }

    return contrast;
  }

  double _getAdaptiveColorIntensity() {
    double intensity = 1.0;

    switch (_ambientLightLevel) {
      case AmbientLightLevel.dark:
        intensity = 0.7; // Dimmer colors in dark
        break;
      case AmbientLightLevel.dim:
        intensity = 0.85;
        break;
      case AmbientLightLevel.normal:
        intensity = 1.0;
        break;
      case AmbientLightLevel.bright:
        intensity = 1.15; // More vibrant colors in bright light
        break;
    }

    return intensity;
  }

  double _getAdaptiveButtonSize() {
    return _getAdaptiveTouchTargetSize();
  }

  double _getAdaptiveCardElevation() {
    double elevation = 4.0;

    switch (_ambientLightLevel) {
      case AmbientLightLevel.dark:
        elevation = 2.0; // Less elevation in dark
        break;
      case AmbientLightLevel.dim:
        elevation = 3.0;
        break;
      case AmbientLightLevel.normal:
        elevation = 4.0;
        break;
      case AmbientLightLevel.bright:
        elevation = 6.0; // More elevation in bright light
        break;
    }

    return elevation;
  }

  double _getAdaptiveAnimationSpeed() {
    double speed = 1.0;

    switch (_currentContext) {
      case UsageContext.driving:
        speed = 0.7; // Slower animations for driving
        break;
      case UsageContext.walking:
        speed = 0.85; // Slightly slower animations
        break;
      case UsageContext.stationary:
        speed = 1.0; // Normal speed
        break;
    }

    return speed;
  }
}

/// Usage context enumeration
enum UsageContext { stationary, walking, driving }

/// Ambient light level enumeration
enum AmbientLightLevel { dark, dim, normal, bright }

/// Device type enumeration
enum DeviceType { mobile, tablet, desktop }

/// Screen density enumeration
enum ScreenDensity { low, medium, high }

/// Device characteristics data class
class DeviceCharacteristics {
  final DeviceType deviceType;
  final Size screenSize;
  final double pixelRatio;
  final ScreenDensity screenDensity;
  final bool hasPhysicalKeyboard;
  final bool supportsTouchInput;
  final bool supportsHover;
  final bool hasAmbientLightSensor;
  final bool hasAccelerometer;

  const DeviceCharacteristics({
    this.deviceType = DeviceType.mobile,
    this.screenSize = const Size(375, 667), // iPhone default
    this.pixelRatio = 2.0,
    this.screenDensity = ScreenDensity.medium,
    this.hasPhysicalKeyboard = false,
    this.supportsTouchInput = true,
    this.supportsHover = false,
    this.hasAmbientLightSensor = false,
    this.hasAccelerometer = false,
  });

  @override
  String toString() {
    return 'DeviceCharacteristics('
        'type: ${deviceType.name}, '
        'size: ${screenSize.width}x${screenSize.height}, '
        'pixelRatio: $pixelRatio, '
        'density: ${screenDensity.name})';
  }
}

/// Contextual UI configuration
class ContextualUIConfig {
  final UsageContext context;
  final AmbientLightLevel lightLevel;
  final DeviceCharacteristics deviceCharacteristics;
  final double touchTargetSize;
  final EdgeInsets spacing;
  final double fontSize;
  final double contrast;
  final double colorIntensity;
  final double buttonSize;
  final double cardElevation;
  final double animationSpeed;

  const ContextualUIConfig({
    required this.context,
    required this.lightLevel,
    required this.deviceCharacteristics,
    required this.touchTargetSize,
    required this.spacing,
    required this.fontSize,
    required this.contrast,
    required this.colorIntensity,
    required this.buttonSize,
    required this.cardElevation,
    required this.animationSpeed,
  });

  @override
  String toString() {
    return 'ContextualUIConfig('
        'context: ${context.name}, '
        'light: ${lightLevel.name}, '
        'touchTarget: $touchTargetSize, '
        'fontSize: $fontSize, '
        'contrast: $contrast)';
  }
}

/// Widget that adapts its UI based on contextual information
class ContextualAdaptationBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, ContextualUIConfig config)
  builder;

  const ContextualAdaptationBuilder({super.key, required this.builder});

  @override
  State<ContextualAdaptationBuilder> createState() =>
      _ContextualAdaptationBuilderState();
}

class _ContextualAdaptationBuilderState
    extends State<ContextualAdaptationBuilder> {
  late ContextualUIConfig _config;

  @override
  void initState() {
    super.initState();
    _config = ContextualAdaptationManager().getUIConfig();

    // Listen for context changes
    ContextualAdaptationManager().addContextChangeCallback(_updateConfig);
    ContextualAdaptationManager().addLightLevelChangeCallback(_updateConfig);
  }

  @override
  void dispose() {
    ContextualAdaptationManager().removeContextChangeCallback(_updateConfig);
    ContextualAdaptationManager().removeLightLevelChangeCallback(_updateConfig);
    super.dispose();
  }

  void _updateConfig() {
    if (mounted) {
      setState(() {
        _config = ContextualAdaptationManager().getUIConfig();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _config);
  }
}
