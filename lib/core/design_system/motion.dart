import 'package:flutter/material.dart';

import '../utils/animation_utils.dart';
import 'animation_manager.dart';

/// Scales [child] to 0.97 while a pointer is down, then springs back.
///
/// It listens to raw pointer events rather than owning a gesture, so it
/// never competes with the `InkWell`/`GestureDetector` inside it. Only a
/// transform changes: no layout shift. Snaps (no animation) with reduce
/// motion.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = pressedScale,
  });

  /// Pressed scale from the spec (§7).
  static const double pressedScale = 0.97;

  final Widget child;

  /// When false the child is returned untouched (disabled controls).
  final bool enabled;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _set(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final duration = AnimationUtils.adjustedDuration(
      context,
      _pressed
          ? AnimationManager.instantDuration
          : AnimationManager.quickDuration,
    );
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: duration,
        curve: _pressed
            ? AnimationManager.enterCurve
            : AnimationManager.springCurve,
        child: widget.child,
      ),
    );
  }
}

/// Fades [child] in and lifts it 8 px, delayed by [index] steps
/// ([AnimationManager.staggered]). Plays once, on first build — for grids
/// and lists on first load. Shows the child immediately with reduce motion.
class Staggered extends StatefulWidget {
  const Staggered({super.key, required this.index, required this.child});

  /// Distance the child travels while entering.
  static const double rise = 8;

  final int index;
  final Widget child;

  @override
  State<Staggered> createState() => _StaggeredState();
}

class _StaggeredState extends State<Staggered>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _curve;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) return;
    final delay = AnimationManager.staggered(widget.index);
    final total = delay + AnimationManager.quickDuration;
    final controller = AnimationController(vsync: this, duration: total);
    _curve = CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: AnimationManager.enterCurve,
      ),
    );
    _controller = controller..forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = _curve;
    if (curve == null) return widget.child;
    return AnimatedBuilder(
      animation: curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: curve.value,
        child: Transform.translate(
          offset: Offset(0, (1 - curve.value) * Staggered.rise),
          child: child,
        ),
      ),
    );
  }
}
