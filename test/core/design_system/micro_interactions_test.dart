import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/micro_interactions.dart';

void main() {
  group('MicroInteractions', () {
    testWidgets('should create interactive button', (
      WidgetTester tester,
    ) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MicroInteractions.interactiveButton(
              onPressed: () {
                buttonPressed = true;
              },
              child: const Text('Test Button'),
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);

      await tester.tap(find.text('Test Button'));
      await tester.pump();

      expect(buttonPressed, isTrue);
    });

    testWidgets('should create interactive card', (WidgetTester tester) async {
      bool cardTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MicroInteractions.interactiveCard(
              onTap: () {
                cardTapped = true;
              },
              child: const Text('Test Card'),
            ),
          ),
        ),
      );

      expect(find.text('Test Card'), findsOneWidget);

      await tester.tap(find.text('Test Card'));
      await tester.pump();

      expect(cardTapped, isTrue);
    });

    testWidgets('should create interactive list item', (
      WidgetTester tester,
    ) async {
      bool itemTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MicroInteractions.interactiveListItem(
              onTap: () {
                itemTapped = true;
              },
              child: const Text('Test List Item'),
            ),
          ),
        ),
      );

      expect(find.text('Test List Item'), findsOneWidget);

      await tester.tap(find.text('Test List Item'));
      await tester.pump();

      expect(itemTapped, isTrue);
    });

    testWidgets('should create ripple effect', (WidgetTester tester) async {
      bool rippleTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MicroInteractions.rippleEffect(
              onTap: () {
                rippleTapped = true;
              },
              child: const Text('Test Ripple'),
            ),
          ),
        ),
      );

      expect(find.text('Test Ripple'), findsOneWidget);

      await tester.tap(find.text('Test Ripple'));
      await tester.pump();

      expect(rippleTapped, isTrue);
    });

    testWidgets('should create pulse animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MicroInteractions.pulseAnimation(
              child: const Text('Test Pulse'),
            ),
          ),
        ),
      );

      expect(find.text('Test Pulse'), findsOneWidget);

      // Let the animation run for a bit
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('should create hover effect on supported platforms', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MicroInteractions.hoverEffect(
              builder: (isHovering) {
                return Container(
                  color: isHovering ? Colors.blue : Colors.red,
                  child: const Text('Test Hover'),
                );
              },
              child: const Text('Test Hover'),
            ),
          ),
        ),
      );

      expect(find.text('Test Hover'), findsOneWidget);
    });

    test('should trigger haptic feedback', () {
      // This test just ensures the method doesn't throw
      expect(() {
        MicroInteractions.triggerHapticFeedback(lightImpact: true);
      }, returnsNormally);

      expect(() {
        MicroInteractions.triggerHapticFeedback(lightImpact: false);
      }, returnsNormally);

      expect(() {
        MicroInteractions.triggerHapticFeedback(respectUserSettings: false);
      }, returnsNormally);
    });
  });
}
