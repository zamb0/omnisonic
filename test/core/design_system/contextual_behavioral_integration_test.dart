import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/contextual_behavioral_integration.dart';
import 'package:omnisonic/core/design_system/contextual_adaptation.dart';
import 'package:omnisonic/core/design_system/behavioral_optimization.dart';
import 'package:omnisonic/core/design_system/adaptive_performance.dart';

void main() {
  group('Contextual and Behavioral Integration Tests', () {
    testWidgets('IntelligentUIAdapter integrates all systems correctly', (
      WidgetTester tester,
    ) async {
      // Initialize managers
      await ContextualAdaptationManager().initialize();
      await BehavioralOptimizationManager().initialize();

      IntelligentUIConfig? capturedConfig;

      await tester.pumpWidget(
        MaterialApp(
          home: IntelligentUIAdapter(
            builder: (context, config) {
              capturedConfig = config;
              return Container();
            },
          ),
        ),
      );

      // Verify config is created
      expect(capturedConfig, isNotNull);
      expect(capturedConfig!.contextualConfig, isNotNull);
      expect(capturedConfig!.behavioralConfig, isNotNull);
      expect(capturedConfig!.performanceConfig, isNotNull);

      // Verify combined adaptations
      expect(capturedConfig!.adaptiveTouchTargets, isNotNull);
      expect(capturedConfig!.intelligentSpacing, isNotNull);
      expect(capturedConfig!.optimizedLayout, isNotNull);
      expect(capturedConfig!.smartAnimations, isNotNull);
      expect(capturedConfig!.contextAwareColors, isNotNull);
      expect(capturedConfig!.behavioralShortcuts, isNotNull);

      // Test helper methods
      final touchTargetSize = capturedConfig!.getTouchTargetSize(
        'test_element',
      );
      expect(touchTargetSize, greaterThan(0));

      final animationDuration = capturedConfig!.getAnimationDuration('micro');
      expect(animationDuration.inMilliseconds, greaterThan(0));

      final contextColor = capturedConfig!.getContextAwareColor('primary');
      expect(contextColor, isNotNull);

      // Cleanup
      ContextualAdaptationManager().dispose();
      BehavioralOptimizationManager().dispose();
    });

    testWidgets('IntelligentMusicPlayerCard adapts based on usage patterns', (
      WidgetTester tester,
    ) async {
      // Initialize managers
      await ContextualAdaptationManager().initialize();
      await BehavioralOptimizationManager().initialize();

      // Record some interactions to simulate usage
      BehavioralOptimizationManager().recordInteraction(
        UserInteraction(
          elementId: 'album_test_album',
          type: InteractionType.tap,
          timestamp: DateTime.now(),
          wasSuccessful: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 200,
                height: 300,
                child: IntelligentMusicPlayerCard(
                  albumId: 'test_album',
                  albumTitle: 'Test Album',
                  artistName: 'Test Artist',
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      // Verify the card renders
      expect(find.text('Test Album'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);

      // Test interaction
      await tester.tap(find.byType(IntelligentMusicPlayerCard));
      await tester.pump();

      // Verify interaction was recorded
      final pattern = BehavioralOptimizationManager().getInteractionPattern(
        'album_test_album',
      );
      expect(pattern, isNotNull);
      expect(pattern!.totalInteractions, greaterThan(0));

      // Cleanup
      ContextualAdaptationManager().dispose();
      BehavioralOptimizationManager().dispose();
    });

    test('IntelligentUIConfig provides consistent API', () {
      final contextualConfig = ContextualUIConfig(
        context: UsageContext.stationary,
        lightLevel: AmbientLightLevel.normal,
        deviceCharacteristics: const DeviceCharacteristics(),
        touchTargetSize: 44.0,
        spacing: const EdgeInsets.all(16.0),
        fontSize: 1.0,
        contrast: 1.0,
        colorIntensity: 1.0,
        buttonSize: 44.0,
        cardElevation: 4.0,
        animationSpeed: 1.0,
      );

      final behavioralConfig = AdaptiveLayoutConfig(
        frequentlyUsedElements: [],
        preferredNavigationPaths: [],
        optimizedElementPositions: {},
        suggestedShortcuts: [],
        adaptiveSpacing: const EdgeInsets.all(16.0),
        intelligentGrouping: {},
      );

      final performanceConfig = AdaptiveAnimationConfig(
        enableMicroInteractions: true,
        enablePageTransitions: true,
        enableLoadingAnimations: true,
        enableParticleEffects: false,
        enableComplexAnimations: true,
        maxAnimationLayers: 2,
        animationQuality: AnimationQuality.high,
      );

      final intelligentConfig = IntelligentUIConfig(
        contextualConfig: contextualConfig,
        behavioralConfig: behavioralConfig,
        performanceConfig: performanceConfig,
        adaptiveTouchTargets: {'test': 48.0},
        intelligentSpacing: const EdgeInsets.all(20.0),
        optimizedLayout: {'test': const Offset(0.5, 0.5)},
        smartAnimations: {'micro': const Duration(milliseconds: 150)},
        contextAwareColors: {'primary': Colors.blue},
        behavioralShortcuts: [],
      );

      // Test API methods
      expect(intelligentConfig.getTouchTargetSize('test'), equals(48.0));
      expect(
        intelligentConfig.getTouchTargetSize('unknown'),
        equals(44.0),
      ); // fallback

      expect(
        intelligentConfig.getOptimalPosition('test'),
        equals(const Offset(0.5, 0.5)),
      );
      expect(intelligentConfig.getOptimalPosition('unknown'), isNull);

      expect(
        intelligentConfig.getAnimationDuration('micro'),
        equals(const Duration(milliseconds: 150)),
      );
      expect(
        intelligentConfig.getAnimationDuration('unknown'),
        equals(const Duration(milliseconds: 300)),
      ); // fallback

      expect(
        intelligentConfig.getContextAwareColor('primary'),
        equals(Colors.blue),
      );
      expect(
        intelligentConfig.getContextAwareColor('unknown'),
        equals(Colors.blue),
      ); // fallback

      expect(
        intelligentConfig.shouldPromoteElement('test'),
        isFalse,
      ); // no usage data
      expect(intelligentConfig.getRelevantShortcuts(), isEmpty);
    });

    test('UIShortcut data structure works correctly', () {
      final shortcut = UIShortcut(
        id: 'test_shortcut',
        label: 'Test Shortcut',
        fromRoute: 'home',
        toRoute: 'search',
        frequency: 10,
        confidence: 0.8,
      );

      expect(shortcut.id, equals('test_shortcut'));
      expect(shortcut.label, equals('Test Shortcut'));
      expect(shortcut.fromRoute, equals('home'));
      expect(shortcut.toRoute, equals('search'));
      expect(shortcut.frequency, equals(10));
      expect(shortcut.confidence, equals(0.8));

      final groupShortcut = UIShortcut(
        id: 'group_shortcut',
        label: 'Group Shortcut',
        elementIds: ['element1', 'element2'],
        confidence: 0.9,
      );

      expect(groupShortcut.elementIds, equals(['element1', 'element2']));
      expect(groupShortcut.confidence, equals(0.9));
    });
  });
}
