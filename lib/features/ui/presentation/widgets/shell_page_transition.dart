import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/design_system/design_system.dart';

/// Coordinates the fades of the pages inside the shell, so a page change is a
/// cross-fade rather than a double exposure.
///
/// Shell pages have transparent scaffolds, so the art wash shows through
/// them. A page route only animates itself, though: the page it replaces
/// stays fully painted underneath until the new one has finished. For a push
/// the page below at least gets a secondary animation, but `context.go` —
/// every tab switch — removes the old page without animating it at all. So a
/// fade showed both pages' content on top of each other and then cut the old
/// one away.
///
/// The scope tracks the route animation currently running, and every
/// [ShellPageFade] that is not that route fades out against it: the page
/// being left on a push or a `go`, the page being revealed (fading back in)
/// on a pop.
class ShellTransitionScope extends StatefulWidget {
  const ShellTransitionScope({super.key, required this.child});

  final Widget child;

  @override
  State<ShellTransitionScope> createState() => _ShellTransitionScopeState();
}

class _ShellTransitionScopeState extends State<ShellTransitionScope> {
  final _active = _ActiveTransition();

  @override
  void dispose() {
    _active.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ShellTransitionMarker(active: _active, child: widget.child);
}

/// The route animation that is running, if any.
class _ActiveTransition extends ChangeNotifier {
  Animation<double>? _animation;
  Animation<double>? get animation => _animation;

  void activate(Animation<double> animation) {
    if (identical(_animation, animation)) return;
    _animation = animation;
    _notifySafely();
  }

  void deactivate(Animation<double> animation) {
    if (!identical(_animation, animation)) return;
    _animation = null;
    _notifySafely();
  }

  /// Route animations start while the new page is being built; telling the
  /// other pages about it then would mark them dirty mid-build. Those
  /// changes wait for the end of the frame — one frame late, at the very
  /// start of a fade, where nothing can be seen yet.
  void _notifySafely() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }
}

class _ShellTransitionMarker extends InheritedWidget {
  const _ShellTransitionMarker({required this.active, required super.child});

  final _ActiveTransition active;

  @override
  bool updateShouldNotify(_ShellTransitionMarker oldWidget) =>
      !identical(oldWidget.active, active);
}

/// A shell page's own fade, plus the fade-out it owes to whichever other
/// page is animating in front of it.
class ShellPageFade extends StatefulWidget {
  const ShellPageFade({
    super.key,
    required this.animation,
    required this.child,
  });

  /// The page route's own animation.
  final Animation<double> animation;

  final Widget child;

  @override
  State<ShellPageFade> createState() => _ShellPageFadeState();
}

class _ShellPageFadeState extends State<ShellPageFade> {
  _ActiveTransition? _scope;

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_onStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = context
        .dependOnInheritedWidgetOfExactType<_ShellTransitionMarker>()
        ?.active;
    if (!identical(scope, _scope)) {
      _scope = scope;
      // A push starts its animation before the page is first built, so the
      // status listener has already missed the change to `forward`.
      _onStatus(widget.animation.status);
    }
  }

  @override
  void didUpdateWidget(ShellPageFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.animation, widget.animation)) {
      oldWidget.animation.removeStatusListener(_onStatus);
      _scope?.deactivate(oldWidget.animation);
      widget.animation.addStatusListener(_onStatus);
      _onStatus(widget.animation.status);
    }
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatus);
    _scope?.deactivate(widget.animation);
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    final scope = _scope;
    if (scope == null) return;
    if (status.isAnimating) {
      scope.activate(widget.animation);
    } else {
      scope.deactivate(widget.animation);
    }
  }

  static double _curve(double t) =>
      AnimationManager.standardCurve.transform(t.clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final scope = _scope;
    if (scope == null) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: widget.animation,
          curve: AnimationManager.standardCurve,
        ),
        child: widget.child,
      );
    }

    return ListenableBuilder(
      listenable: scope,
      builder: (context, child) {
        final other = scope.animation;
        final ownsTransition =
            other == null || identical(other, widget.animation);
        return AnimatedBuilder(
          animation: ownsTransition
              ? widget.animation
              : Listenable.merge([widget.animation, other]),
          builder: (context, child) {
            var opacity = _curve(widget.animation.value);
            if (!ownsTransition) opacity *= 1 - _curve(other.value);
            return Opacity(opacity: opacity, child: child);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
