import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/checkpoint_test_app.dart';

void main() {
  group('Design System Checkpoint App Tests', () {
    testWidgets('Checkpoint app can be created and rendered', (
      WidgetTester tester,
    ) async {
      // Test that the checkpoint app can be instantiated and rendered
      await tester.pumpWidget(const DesignSystemCheckpointApp());

      // Verify the app renders without errors
      expect(find.text('Design System Checkpoint'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);

      // Verify key sections are present
      expect(find.text('Color System Test'), findsOneWidget);
      expect(find.text('Typography Test'), findsOneWidget);
      expect(find.text('Animation Test'), findsOneWidget);
      expect(find.text('Responsive Test'), findsOneWidget);
      expect(find.text('Components Test'), findsOneWidget);
    });

    testWidgets('Theme switching works in checkpoint app', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const DesignSystemCheckpointApp());

      // Find and tap the theme toggle button
      final themeButton = find.byIcon(Icons.dark_mode);
      expect(themeButton, findsOneWidget);

      await tester.tap(themeButton);
      await tester.pump();

      // Verify the theme toggle button icon changed
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
    });

    testWidgets('Responsive layout adapts correctly', (
      WidgetTester tester,
    ) async {
      // Test mobile layout
      await tester.pumpWidget(const DesignSystemCheckpointApp());

      // Verify mobile-specific elements
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      // Test tablet layout by changing screen size
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const DesignSystemCheckpointApp());
      await tester.pump();

      // Verify tablet-specific elements
      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('Animation test button works', (WidgetTester tester) async {
      await tester.pumpWidget(const DesignSystemCheckpointApp());

      // Find and tap the animation test button
      final animationButton = find.text('Test Animations');
      expect(animationButton, findsOneWidget);

      await tester.tap(animationButton);
      await tester.pump();

      // Verify the button state changes during animation
      expect(find.text('Animating...'), findsOneWidget);
    });

    testWidgets('Component interactions work', (WidgetTester tester) async {
      await tester.pumpWidget(const DesignSystemCheckpointApp());

      // Test button interactions
      await tester.tap(find.text('Elevated'));
      await tester.pump();

      await tester.tap(find.text('Outlined'));
      await tester.pump();

      await tester.tap(find.text('Text'));
      await tester.pump();

      // Test FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // Verify no errors occurred
      expect(tester.takeException(), isNull);
    });
  });
}
