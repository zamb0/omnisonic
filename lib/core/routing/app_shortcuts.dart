import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../features/playback/presentation/viewmodels/playback_view_model.dart';
import 'app_router.dart';
import 'search_focus.dart';

/// Keyboard shortcuts for the whole app.
///
/// The desktop top bar has advertised `⌘K` since the redesign landed, and
/// nothing implemented it — there was no `Shortcuts`, `Actions` or
/// `SingleActivator` anywhere in the codebase. Desktop is a first-class
/// target here, so the affordance is now real rather than removed.
///
/// Everything is suppressed while a text field has focus, so typing "k" into
/// the search box does not seek, pause, or navigate. Space and the arrows
/// also yield to any focused control (button, checkbox, slider), which needs
/// those keys for itself.
class AppShortcuts extends StatelessWidget {
  const AppShortcuts({super.key, required this.child, required this.playback});

  final Widget child;

  /// Passed in rather than read from the tree: this sits above the router,
  /// which is above the providers a page would use.
  final PlaybackViewModel Function() playback;

  static const _seekStep = Duration(seconds: 10);

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        // Both, because the same build runs on macOS and on Windows/Linux.
        SingleActivator(LogicalKeyboardKey.keyK, meta: true): _FocusSearch(),
        SingleActivator(LogicalKeyboardKey.keyK, control: true): _FocusSearch(),
        SingleActivator(LogicalKeyboardKey.slash): _FocusSearch(),
        SingleActivator(LogicalKeyboardKey.space): _TogglePlayback(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _Seek(back: true),
        SingleActivator(LogicalKeyboardKey.arrowRight): _Seek(back: false),
        SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): _Skip(
          back: true,
        ),
        SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): _Skip(
          back: false,
        ),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _FocusSearch: _GuardedAction<_FocusSearch>(
            onInvoke: (context, [intent]) {
              SearchFocusRequest.request();
              GoRouter.of(context).go(AppRouter.search);
            },
          ),
          _TogglePlayback: _GuardedAction<_TogglePlayback>(
            yieldToControls: true,
            onInvoke: (context, [intent]) => playback().togglePlayPause(),
          ),
          _Seek: _GuardedAction<_Seek>(
            yieldToControls: true,
            onInvoke: (context, [intent]) {
              final vm = playback();
              if (!vm.hasCurrentTrack) return;
              final delta = (intent as _Seek).back ? -_seekStep : _seekStep;
              final target = vm.position + delta;
              vm.seek(
                target < Duration.zero
                    ? Duration.zero
                    : (target > vm.duration ? vm.duration : target),
              );
            },
          ),
          _Skip: _GuardedAction<_Skip>(
            yieldToControls: true,
            onInvoke: (context, [intent]) {
              final vm = playback();
              (intent as _Skip).back ? vm.skipToPrevious() : vm.skipToNext();
            },
          ),
        },
        child: child,
      ),
    );
  }
}

/// Runs [onInvoke] unless a text field currently has focus.
///
/// Without this, Space would pause playback mid-word and `/` would navigate
/// away from whatever the user was typing.
///
/// With [yieldToControls], the action also stands aside while any control
/// has keyboard focus: Space has to press the focused button or tick the
/// focused checkbox, and the arrows have to move focus, not seek. A disabled
/// action lets the key fall through to the framework's own shortcuts.
class _GuardedAction<T extends Intent> extends ContextAction<T> {
  _GuardedAction({required this.onInvoke, this.yieldToControls = false});

  final void Function(BuildContext context, [Intent? intent]) onInvoke;
  final bool yieldToControls;

  bool get _blocked => _editing || (yieldToControls && _controlFocused);

  @override
  bool isEnabled(T intent, [BuildContext? context]) => !_blocked;

  @override
  Object? invoke(T intent, [BuildContext? context]) {
    if (context == null || _blocked) return null;
    onInvoke(context, intent);
    return null;
  }

  /// Whether a single control, rather than a whole route or the app, holds
  /// focus. With nothing in particular focused, the primary focus is a
  /// scope node.
  static bool get _controlFocused {
    final focus = FocusManager.instance.primaryFocus;
    return focus != null && focus is! FocusScopeNode;
  }

  static bool get _editing {
    // The focused node lives inside EditableText's own subtree, so the
    // widget at that context is a Focus, not the EditableText itself —
    // looking for the state above it is what actually answers the question.
    final context = FocusManager.instance.primaryFocus?.context;
    return context?.findAncestorStateOfType<EditableTextState>() != null;
  }
}

class _FocusSearch extends Intent {
  const _FocusSearch();
}

class _TogglePlayback extends Intent {
  const _TogglePlayback();
}

class _Seek extends Intent {
  const _Seek({required this.back});

  final bool back;
}

class _Skip extends Intent {
  const _Skip({required this.back});

  final bool back;
}
