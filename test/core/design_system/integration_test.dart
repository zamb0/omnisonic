import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';

void main() {
  group('Design System Integration Tests', () {
    testWidgets('Design system components work together', (
      WidgetTester tester,
    ) async {
      // Create a test app with the design system
      await tester.pumpWidget(
        MaterialApp(
          theme: OmnisonicTheme.lightTheme,
          darkTheme: OmnisonicTheme.darkTheme,
          home: Scaffold(
            appBar: AppBar(title: const Text('Integration Test')),
            body: SingleChildScrollView(
              padding: OmnisonicInsets.screen,
              child: Column(
                children: [
                  // Test color system
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: OmnisonicBrand.dark.aurora,
                      borderRadius: BorderRadius.circular(OmnisonicRadius.md),
                    ),
                    child: const Center(
                      child: Text(
                        'Color System Test',
                        style: TextStyle(color: OmnisonicColors.onAurora),
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
      expect(
        find.text('Card content with proper spacing and typography.'),
        findsOneWidget,
      );
    });

    testWidgets('Responsive layout adapts to different sizes', (
      WidgetTester tester,
    ) async {
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
  });
}
