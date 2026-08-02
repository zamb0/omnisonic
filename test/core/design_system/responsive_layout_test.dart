import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/responsive_layout.dart';

/// Pumps [child] with the test view resized to [size] logical pixels.
///
/// `tester.binding.setSurfaceSize` no longer feeds `MediaQuery` since the
/// `View` widget was introduced — the size has to be set on `tester.view`.
Future<void> pumpAtSize(WidgetTester tester, Size size, Widget child) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: child));
}

void main() {
  group('Responsive Layout System Tests', () {
    testWidgets('ResponsiveBreakpoints correctly identifies screen types', (
      tester,
    ) async {
      await pumpAtSize(
        tester,
        const Size(400, 800),
        Builder(
          builder: (context) {
            expect(ResponsiveBreakpoints.isMobile(context), true);
            expect(ResponsiveBreakpoints.isTablet(context), false);
            expect(ResponsiveBreakpoints.isDesktop(context), false);
            expect(
              ResponsiveBreakpoints.getScreenType(context),
              ScreenType.mobile,
            );
            return Container();
          },
        ),
      );

      await pumpAtSize(
        tester,
        const Size(600, 800),
        Builder(
          builder: (context) {
            expect(ResponsiveBreakpoints.isMobile(context), false);
            expect(ResponsiveBreakpoints.isTablet(context), true);
            expect(ResponsiveBreakpoints.isDesktop(context), false);
            expect(
              ResponsiveBreakpoints.getScreenType(context),
              ScreenType.tablet,
            );
            return Container();
          },
        ),
      );

      await pumpAtSize(
        tester,
        const Size(1200, 800),
        Builder(
          builder: (context) {
            expect(ResponsiveBreakpoints.isMobile(context), false);
            expect(ResponsiveBreakpoints.isTablet(context), false);
            expect(ResponsiveBreakpoints.isDesktop(context), true);
            expect(
              ResponsiveBreakpoints.getScreenType(context),
              ScreenType.desktop,
            );
            return Container();
          },
        ),
      );
    });

    testWidgets('ResponsiveLayout shows correct widget for screen size', (
      tester,
    ) async {
      const layout = ResponsiveLayout(
        mobile: Text('Mobile'),
        tablet: Text('Tablet'),
        desktop: Text('Desktop'),
      );

      await pumpAtSize(tester, const Size(400, 800), layout);
      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsNothing);

      await pumpAtSize(tester, const Size(600, 800), layout);
      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text('Desktop'), findsNothing);

      await pumpAtSize(tester, const Size(1200, 800), layout);
      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsOneWidget);
    });

    testWidgets(
      'ResponsiveLayout falls back to mobile when other layouts not provided',
      (tester) async {
        const layout = ResponsiveLayout(mobile: Text('Mobile'));

        await pumpAtSize(tester, const Size(600, 800), layout);
        expect(find.text('Mobile'), findsOneWidget);

        await pumpAtSize(tester, const Size(1200, 800), layout);
        expect(find.text('Mobile'), findsOneWidget);
      },
    );

    test(
      'LayoutConfiguration provides correct values for different screen sizes',
      () {
        // Test mobile configuration
        final mobileConfig = LayoutConfiguration.forScreenSize(400);
        expect(mobileConfig.columnsPortrait, 2);
        expect(mobileConfig.columnsLandscape, 3);
        expect(mobileConfig.enableHoverEffects, false);
        expect(mobileConfig.gridSpacing, 12);

        // Test tablet configuration
        final tabletConfig = LayoutConfiguration.forScreenSize(600);
        expect(tabletConfig.columnsPortrait, 4);
        expect(tabletConfig.columnsLandscape, 6);
        expect(tabletConfig.enableHoverEffects, true);
        expect(tabletConfig.gridSpacing, 16);

        // Test desktop configuration
        final desktopConfig = LayoutConfiguration.forScreenSize(1200);
        expect(desktopConfig.columnsPortrait, 6);
        expect(desktopConfig.columnsLandscape, 8);
        expect(desktopConfig.enableHoverEffects, true);
        expect(desktopConfig.gridSpacing, 24);

        // Test large desktop configuration
        final largeDesktopConfig = LayoutConfiguration.forScreenSize(1500);
        expect(largeDesktopConfig.columnsPortrait, 8);
        expect(largeDesktopConfig.columnsLandscape, 10);
        expect(largeDesktopConfig.gridSpacing, 32);
      },
    );

    testWidgets('ResponsiveValue returns correct value for screen size', (
      tester,
    ) async {
      const responsiveValue = ResponsiveValue<String>(
        mobile: 'Mobile Value',
        tablet: 'Tablet Value',
        desktop: 'Desktop Value',
        largeDesktop: 'Large Desktop Value',
      );

      Widget expectValue(String expected) => Builder(
        builder: (context) {
          expect(responsiveValue.getValue(context), expected);
          return Container();
        },
      );

      await pumpAtSize(
        tester,
        const Size(400, 800),
        expectValue('Mobile Value'),
      );
      await pumpAtSize(
        tester,
        const Size(600, 800),
        expectValue('Tablet Value'),
      );
      await pumpAtSize(
        tester,
        const Size(1200, 800),
        expectValue('Desktop Value'),
      );
      await pumpAtSize(
        tester,
        const Size(1500, 800),
        expectValue('Large Desktop Value'),
      );
    });

    testWidgets(
      'ResponsiveValue falls back correctly when values not provided',
      (tester) async {
        const responsiveValue = ResponsiveValue<String>(mobile: 'Mobile Value');

        Widget expectMobile() => Builder(
          builder: (context) {
            expect(responsiveValue.getValue(context), 'Mobile Value');
            return Container();
          },
        );

        await pumpAtSize(tester, const Size(600, 800), expectMobile());
        await pumpAtSize(tester, const Size(1200, 800), expectMobile());
      },
    );
  });

  group('Screen Size Detection Tests', () {
    testWidgets('ScreenSizeDetector provides correct screen information', (
      tester,
    ) async {
      await pumpAtSize(
        tester,
        const Size(400, 800),
        Builder(
          builder: (context) {
            expect(ScreenSizeDetector.getScreenWidth(context), 400);
            expect(ScreenSizeDetector.getScreenHeight(context), 800);
            expect(
              ScreenSizeDetector.getScreenSize(context),
              const Size(400, 800),
            );
            expect(ScreenSizeDetector.isPortrait(context), true);
            expect(ScreenSizeDetector.isLandscape(context), false);
            return Container();
          },
        ),
      );

      await pumpAtSize(
        tester,
        const Size(800, 400),
        Builder(
          builder: (context) {
            expect(ScreenSizeDetector.getScreenWidth(context), 800);
            expect(ScreenSizeDetector.getScreenHeight(context), 400);
            expect(ScreenSizeDetector.isPortrait(context), false);
            expect(ScreenSizeDetector.isLandscape(context), true);
            return Container();
          },
        ),
      );
    });
  });
}
