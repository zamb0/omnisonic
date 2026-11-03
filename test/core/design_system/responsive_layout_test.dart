import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/responsive_layout.dart';
import 'package:omnisonic/features/ui/presentation/widgets/media_card.dart';
import 'package:omnisonic/features/ui/presentation/widgets/responsive_grid.dart';

/// This file used to cover LayoutConfiguration, ResponsiveValue and
/// ScreenSizeDetector, none of which had a single caller in the app. Testing
/// unused code proves only that it still compiles; those tests went when the
/// classes did. What is left covers the two responsive pieces the app really
/// renders through, at the boundaries where they change behaviour.
void main() {
  /// Pumps [child] inside a box of exactly [width], so the assertions are
  /// about the constraints the widget receives rather than the window.
  Future<void> pumpAtWidth(
    WidgetTester tester,
    double width,
    Widget child, {
    double? windowWidth,
  }) async {
    // The window has to be at least as wide as the box, otherwise the box is
    // clipped to it and the test silently measures the wrong width.
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(windowWidth ?? width, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, height: 800, child: child),
        ),
      ),
    );
  }

  group('ResponsiveLayout', () {
    Widget layout() => const ResponsiveLayout(
      mobile: Text('mobile'),
      tablet: Text('tablet'),
      desktop: Text('desktop'),
      largeDesktop: Text('largeDesktop'),
    );

    // An off-by-one at a breakpoint stays invisible until someone resizes
    // onto exactly that width, so both sides of each are checked.
    final cases = <double, String>{
      ResponsiveBreakpoints.mobile - 1: 'mobile',
      ResponsiveBreakpoints.mobile: 'tablet',
      ResponsiveBreakpoints.desktop - 1: 'tablet',
      ResponsiveBreakpoints.desktop: 'desktop',
      ResponsiveBreakpoints.largeDesktop - 1: 'desktop',
      ResponsiveBreakpoints.largeDesktop: 'largeDesktop',
    };

    cases.forEach((width, expected) {
      testWidgets('at ${width}px shows $expected', (tester) async {
        await pumpAtWidth(tester, width, layout());
        expect(find.text(expected), findsOneWidget);
      });
    });

    testWidgets('falls back down the chain when a variant is missing', (
      tester,
    ) async {
      await pumpAtWidth(
        tester,
        ResponsiveBreakpoints.largeDesktop,
        const ResponsiveLayout(mobile: Text('mobile'), tablet: Text('tablet')),
      );

      expect(find.text('tablet'), findsOneWidget);
    });

    testWidgets('measures its own constraints, not the window', (tester) async {
      // The sidebar makes the content column narrower than the screen. A
      // layout keyed off MediaQuery would answer "largeDesktop" here and
      // blow out of a 400px column.
      await pumpAtWidth(tester, 400, layout(), windowWidth: 1440);

      expect(find.text('mobile'), findsOneWidget);
    });
  });

  group('ResponsiveGridView', () {
    Future<int> columnsAt(WidgetTester tester, double width) async {
      await pumpAtWidth(
        tester,
        width,
        ResponsiveGridView(
          itemCount: 24,
          minItemWidth: 160,
          spacing: 16,
          itemBuilder: (context, index) => Text('item$index'),
        ),
      );

      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      return delegate.crossAxisCount;
    }

    testWidgets('fits as many columns as the width allows', (tester) async {
      expect(await columnsAt(tester, 400), 2);
      expect(await columnsAt(tester, 800), 4);
    });

    testWidgets('never drops below one column', (tester) async {
      // Narrower than a single item: a zero column count throws inside the
      // grid delegate rather than degrading.
      expect(await columnsAt(tester, 100), 1);
    });

    testWidgets('adds columns rather than growing cards past the max', (
      tester,
    ) async {
      // A fixed six-column cap rendered album art at poster size on an
      // ultrawide window; capping the card width instead scales with it.
      final columns = await columnsAt(tester, 4000);
      final cell = MediaGridPreset.cellWidth(4000, columns);
      expect(cell, lessThanOrEqualTo(MediaGridPreset.maxItemWidth));
      expect(cell, greaterThanOrEqualTo(160));
    });

    testWidgets('media cells fit a square cover and the text', (tester) async {
      await pumpAtWidth(
        tester,
        360,
        ResponsiveGridView.media(
          itemCount: 4,
          itemBuilder: (context, index) => MediaCard(title: 'Album $index'),
        ),
      );

      final art = tester.getSize(find.byType(AspectRatio).first);
      expect(art.width, art.height);
      expect(art.width, greaterThan(140));
      expect(tester.takeException(), isNull);
    });

    testWidgets('builds lazily rather than eagerly', (tester) async {
      await pumpAtWidth(
        tester,
        800,
        ResponsiveGridView(
          itemCount: 500,
          minItemWidth: 160,
          itemBuilder: (context, index) => Text('item$index'),
        ),
      );

      expect(find.byType(Text).evaluate().length, lessThan(60));
    });
  });
}
