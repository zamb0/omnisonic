import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';

void main() {
  group('Design System Integration Tests', () {
    testWidgets('Design system components work together', (WidgetTester tester) async {
      // Create a test app with the design system
      await tester.pumpWidget(
        MaterialApp(
          theme: OmnisonicTheme.lightTheme,
          darkTheme: OmnisonicTheme.darkTheme,
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Integration Test'),
            ),
            body: SingleChildScrollView(
              padding: OmnisonicInsets.screen,
              child: Column(
                children: [
                  // Test color system
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: OmnisonicColors.primaryGradient,
                      borderRadius: BorderRadius.circular(OmnisonicRadius.md),
                    ),
                    child: const Center(
                      child: Text(
                        'Color System Test',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: OmnisonicSpacing.md),
                  
                  // Test typography
                  Text(
                    'Typography Test',
                    style: OmnisonicTypography.headlineMedium,
                  ),
                  const SizedBox(height: OmnisonicSpacing.sm),
                  Text(
                    'Body text example',
                    style: OmnisonicTypography.bodyLarge,
                  ),
                  const SizedBox(height: OmnisonicSpacing.md),
                  
                  // Test buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          child: const Text('Elevated'),
                        ),
                      ),
                      const SizedBox(width: OmnisonicSpacing.sm),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          child: const Text('Outlined'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: OmnisonicSpacing.md),
                  
                  // Test card
                  Card(
                    child: Padding(
                      padding: OmnisonicInsets.card,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Card Title',
                            style: OmnisonicTypography.titleMedium,
                          ),
                          const SizedBox(height: OmnisonicSpacing.sm),
                          Text(
                            'Card content with proper spacing and typography.',
                            style: OmnisonicTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify the app renders without errors
      expect(find.text('Integration Test'), findsOneWidget);
      expect(find.text('Color System Test'), findsOneWidget);
      expect(find.text('Typography Test'), findsOneWidget);
      expect(find.text('Body text example'), findsOneWidget);
      expect(find.text('Elevated'), findsOneWidget);
      expect(find.text('Outlined'), findsOneWidget);
      expect(find.text('Card Title'), findsOneWidget);
      expect(find.text('Card content with proper spacing and typography.'), findsOneWidget);
    });

    testWidgets('Theme switching works correctly', (WidgetTester tester) async {
      final themeManager = OmnisonicThemeManager();
      await themeManager.initialize();

      await tester.pumpWidget(
        ListenableBuilder(
          listenable: themeManager,
          builder: (context, child) {
            return MaterialApp(
              theme: OmnisonicTheme.lightTheme,
              darkTheme: OmnisonicTheme.darkTheme,
              themeMode: themeManager.themeMode,
              home: Scaffold(
                appBar: AppBar(
                  title: const Text('Theme Test'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.brightness_6),
                      onPressed: () async {
                        await themeManager.toggleTheme();
                      },
                    ),
                  ],
                ),
                body: const Center(
                  child: Text('Theme switching test'),
                ),
              ),
            );
          },
        ),
      );

      // Verify initial state
      expect(find.text('Theme Test'), findsOneWidget);
      expect(find.text('Theme switching test'), findsOneWidget);

      // Test theme toggle
      await tester.tap(find.byIcon(Icons.brightness_6));
      await tester.pumpAndSettle();

      // Verify the app still works after theme change
      expect(find.text('Theme Test'), findsOneWidget);
      expect(find.text('Theme switching test'), findsOneWidget);
    });

    testWidgets('Responsive layout adapts to different sizes', (WidgetTester tester) async {
      // Test mobile layout
      await tester.binding.setSurfaceSize(const Size(400, 800));
      
      await tester.pumpWidget(
        MaterialApp(
          theme: OmnisonicTheme.lightTheme,
          home: Scaffold(
            body: ResponsiveLayout(
              mobile: const Center(child: Text('Mobile Layout')),
              tablet: const Center(child: Text('Tablet Layout')),
              desktop: const Center(child: Text('Desktop Layout')),
            ),
          ),
        ),
      );

      expect(find.text('Mobile Layout'), findsOneWidget);

      // Test tablet layout
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpAndSettle();

      expect(find.text('Tablet Layout'), findsOneWidget);

      // Test desktop layout
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpAndSettle();

      expect(find.text('Desktop Layout'), findsOneWidget);

      // Reset to default size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Animation system works correctly', (WidgetTester tester) async {
      late AnimationController controller;
      late Animation<double> animation;

      await tester.pumpWidget(
        MaterialApp(
          theme: OmnisonicTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: animation.value,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: OmnisonicColors.primaryBlue,
                                borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
                              ),
                              child: const Center(
                                child: Text(
                                  'Animated',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: OmnisonicSpacing.md),
                      ElevatedButton(
                        onPressed: () {
                          if (controller.isCompleted) {
                            controller.reverse();
                          } else {
                            controller.forward();
                          }
                        },
                        child: const Text('Animate'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Initialize animation after the widget is built
      await tester.pumpAndSettle();
      
      final context = tester.element(find.byType(Scaffold));
      final animationManager = AnimationManager();
      
      controller = animationManager.createController(
        duration: AnimationManager.fastDuration,
        vsync: tester,
      );
      
      animation = animationManager.createTween<double>(
        controller: controller,
        begin: 1.0,
        end: 1.5,
      );

      // Rebuild with the animation
      await tester.pumpAndSettle();

      // Verify the animated widget exists
      expect(find.text('Animated'), findsOneWidget);
      expect(find.text('Animate'), findsOneWidget);

      // Test animation
      await tester.tap(find.text('Animate'));
      await tester.pump();
      await tester.pump(AnimationManager.fastDuration);

      // Verify animation completed
      expect(controller.isCompleted, isTrue);

      // Cleanup
      controller.dispose();
      animationManager.dispose();
    });
  });
}