import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/adaptive_performance.dart';
import 'package:omnisonic/core/design_system/animation_manager.dart';

void main() {
  group('Performance Optimization', () {
    test('AdaptivePerformanceManager should initialize with default settings', () {
      final manager = AdaptivePerformanceManager();
      
      expect(manager.currentPerformanceLevel, DevicePerformanceLevel.high);
      expect(manager.batteryOptimizationLevel, BatteryOptimizationLevel.none);
      expect(manager.thermalState, ThermalState.normal);
      expect(manager.averageFrameRate, 60.0);
      expect(manager.isLowPowerModeEnabled, false);
    });
    
    test('AdaptivePerformanceManager should provide animation configuration', () {
      final manager = AdaptivePerformanceManager();
      final config = manager.getAnimationConfig();
      
      expect(config.enableMicroInteractions, true);
      expect(config.enablePageTransitions, true);
      expect(config.enableLoadingAnimations, true);
      expect(config.animationQuality, AnimationQuality.high);
    });
    
    test('AdaptivePerformanceManager should adjust multipliers based on performance', () {
      final manager = AdaptivePerformanceManager();
      
      // High performance should have full multipliers
      expect(manager.animationComplexityMultiplier, 1.0);
      expect(manager.animationDurationMultiplier, 1.0);
      expect(manager.maxConcurrentAnimations, 4);
    });
    
    test('AdaptivePerformanceManager should handle frame drops', () {
      final manager = AdaptivePerformanceManager();
      
      // Simulate frame drops
      manager.reportFrameDrop();
      manager.reportFrameDrop();
      manager.reportFrameDrop();
      
      // Performance should still be manageable with few drops
      expect(manager.currentPerformanceLevel, DevicePerformanceLevel.high);
    });
    
    test('AdaptivePerformanceManager should report frame rate', () {
      final manager = AdaptivePerformanceManager();
      
      // Report good frame rate
      manager.reportFrameRate(60.0);
      expect(manager.averageFrameRate, closeTo(60.0, 0.1));
      
      // Report poor frame rate
      manager.reportFrameRate(30.0);
      expect(manager.averageFrameRate, lessThan(60.0));
    });
    
    test('AnimationPriority enum should have correct values', () {
      expect(AnimationPriority.values.length, 4);
      expect(AnimationPriority.low.index, 0);
      expect(AnimationPriority.normal.index, 1);
      expect(AnimationPriority.high.index, 2);
      expect(AnimationPriority.critical.index, 3);
    });
    
    test('AdaptiveAnimationConfig should create correct configurations', () {
      final lowConfig = AdaptiveAnimationConfig.lowPerformance();
      expect(lowConfig.enableMicroInteractions, false);
      expect(lowConfig.enableComplexAnimations, false);
      expect(lowConfig.maxAnimationLayers, 1);
      expect(lowConfig.animationQuality, AnimationQuality.low);
      
      final highConfig = AdaptiveAnimationConfig.highPerformance();
      expect(highConfig.enableMicroInteractions, true);
      expect(highConfig.enableComplexAnimations, true);
      expect(highConfig.maxAnimationLayers, 4);
      expect(highConfig.animationQuality, AnimationQuality.high);
    });
  });
}