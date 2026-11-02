import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:omnisonic/core/routing/app_router.dart';
import 'package:omnisonic/core/routing/app_shortcuts.dart';

import '../../helpers/entity_factories.dart';
import '../../helpers/view_model_fakes.dart';

/// The desktop top bar advertised ⌘K from the day the redesign landed, and
/// there was no Shortcuts, Actions or SingleActivator anywhere in the app.
void main() {
  late FakePlaybackViewModel playback;
  GoRouter? router;

  setUp(() => playback = FakePlaybackViewModel());

  tearDown(() {
    router?.dispose();
    router = null;
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    bool withTextField = false,
    Widget? body,
  }) async {
    // The field belongs inside a route, not in MaterialApp's builder: an
    // EditableText needs the Navigator's Overlay above it.
    final created = GoRouter(
      initialLocation: AppRouter.home,
      routes: [
        GoRoute(
          path: AppRouter.home,
          builder: (context, state) => Scaffold(
            body:
                body ??
                (withTextField
                    ? const SizedBox(width: 200, child: TextField())
                    : const Text('home')),
          ),
        ),
        GoRoute(
          path: AppRouter.search,
          builder: (context, state) => const Scaffold(body: Text('search')),
        ),
      ],
    );
    router = created;

    await tester.pumpWidget(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: created,
        builder: (context, child) => AppShortcuts(
          playback: () => playback,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('cmd-K opens search', (tester) async {
    await pumpApp(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pumpAndSettle();

    expect(find.text('search'), findsOneWidget);
  });

  testWidgets('ctrl-K opens search too', (tester) async {
    // The same build ships on Windows and Linux, where meta is not the
    // modifier anyone reaches for.
    await pumpApp(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pumpAndSettle();

    expect(find.text('search'), findsOneWidget);
  });

  testWidgets('space toggles playback', (tester) async {
    playback.emitPlaying(testTrack(), isPlaying: true);
    await pumpApp(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(playback.isPlaying, isFalse);
  });

  testWidgets('the arrow keys seek', (tester) async {
    playback.emitPlaying(
      testTrack(duration: const Duration(minutes: 3)),
      position: const Duration(seconds: 60),
    );
    await pumpApp(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(playback.position, const Duration(seconds: 70));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(playback.position, const Duration(seconds: 60));
  });

  testWidgets('seeking clamps to the track', (tester) async {
    playback.emitPlaying(
      testTrack(duration: const Duration(minutes: 3)),
      position: const Duration(seconds: 3),
    );
    await pumpApp(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(playback.position, Duration.zero);
  });

  testWidgets('nothing fires while a text field has focus', (tester) async {
    // Otherwise typing "k" into search navigates, and a space pauses the
    // music mid-word.
    playback.emitPlaying(testTrack(), isPlaying: true);
    await pumpApp(tester, withTextField: true);

    // Tapping rather than relying on autofocus: inside a route the page's
    // own focus scope can hold primary focus instead.
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorStateOfType<EditableTextState>(),
      isNotNull,
      reason: 'the field never took focus, so the guard is untested',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pumpAndSettle();

    expect(playback.isPlaying, isTrue);
    expect(find.text('search'), findsNothing);
  });

  testWidgets('seeking does nothing with no track', (tester) async {
    await pumpApp(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(playback.position, Duration.zero);
  });

  testWidgets('space presses a focused button instead of toggling playback', (
    tester,
  ) async {
    playback.emitPlaying(testTrack(), isPlaying: true);
    var pressed = 0;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await pumpApp(
      tester,
      body: TextButton(
        focusNode: focus,
        onPressed: () => pressed++,
        child: const Text('Press'),
      ),
    );

    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    expect(pressed, 1);
    expect(playback.isPlaying, isTrue);
  });

  testWidgets('arrows leave a focused control alone', (tester) async {
    playback.emitPlaying(testTrack(), position: const Duration(seconds: 30));
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await pumpApp(
      tester,
      body: TextButton(
        focusNode: focus,
        onPressed: () {},
        child: const Text('Press'),
      ),
    );

    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(playback.position, const Duration(seconds: 30));
  });
}
