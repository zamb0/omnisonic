import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../features/playback/presentation/viewmodels/playback_view_model.dart';
import 'app_router.dart';

/// Keyboard shortcuts for the whole app.
///
/// The desktop top bar has advertised `⌘K` since the redesign landed, and
/// nothing implemented it — there was no `Shortcuts`, `Actions` or
/// `SingleActivator` anywhere in the codebase. Desktop is a first-class
/// target here, so the affordance is now real rather than removed.
///
/// Everything is suppressed while a text field has focus, so typing "k" into
/// the search box does not seek, pause, or navigate.
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
            onInvoke: (context, [intent]) =>
                GoRouter.of(context).go(AppRouter.search),
          ),
          _TogglePlayback: _GuardedAction<_TogglePlayback>(
            onInvoke: (context, [intent]) => playback().togglePlayPause(),
          ),
          _Seek: _GuardedAction<_Seek>(
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
class _GuardedAction<T extends Intent> extends ContextAction<T> {
  _GuardedAction({required this.onInvoke});

  final void Function(BuildContext context, [Intent? intent]) onInvoke;

  @override
  bool isEnabled(T intent, [BuildContext? context]) => !_editing;

  @override
  Object? invoke(T intent, [BuildContext? context]) {
    if (context == null || _editing) return null;
    onInvoke(context, intent);
    return null;
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
