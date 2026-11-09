import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// Three bars that say "this is the track playing", in a track row, the
/// resume card and the mini player (docs/design-system.md §7, §9.5).
///
/// - [playing]: the bars loop out of phase, about 900 ms.
/// - paused, or reduce motion: the bars hold still at mid height.
///
/// Announced as "Now playing" so the state does not rely on colour or
/// motion; a parent that already says it can [excludeSemantics].
class NowPlayingEqualizer extends StatefulWidget {
  const NowPlayingEqualizer({
    super.key,
    required this.playing,
    this.color,
    this.excludeSemantics = false,
  });

  /// Bar count and geometry.
  static const int barCount = 3;
  static const double barWidth = 3;
  static const double barGap = 2;
  static const double minBarHeight = 4;
  static const double maxBarHeight = 14;

  final bool playing;

  /// Bar colour; defaults to the accent.
  final Color? color;

  final bool excludeSemantics;

  @override
  State<NowPlayingEqualizer> createState() => _NowPlayingEqualizerState();
}

class _NowPlayingEqualizerState extends State<NowPlayingEqualizer>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers = List.generate(
    NowPlayingEqualizer.barCount,
    (i) => AnimationController(
      duration: AnimationManager.equalizerBarDuration(i),
      vsync: this,
      value: 0.5,
    ),
  );

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(NowPlayingEqualizer old) {
    super.didUpdateWidget(old);
    if (old.playing != widget.playing) _sync();
  }

  /// Loops while playing; otherwise stops and settles at mid height.
  void _sync() {
    for (final controller in _controllers) {
      if (widget.playing && !_reduceMotion) {
        if (!controller.isAnimating) controller.repeat(reverse: true);
      } else {
        controller
          ..stop()
          ..value = 0.5;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    const range =
        NowPlayingEqualizer.maxBarHeight - NowPlayingEqualizer.minBarHeight;

    // Its own layer: the bars move on every frame while playing, and without
    // the boundary each frame repainted whatever holds them — the mini
    // player's whole glass pane, or the track list around a live row.
    final bars = RepaintBoundary(
      child: SizedBox(
        width:
            NowPlayingEqualizer.barCount * NowPlayingEqualizer.barWidth +
            (NowPlayingEqualizer.barCount - 1) * NowPlayingEqualizer.barGap,
        height: NowPlayingEqualizer.maxBarHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < NowPlayingEqualizer.barCount; i++) ...[
              if (i > 0) const SizedBox(width: NowPlayingEqualizer.barGap),
              AnimatedBuilder(
                animation: _controllers[i],
                builder: (context, _) => DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(OmnisonicRadius.xs / 4),
                  ),
                  child: SizedBox(
                    width: NowPlayingEqualizer.barWidth,
                    height:
                        NowPlayingEqualizer.minBarHeight +
                        _controllers[i].value * range,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (widget.excludeSemantics) return ExcludeSemantics(child: bars);
    return Semantics(
      label: 'Now playing',
      child: ExcludeSemantics(child: bars),
    );
  }
}
