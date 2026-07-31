import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/design_system/enhanced_text.dart';
import 'package:omnisonic/core/design_system/animated_text.dart';
import 'package:omnisonic/core/design_system/typography.dart';

void main() {
  group('Typography System Tests', () {
    testWidgets('EnhancedText displays text correctly', (
      WidgetTester tester,
    ) async {
      const testText = 'Test Text';

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: EnhancedText(testText))),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('EnhancedText shows tooltip when truncated', (
      WidgetTester tester,
    ) async {
      const testText = 'This is a very long text that should be truncated';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              child: EnhancedText(testText, maxLines: 1, showTooltip: true),
            ),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('TrackTitleText displays with correct styling', (
      WidgetTester tester,
    ) async {
      const testTitle = 'Test Track';

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TrackTitleText(testTitle))),
      );

      expect(find.text(testTitle), findsOneWidget);

      final textWidget = tester.widget<Text>(find.text(testTitle));
      expect(
        textWidget.style?.fontFamily,
        equals(OmnisonicTypography.primaryFont),
      );
    });

    testWidgets('TrackTitleText shows playing state correctly', (
      WidgetTester tester,
    ) async {
      const testTitle = 'Playing Track';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TrackTitleText(testTitle, isPlaying: true)),
        ),
      );

      expect(find.text(testTitle), findsOneWidget);

      final textWidget = tester.widget<Text>(find.text(testTitle));
      expect(textWidget.style?.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('ArtistNameText displays correctly', (
      WidgetTester tester,
    ) async {
      const testArtist = 'Test Artist';

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ArtistNameText(testArtist))),
      );

      expect(find.text(testArtist), findsOneWidget);
    });

    testWidgets('NowPlayingText displays title and artist', (
      WidgetTester tester,
    ) async {
      const testTitle = 'Test Song';
      const testArtist = 'Test Artist';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NowPlayingText(title: testTitle, artist: testArtist),
          ),
        ),
      );

      expect(find.text(testTitle), findsOneWidget);
      expect(find.text(testArtist), findsOneWidget);
    });

    testWidgets('DurationText formats duration correctly', (
      WidgetTester tester,
    ) async {
      const testDuration = Duration(minutes: 3, seconds: 45);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DurationText(testDuration))),
      );

      expect(find.text('3:45'), findsOneWidget);
    });

    testWidgets('DurationText formats duration with hours', (
      WidgetTester tester,
    ) async {
      const testDuration = Duration(hours: 1, minutes: 23, seconds: 45);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DurationText(testDuration, showHours: true)),
        ),
      );

      expect(find.text('1:23:45'), findsOneWidget);
    });

    testWidgets('MetadataText displays label and value', (
      WidgetTester tester,
    ) async {
      const testLabel = 'Genre';
      const testValue = 'Rock';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetadataText(label: testLabel, value: testValue),
          ),
        ),
      );

      expect(find.textContaining(testLabel), findsOneWidget);
      expect(find.textContaining(testValue), findsOneWidget);
    });

    testWidgets('ExpandableText shows expand/collapse functionality', (
      WidgetTester tester,
    ) async {
      const longText =
          'This is a very long text that should be expandable. '
          'It contains multiple sentences and should show a "Show more" link '
          'when truncated to fewer lines than the full content requires.';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: ExpandableText(longText, maxLines: 2),
            ),
          ),
        ),
      );

      // Should show "Show more" link
      expect(find.text('Show more'), findsOneWidget);

      // Tap to expand
      await tester.tap(find.text('Show more'));
      await tester.pumpAndSettle();

      // Should now show "Show less" link
      expect(find.text('Show less'), findsOneWidget);
    });
  });

  group('Animated Text Tests', () {
    testWidgets('AnimatedText displays text correctly', (
      WidgetTester tester,
    ) async {
      const testText = 'Animated Text';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedText(testText, animationType: AnimationType.fadeIn),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('StateChangeText updates text with animation', (
      WidgetTester tester,
    ) async {
      const initialText = 'Initial Text';
      const updatedText = 'Updated Text';

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: StateChangeText(initialText))),
      );

      expect(find.text(initialText), findsOneWidget);

      // Update the text
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: StateChangeText(updatedText))),
      );

      // Allow animation to complete
      await tester.pumpAndSettle();

      expect(find.text(updatedText), findsOneWidget);
    });

    testWidgets('LoadingText displays loading animation', (
      WidgetTester tester,
    ) async {
      const testText = 'Loading';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingText(testText, loadingType: LoadingType.dots),
          ),
        ),
      );

      // Should find text with dots
      expect(find.textContaining(testText), findsOneWidget);
    });
  });

  group('Typography Scale Tests', () {
    test('Typography scale has consistent font families', () {
      expect(
        OmnisonicTypography.displayLarge.fontFamily,
        equals(OmnisonicTypography.displayFont),
      );
      expect(
        OmnisonicTypography.headlineLarge.fontFamily,
        equals(OmnisonicTypography.displayFont),
      );
      expect(
        OmnisonicTypography.titleLarge.fontFamily,
        equals(OmnisonicTypography.primaryFont),
      );
      expect(
        OmnisonicTypography.bodyLarge.fontFamily,
        equals(OmnisonicTypography.primaryFont),
      );
    });

    test('Typography scale has proper font sizes', () {
      expect(OmnisonicTypography.displayLarge.fontSize, equals(57));
      expect(OmnisonicTypography.displayMedium.fontSize, equals(45));
      expect(OmnisonicTypography.headlineLarge.fontSize, equals(32));
      expect(OmnisonicTypography.titleLarge.fontSize, equals(22));
      expect(OmnisonicTypography.bodyLarge.fontSize, equals(16));
    });

    test('Music-specific typography has correct properties', () {
      expect(
        OmnisonicTypography.trackTitle.fontFamily,
        equals(OmnisonicTypography.primaryFont),
      );
      expect(OmnisonicTypography.trackTitle.fontSize, equals(16));
      expect(
        OmnisonicTypography.trackTitle.fontWeight,
        equals(FontWeight.w500),
      );

      expect(
        OmnisonicTypography.artistName.fontFamily,
        equals(OmnisonicTypography.primaryFont),
      );
      expect(OmnisonicTypography.artistName.fontSize, equals(14));

      expect(
        OmnisonicTypography.albumTitle.fontFamily,
        equals(OmnisonicTypography.primaryFont),
      );
      expect(OmnisonicTypography.albumTitle.fontSize, equals(14));
      expect(
        OmnisonicTypography.albumTitle.fontWeight,
        equals(FontWeight.w500),
      );
    });

    test('Typography utilities work correctly', () {
      const baseStyle = TextStyle(fontSize: 16, color: Colors.black);
      const newColor = Colors.blue;

      final styledText = OmnisonicTypography.withColor(baseStyle, newColor);
      expect(styledText.color, equals(newColor));
      expect(styledText.fontSize, equals(baseStyle.fontSize));

      final opacityText = OmnisonicTypography.withOpacity(baseStyle, 0.5);
      expect(opacityText.color?.alpha, equals((255 * 0.5).round()));
    });
  });
}
