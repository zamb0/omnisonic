import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/behavioral_optimization.dart';

void main() {
  group('Behavioral UI Optimization Tests', () {
    group('Property 49: Behavioral UI Optimization', () {
      test('PROPERTY: User interactions are recorded and tracked', () {
        final manager = BehavioralOptimizationManager();

        // Record multiple interactions
        final interactions = [
          UserInteraction(
            elementId: 'play_button',
            type: InteractionType.tap,
            timestamp: DateTime.now(),
            wasSuccessful: true,
          ),
          UserInteraction(
            elementId: 'play_button',
            type: InteractionType.tap,
            timestamp: DateTime.now().add(const Duration(seconds: 1)),
            wasSuccessful: true,
          ),
          UserInteraction(
            elementId: 'album_card_1',
            type: InteractionType.tap,
            timestamp: DateTime.now().add(const Duration(seconds: 2)),
            wasSuccessful: true,
          ),
        ];

        for (final interaction in interactions) {
          manager.recordInteraction(interaction);
        }

        // Verify interactions are tracked
        final playButtonPattern = manager.getInteractionPattern('play_button');
        expect(playButtonPattern, isNotNull);
        expect(playButtonPattern!.totalInteractions, equals(2));
        expect(playButtonPattern.successfulInteractions, equals(2));
        expect(playButtonPattern.successRate, equals(1.0));

        final albumCardPattern = manager.getInteractionPattern('album_card_1');
        expect(albumCardPattern, isNotNull);
        expect(albumCardPattern!.totalInteractions, equals(1));

        manager.dispose();
      });

      test('PROPERTY: Frequently used elements are identified', () {
        final manager = BehavioralOptimizationManager();

        // Simulate frequent usage of specific elements
        final frequentElement = 'search_button';
        final infrequentElement = 'settings_button';

        // Record many interactions for frequent element
        for (int i = 0; i < 15; i++) {
          manager.recordInteraction(
            UserInteraction(
              elementId: frequentElement,
              type: InteractionType.tap,
              timestamp: DateTime.now().add(Duration(seconds: i)),
              wasSuccessful: true,
            ),
          );
        }

        // Record few interactions for infrequent element
        for (int i = 0; i < 2; i++) {
          manager.recordInteraction(
            UserInteraction(
              elementId: infrequentElement,
              type: InteractionType.tap,
              timestamp: DateTime.now().add(Duration(seconds: i + 20)),
              wasSuccessful: true,
            ),
          );
        }

        final layoutConfig = manager.getLayoutConfig();

        // Verify frequent element is identified
        final frequentElements = layoutConfig.frequentlyUsedElements;
        expect(
          frequentElements.any((e) => e.elementId == frequentElement),
          isTrue,
        );

        // Verify frequent element has higher usage count
        final frequentElementUsage = frequentElements
            .firstWhere((e) => e.elementId == frequentElement)
            .usage
            .totalUsage;
        expect(frequentElementUsage, greaterThanOrEqualTo(15));

        manager.dispose();
      });

      test('PROPERTY: Navigation patterns are learned and optimized', () {
        final manager = BehavioralOptimizationManager();

        // Record navigation patterns
        final navigationInteractions = [
          UserInteraction(
            elementId: 'nav_home_to_search',
            type: InteractionType.navigation,
            timestamp: DateTime.now(),
            fromRoute: 'home',
            toRoute: 'search',
            duration: const Duration(milliseconds: 500),
          ),
          UserInteraction(
            elementId: 'nav_home_to_search',
            type: InteractionType.navigation,
            timestamp: DateTime.now().add(const Duration(minutes: 1)),
            fromRoute: 'home',
            toRoute: 'search',
            duration: const Duration(milliseconds: 450),
          ),
          UserInteraction(
            elementId: 'nav_search_to_player',
            type: InteractionType.navigation,
            timestamp: DateTime.now().add(const Duration(minutes: 2)),
            fromRoute: 'search',
            toRoute: 'player',
            duration: const Duration(milliseconds: 300),
          ),
        ];

        for (final interaction in navigationInteractions) {
          manager.recordInteraction(interaction);
        }

        // Verify navigation patterns are learned
        final homeToSearchPattern = manager.getNavigationPattern(
          'home->search',
        );
        expect(homeToSearchPattern, isNotNull);
        expect(homeToSearchPattern!.frequency, equals(2));
        expect(homeToSearchPattern.averageDuration, isNotNull);
        expect(
          homeToSearchPattern.averageDuration!.inMilliseconds,
          closeTo(475, 50),
        ); // Average of 500 and 450

        final layoutConfig = manager.getLayoutConfig();
        final preferredPaths = layoutConfig.preferredNavigationPaths;
        expect(
          preferredPaths.any(
            (p) => p.fromRoute == 'home' && p.toRoute == 'search',
          ),
          isTrue,
        );

        manager.dispose();
      });

      test('PROPERTY: Element positions are optimized based on usage', () {
        final manager = BehavioralOptimizationManager();

        // Record interactions with position data
        final elementId = 'volume_slider';
        final positions = [
          const Offset(100, 200),
          const Offset(110, 210),
          const Offset(105, 205),
        ];

        for (int i = 0; i < positions.length; i++) {
          manager.recordInteraction(
            UserInteraction(
              elementId: elementId,
              type: InteractionType.tap,
              timestamp: DateTime.now().add(Duration(seconds: i)),
              position: positions[i],
            ),
          );
        }

        final elementUsage = manager.getElementUsage(elementId);
        expect(elementUsage, isNotNull);
        expect(elementUsage!.averagePosition, isNotNull);

        // Verify average position is calculated correctly
        final avgPosition = elementUsage.averagePosition!;
        expect(avgPosition.dx, closeTo(105, 5)); // Average of 100, 110, 105
        expect(avgPosition.dy, closeTo(205, 5)); // Average of 200, 210, 205

        manager.dispose();
      });

      test('PROPERTY: Adaptive spacing adjusts based on usage patterns', () {
        final manager = BehavioralOptimizationManager();

        // Record interactions to establish usage patterns
        for (int i = 0; i < 20; i++) {
          manager.recordInteraction(
            UserInteraction(
              elementId: 'main_button_$i',
              type: InteractionType.tap,
              timestamp: DateTime.now().add(Duration(seconds: i)),
            ),
          );
        }

        final layoutConfig = manager.getLayoutConfig();
        final adaptiveSpacing = layoutConfig.adaptiveSpacing;

        // Verify spacing is reasonable
        expect(adaptiveSpacing.left, greaterThan(0));
        expect(adaptiveSpacing.top, greaterThan(0));
        expect(adaptiveSpacing.right, greaterThan(0));
        expect(adaptiveSpacing.bottom, greaterThan(0));

        // Verify spacing is not excessive
        expect(adaptiveSpacing.left, lessThan(50));
        expect(adaptiveSpacing.top, lessThan(50));
        expect(adaptiveSpacing.right, lessThan(50));
        expect(adaptiveSpacing.bottom, lessThan(50));

        manager.dispose();
      });

      test('PROPERTY: Interaction patterns maintain consistency', () {
        final manager = BehavioralOptimizationManager();

        // Test multiple configurations
        for (int i = 0; i < 10; i++) {
          manager.recordInteraction(
            UserInteraction(
              elementId: 'test_element_$i',
              type: InteractionType.tap,
              timestamp: DateTime.now().add(Duration(seconds: i)),
            ),
          );
        }

        final layoutConfig = manager.getLayoutConfig();

        // Verify all required properties are present and valid
        expect(layoutConfig.frequentlyUsedElements, isNotNull);
        expect(layoutConfig.preferredNavigationPaths, isNotNull);
        expect(layoutConfig.optimizedElementPositions, isNotNull);
        expect(layoutConfig.suggestedShortcuts, isNotNull);
        expect(layoutConfig.adaptiveSpacing, isNotNull);
        expect(layoutConfig.intelligentGrouping, isNotNull);

        // Verify spacing is valid
        expect(layoutConfig.adaptiveSpacing.left, greaterThanOrEqualTo(0));
        expect(layoutConfig.adaptiveSpacing.top, greaterThanOrEqualTo(0));
        expect(layoutConfig.adaptiveSpacing.right, greaterThanOrEqualTo(0));
        expect(layoutConfig.adaptiveSpacing.bottom, greaterThanOrEqualTo(0));

        manager.dispose();
      });

      test('PROPERTY: InteractionTracker data structures are valid', () {
        // Test UserInteraction creation
        final interaction = UserInteraction(
          elementId: 'test_element',
          type: InteractionType.tap,
          timestamp: DateTime.now(),
          position: const Offset(100, 200),
          context: 'test_context',
          wasSuccessful: true,
        );

        expect(interaction.elementId, equals('test_element'));
        expect(interaction.type, equals(InteractionType.tap));
        expect(interaction.position, equals(const Offset(100, 200)));
        expect(interaction.context, equals('test_context'));
        expect(interaction.wasSuccessful, isTrue);

        // Test InteractionPattern creation
        final pattern = InteractionPattern(elementId: 'test_pattern');
        pattern.totalInteractions = 5;
        pattern.successfulInteractions = 4;
        pattern.successRate = 0.8;

        expect(pattern.elementId, equals('test_pattern'));
        expect(pattern.totalInteractions, equals(5));
        expect(pattern.successfulInteractions, equals(4));
        expect(pattern.successRate, equals(0.8));

        // Test NavigationPattern creation
        final navPattern = NavigationPattern(
          fromRoute: 'home',
          toRoute: 'search',
        );
        navPattern.frequency = 10;

        expect(navPattern.fromRoute, equals('home'));
        expect(navPattern.toRoute, equals('search'));
        expect(navPattern.frequency, equals(10));

        // Test UIElementUsage creation
        final usage = UIElementUsage(elementId: 'test_usage');
        usage.totalUsage = 15;
        usage.averagePosition = const Offset(150, 250);

        expect(usage.elementId, equals('test_usage'));
        expect(usage.totalUsage, equals(15));
        expect(usage.averagePosition, equals(const Offset(150, 250)));

        // Test OptimizationSuggestion creation
        final suggestion = OptimizationSuggestion(
          id: 'test_suggestion',
          type: OptimizationType.elementPromotion,
          description: 'Test suggestion',
          confidence: 0.9,
          elementId: 'test_element',
        );

        expect(suggestion.id, equals('test_suggestion'));
        expect(suggestion.type, equals(OptimizationType.elementPromotion));
        expect(suggestion.description, equals('Test suggestion'));
        expect(suggestion.confidence, equals(0.9));
        expect(suggestion.elementId, equals('test_element'));
      });
    });
  });
}
