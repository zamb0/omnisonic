import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/contextual_adaptation.dart';

void main() {
  group('Contextual UI Adaptation Tests', () {
    late ContextualAdaptationManager manager;
    
    setUp(() {
      manager = ContextualAdaptationManager();
    });
    
    tearDown(() {
      manager.dispose();
    });
    
    group('Property 45: Contextual UI Adaptation', () {
      testWidgets('PROPERTY: UI adapts to different usage contexts', (WidgetTester tester) async {
        await manager.initialize();
        
        // Test all usage contexts
        final contexts = [UsageContext.stationary, UsageContext.walking, UsageContext.driving];
        
        for (final context in contexts) {
          manager.setUsageContext(context);
          final config = manager.getUIConfig();
          
          // Verify context is set correctly
          expect(config.context, equals(context));
          
          // Verify touch target size adapts to context
          switch (context) {
            case UsageContext.driving:
              expect(config.touchTargetSize, greaterThan(44.0 * 1.4)); // Should be larger for driving
              break;
            case UsageContext.walking:
              expect(config.touchTargetSize, greaterThan(44.0 * 1.1)); // Should be larger for walking
              break;
            case UsageContext.stationary:
              expect(config.touchTargetSize, greaterThanOrEqualTo(44.0)); // Should meet WCAG minimum
              break;
          }
          
          // Verify spacing adapts to context
          expect(config.spacing.left, greaterThan(0));
          expect(config.spacing.top, greaterThan(0));
          expect(config.spacing.right, greaterThan(0));
          expect(config.spacing.bottom, greaterThan(0));
          
          // Verify font size adapts to context
          expect(config.fontSize, greaterThan(0.8)); // Should be reasonable
          expect(config.fontSize, lessThan(2.0)); // Should not be excessive
          
          // Verify animation speed adapts to context
          expect(config.animationSpeed, greaterThan(0.5)); // Should not be too slow
          expect(config.animationSpeed, lessThanOrEqualTo(1.0)); // Should not exceed normal speed
        }
      });
      
      testWidgets('PROPERTY: UI adapts to different ambient light levels', (WidgetTester tester) async {
        await manager.initialize();
        
        // Test all ambient light levels
        final lightLevels = [
          AmbientLightLevel.dark,
          AmbientLightLevel.dim,
          AmbientLightLevel.normal,
          AmbientLightLevel.bright
        ];
        
        for (final lightLevel in lightLevels) {
          manager.setAmbientLightLevel(lightLevel);
          final config = manager.getUIConfig();
          
          // Verify light level is set correctly
          expect(config.lightLevel, equals(lightLevel));
          
          // Verify contrast adapts to light level
          expect(config.contrast, greaterThan(0.5)); // Should maintain readability
          expect(config.contrast, lessThan(2.0)); // Should not be excessive
          
          // Verify color intensity adapts to light level
          expect(config.colorIntensity, greaterThan(0.5)); // Should be visible
          expect(config.colorIntensity, lessThan(1.5)); // Should not be overwhelming
          
          // Verify card elevation adapts to light level
          expect(config.cardElevation, greaterThan(0)); // Should have some elevation
          expect(config.cardElevation, lessThan(10)); // Should not be excessive
        }
      });
      
      testWidgets('PROPERTY: Device characteristics are detected correctly', (WidgetTester tester) async {
        await manager.initialize();
        
        final characteristics = manager.deviceCharacteristics;
        
        // Verify device type is valid
        expect([DeviceType.mobile, DeviceType.tablet, DeviceType.desktop], 
               contains(characteristics.deviceType));
        
        // Verify screen size is reasonable
        expect(characteristics.screenSize.width, greaterThan(200)); // Minimum reasonable width
        expect(characteristics.screenSize.height, greaterThan(200)); // Minimum reasonable height
        
        // Verify pixel ratio is reasonable
        expect(characteristics.pixelRatio, greaterThan(0.5)); // Should be reasonable
        expect(characteristics.pixelRatio, lessThan(5.0)); // Should not be excessive
        
        // Verify screen density is valid
        expect([ScreenDensity.low, ScreenDensity.medium, ScreenDensity.high], 
               contains(characteristics.screenDensity));
      });
      
      testWidgets('PROPERTY: Contextual UI config provides consistent values', (WidgetTester tester) async {
        await manager.initialize();
        
        // Test multiple configurations
        for (int i = 0; i < 10; i++) {
          final config = manager.getUIConfig();
          
          // Verify all required properties are present and valid
          expect(config.touchTargetSize, greaterThan(0));
          expect(config.fontSize, greaterThan(0));
          expect(config.contrast, greaterThan(0));
          expect(config.colorIntensity, greaterThan(0));
          expect(config.buttonSize, greaterThan(0));
          expect(config.cardElevation, greaterThanOrEqualTo(0));
          expect(config.animationSpeed, greaterThan(0));
          
          // Verify spacing is valid
          expect(config.spacing.left, greaterThanOrEqualTo(0));
          expect(config.spacing.top, greaterThanOrEqualTo(0));
          expect(config.spacing.right, greaterThanOrEqualTo(0));
          expect(config.spacing.bottom, greaterThanOrEqualTo(0));
        }
      });
      
      testWidgets('PROPERTY: Context changes trigger callbacks', (WidgetTester tester) async {
        await manager.initialize();
        
        bool contextCallbackTriggered = false;
        bool lightCallbackTriggered = false;
        
        manager.addContextChangeCallback(() {
          contextCallbackTriggered = true;
        });
        
        manager.addLightLevelChangeCallback(() {
          lightCallbackTriggered = true;
        });
        
        // Get initial context to ensure we're changing to something different
        final initialContext = manager.currentContext;
        final newContext = initialContext == UsageContext.driving 
            ? UsageContext.walking 
            : UsageContext.driving;
        
        // Change context and verify callback
        manager.setUsageContext(newContext);
        expect(contextCallbackTriggered, isTrue);
        
        // Get initial light level to ensure we're changing to something different
        final initialLight = manager.ambientLightLevel;
        final newLight = initialLight == AmbientLightLevel.bright 
            ? AmbientLightLevel.dark 
            : AmbientLightLevel.bright;
        
        // Change light level and verify callback
        manager.setAmbientLightLevel(newLight);
        expect(lightCallbackTriggered, isTrue);
      });
      
      testWidgets('PROPERTY: ContextualAdaptationBuilder updates on changes', (WidgetTester tester) async {
        await manager.initialize();
        
        int buildCount = 0;
        ContextualUIConfig? lastConfig;
        
        await tester.pumpWidget(
          MaterialApp(
            home: ContextualAdaptationBuilder(
              builder: (context, config) {
                buildCount++;
                lastConfig = config;
                return Container();
              },
            ),
          ),
        );
        
        final initialBuildCount = buildCount;
        final initialContext = lastConfig?.context;
        
        // Change context and verify rebuild
        final newContext = initialContext == UsageContext.driving 
            ? UsageContext.walking 
            : UsageContext.driving;
        manager.setUsageContext(newContext);
        await tester.pump();
        
        expect(buildCount, greaterThanOrEqualTo(initialBuildCount));
        expect(lastConfig?.context, equals(newContext));
      });
    });
  });
}