import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/design_system.dart';

void main() {
  group('Design System Checkpoint Verification', () {
    testWidgets('All design system components are accessible and work together', (WidgetTester tester) async {
      // Test that all design system components can be imported and used
      await tester.pumpWidget(
        MaterialApp(
          theme: OmnisonicTheme.lightTheme,
          darkTheme: OmnisonicTheme.darkTheme,
          home: Builder(
            builder: (context) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Checkpoint Test'),
                ),
                body: SingleChildScrollView(
                  padding: OmnisonicInsets.screen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Test colors
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: context.primaryGradient,
                          borderRadius: BorderRadius.circular(OmnisonicRadius.md),
                        ),
                        child: const Center(
                          child: Text(
                            'Colors Work',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: OmnisonicSpacing.md),
                      
                      // Test typography
                      Text(
                        'Typography Works',
                        style: context.textTheme.headlineMedium,
                      ),
                      Text(
                        'Body text works too',
                        style: context.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: OmnisonicSpacing.md),
                      
                      // Test spacing
                      Row(
                        children: [
                          Container(
                            width: OmnisonicSpacing.xl,
                            height: 20,
                            color: context.colorScheme.primary,
                          ),
                          const SizedBox(width: OmnisonicSpacing.md),
                          const Text('Spacing Works'),
                        ],
                      ),
                      const SizedBox(height: OmnisonicSpacing.md),
                      
                      // Test buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              child: const Text('Buttons Work'),
                            ),
                          ),
                          const SizedBox(width: OmnisonicSpacing.sm),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              child: const Text('Outlined Too'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: OmnisonicSpacing.md),
                      
                      // Test cards
                      Card(
                        child: Padding(
                          padding: OmnisonicInsets.card,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cards Work',
                                style: context.textTheme.titleMedium,
                              ),
                              const SizedBox(height: OmnisonicSpacing.sm),
                              const Text('With proper theming and spacing'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Verify all components render correctly
      expect(find.text('Checkpoint Test'), findsOneWidget);
      expect(find.text('Colors Work'), findsOneWidget);
      expect(find.text('Typography Works'), findsOneWidget);
      expect(find.text('Body text works too'), findsOneWidget);
      expect(find.text('Spacing Works'), findsOneWidget);
      expect(find.text('Buttons Work'), findsOneWidget);
      expect(find.text('Outlined Too'), findsOneWidget);
      expect(find.text('Cards Work'), findsOneWidget);
      expect(find.text('With proper theming and spacing'), findsOneWidget);
    });

    test('Theme manager can be initialized and used', () {
      final themeManager = OmnisonicThemeManager();
      
      // Test initial state
      expect(themeManager.themeMode, ThemeMode.system);
      expect(themeManager.isInitialized, false);
      
      // Test theme mode names
      expect(themeManager.themeModeName, 'System');
    });

    test('Animation manager can be initialized and used', () {
      final animationManager = AnimationManager();
      
      // Test initialization
      animationManager.initialize();
      expect(animationManager.activeAnimationCount, 0);
      expect(animationManager.isPerformanceMonitoringEnabled, false);
      
      // Test with performance monitoring
      animationManager.initialize(enablePerformanceMonitoring: true);
      expect(animationManager.isPerformanceMonitoringEnabled, true);
      
      // Cleanup
      animationManager.dispose();
    });

    test('Responsive breakpoints work correctly', () {
      // Test breakpoint constants
      expect(ResponsiveBreakpoints.mobile, 480);
      expect(ResponsiveBreakpoints.tablet, 768);
      expect(ResponsiveBreakpoints.desktop, 1024);
      expect(ResponsiveBreakpoints.largeDesktop, 1440);
    });

    test('Color system provides all required colors', () {
      // Test primary colors
      expect(OmnisonicColors.primaryPurple, const Color(0xFF6366F1));
      expect(OmnisonicColors.primaryBlue, const Color(0xFF3B82F6));
      expect(OmnisonicColors.primaryTeal, const Color(0xFF06B6D4));
      
      // Test semantic colors
      expect(OmnisonicColors.success, const Color(0xFF10B981));
      expect(OmnisonicColors.warning, const Color(0xFFF59E0B));
      expect(OmnisonicColors.error, const Color(0xFFEF4444));
      expect(OmnisonicColors.info, const Color(0xFF3B82F6));
      
      // Test gradients are defined
      expect(OmnisonicColors.primaryGradient, isA<LinearGradient>());
      expect(OmnisonicColors.accentGradient, isA<LinearGradient>());
      expect(OmnisonicColors.heroGradient, isA<LinearGradient>());
    });

    test('Typography system provides all required styles', () {
      // Test font families
      expect(OmnisonicTypography.primaryFont, 'Inter');
      expect(OmnisonicTypography.displayFont, 'Poppins');
      
      // Test text styles are defined
      expect(OmnisonicTypography.displayLarge, isA<TextStyle>());
      expect(OmnisonicTypography.headlineMedium, isA<TextStyle>());
      expect(OmnisonicTypography.titleLarge, isA<TextStyle>());
      expect(OmnisonicTypography.bodyLarge, isA<TextStyle>());
      expect(OmnisonicTypography.labelMedium, isA<TextStyle>());
      
      // Test music-specific styles
      expect(OmnisonicTypography.trackTitle, isA<TextStyle>());
      expect(OmnisonicTypography.artistName, isA<TextStyle>());
      expect(OmnisonicTypography.albumTitle, isA<TextStyle>());
    });

    test('Spacing system follows 8px grid', () {
      // Test spacing values
      expect(OmnisonicSpacing.xs, 4);
      expect(OmnisonicSpacing.sm, 8);
      expect(OmnisonicSpacing.md, 16);
      expect(OmnisonicSpacing.lg, 24);
      expect(OmnisonicSpacing.xl, 32);
      
      // Verify they follow 4px/8px grid
      expect(OmnisonicSpacing.xs % 4, 0);
      expect(OmnisonicSpacing.sm % 4, 0);
      expect(OmnisonicSpacing.md % 8, 0);
      expect(OmnisonicSpacing.lg % 8, 0);
      expect(OmnisonicSpacing.xl % 8, 0);
    });

    test('Animation system provides standardized values', () {
      // Test durations
      expect(AnimationManager.fastDuration, const Duration(milliseconds: 150));
      expect(AnimationManager.normalDuration, const Duration(milliseconds: 300));
      expect(AnimationManager.slowDuration, const Duration(milliseconds: 500));
      
      // Test curves
      expect(AnimationManager.standardCurve, Curves.easeInOutCubic);
      expect(AnimationManager.fastCurve, Curves.easeOutQuart);
      expect(AnimationManager.slowCurve, Curves.easeInOutQuint);
    });
  });
}