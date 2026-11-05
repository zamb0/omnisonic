import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/animation_utils.dart';
import '../utils/formatters.dart';
import 'animation_manager.dart';
import 'brand.dart';
import 'spacing.dart';

/// The seek bar of the player (docs/design-system.md §9.3, §9.6).
///
/// A 4 px track that grows to 6 px, with a 14 px thumb appearing, while the
/// pointer is over it, it is dragged or it has keyboard focus. The played
/// part is the Aurora gradient (revealed, not stretched: it always spans the
/// whole track); an optional [buffered] fraction sits behind it in
/// `onSurface` at 20 %.
///
/// Dragging shows the position under the finger through [onChanged] and
/// commits **once**, on release, through [onSeek] — a drag costs one seek,
/// not one per pointer move. A tap seeks there. The arrow keys seek ±5 s, and
/// screen readers get a slider whose value reads as "1:23 of 3:24" with
/// increase/decrease actions.
class AuroraProgress extends StatefulWidget {
  const AuroraProgress({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.onChanged,
    this.buffered = 0,
    this.semanticLabel = 'Seek',
  });

  /// How far arrow keys and screen-reader actions move.
  static const Duration step = Duration(seconds: 5);

  static const double trackHeight = 4;
  static const double trackHeightActive = 6;
  static const double thumbDiameter = 14;

  /// Height of the touch/hit area; the visible track is centred in it.
  static const double hitHeight = 28;

  final Duration position;
  final Duration duration;

  /// Called once with the new position when a seek is committed: a tap, the
  /// release of a drag, an arrow key, or an accessibility action.
  final ValueChanged<Duration> onSeek;

  /// Called while dragging with the position under the finger (null when the
  /// drag ends), so the elapsed-time label can follow it.
  final ValueChanged<Duration?>? onChanged;

  /// Fraction (0–1) already buffered ahead of the position.
  final double buffered;

  final String semanticLabel;

  @override
  State<AuroraProgress> createState() => _AuroraProgressState();
}

class _AuroraProgressState extends State<AuroraProgress> {
  bool _hovering = false;
  bool _focused = false;
  double? _drag;

  bool get _enabled => widget.duration > Duration.zero;
  bool get _active => _hovering || _focused || _drag != null;

  double get _fraction {
    if (_drag != null) return _drag!;
    if (!_enabled) return 0;
    return (widget.position.inMicroseconds / widget.duration.inMicroseconds)
        .clamp(0.0, 1.0);
  }

  Duration _at(double fraction) => Duration(
    microseconds: (widget.duration.inMicroseconds * fraction.clamp(0.0, 1.0))
        .round(),
  );

  double _fractionFor(Offset local, double width) =>
      width <= 0 ? 0 : (local.dx / width).clamp(0.0, 1.0);

  Duration _clamped(Duration value) => value < Duration.zero
      ? Duration.zero
      : (value > widget.duration ? widget.duration : value);

  String _spoken(Duration at) =>
      '${formatDuration(at)} of ${formatDuration(widget.duration)}';

  void _seekBy(Duration delta) {
    if (!_enabled) return;
    widget.onSeek(_clamped(widget.position + delta));
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || !_enabled) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp) {
      _seekBy(AuroraProgress.step);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowDown) {
      _seekBy(-AuroraProgress.step);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = OmnisonicBrand.of(context);
    final shown = _at(_fraction);

    return Semantics(
      slider: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      value: _spoken(shown),
      increasedValue: _spoken(_clamped(shown + AuroraProgress.step)),
      decreasedValue: _spoken(_clamped(shown - AuroraProgress.step)),
      onIncrease: _enabled ? () => _seekBy(AuroraProgress.step) : null,
      onDecrease: _enabled ? () => _seekBy(-AuroraProgress.step) : null,
      excludeSemantics: true,
      child: Focus(
        onKeyEvent: _onKey,
        onFocusChange: (value) => setState(() => _focused = value),
        child: MouseRegion(
          cursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: _enabled
                    ? (d) => widget.onSeek(
                        _at(_fractionFor(d.localPosition, width)),
                      )
                    : null,
                onHorizontalDragStart: _enabled
                    ? (d) {
                        final f = _fractionFor(d.localPosition, width);
                        setState(() => _drag = f);
                        widget.onChanged?.call(_at(f));
                      }
                    : null,
                onHorizontalDragUpdate: _enabled
                    ? (d) {
                        final f = _fractionFor(d.localPosition, width);
                        setState(() => _drag = f);
                        widget.onChanged?.call(_at(f));
                      }
                    : null,
                onHorizontalDragEnd: _enabled
                    ? (_) {
                        final f = _drag;
                        setState(() => _drag = null);
                        widget.onChanged?.call(null);
                        if (f != null) widget.onSeek(_at(f));
                      }
                    : null,
                onHorizontalDragCancel: () {
                  if (_drag == null) return;
                  setState(() => _drag = null);
                  widget.onChanged?.call(null);
                },
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: _active ? 1 : 0),
                  duration: AnimationUtils.adjustedDuration(
                    context,
                    AnimationManager.fastDuration,
                  ),
                  curve: AnimationManager.standardCurve,
                  builder: (context, emphasis, _) => CustomPaint(
                    size: Size(width, AuroraProgress.hitHeight),
                    painter: _ProgressPainter(
                      fraction: _fraction,
                      buffered: widget.buffered.clamp(0.0, 1.0),
                      emphasis: emphasis,
                      gradient: brand.aurora,
                      track: scheme.onSurface.withValues(alpha: 0.14),
                      bufferColor: scheme.onSurface.withValues(alpha: 0.20),
                      thumb: scheme.onSurface,
                      halo: brand.auroraSoft.colors[1],
                      showHalo: _focused,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter({
    required this.fraction,
    required this.buffered,
    required this.emphasis,
    required this.gradient,
    required this.track,
    required this.bufferColor,
    required this.thumb,
    required this.halo,
    required this.showHalo,
  });

  final double fraction;
  final double buffered;
  final double emphasis;
  final LinearGradient gradient;
  final Color track;
  final Color bufferColor;
  final Color thumb;
  final Color halo;
  final bool showHalo;

  @override
  void paint(Canvas canvas, Size size) {
    final height =
        AuroraProgress.trackHeight +
        (AuroraProgress.trackHeightActive - AuroraProgress.trackHeight) *
            emphasis;
    final top = (size.height - height) / 2;
    final radius = Radius.circular(OmnisonicRadius.xs);
    RRect bar(double fractionOfWidth) => RRect.fromLTRBR(
      0,
      top,
      size.width * fractionOfWidth,
      top + height,
      radius,
    );

    canvas.drawRRect(bar(1), Paint()..color = track);
    if (buffered > 0) {
      canvas.drawRRect(bar(buffered), Paint()..color = bufferColor);
    }
    if (fraction > 0) {
      // The gradient spans the whole track and is revealed, so a short
      // played part is violet and only a long one reaches coral.
      canvas.drawRRect(
        bar(fraction),
        Paint()
          ..shader = gradient.createShader(
            Rect.fromLTWH(0, top, size.width, height),
          ),
      );
    }

    final thumbRadius = AuroraProgress.thumbDiameter / 2 * emphasis;
    if (thumbRadius > 0.5) {
      final cx = (size.width * fraction).clamp(
        thumbRadius,
        size.width - thumbRadius,
      );
      final centre = Offset(cx, size.height / 2);
      if (showHalo) {
        canvas.drawCircle(centre, thumbRadius + 5, Paint()..color = halo);
      }
      canvas.drawCircle(centre, thumbRadius, Paint()..color = thumb);
    }
  }

  @override
  bool shouldRepaint(_ProgressPainter old) =>
      old.fraction != fraction ||
      old.buffered != buffered ||
      old.emphasis != emphasis ||
      old.gradient != gradient ||
      old.track != track ||
      old.showHalo != showHalo ||
      old.thumb != thumb;
}

/// A non-interactive 2 px Aurora progress line, for the bottom edge of the
/// mini player. Shows the same revealed gradient as [AuroraProgress].
class AuroraProgressLine extends StatelessWidget {
  const AuroraProgressLine({
    super.key,
    required this.fraction,
    this.height = 2,
  });

  /// 0–1.
  final double fraction;
  final double height;

  @override
  Widget build(BuildContext context) {
    final gradient = OmnisonicBrand.of(context).aurora;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _LinePainter(fraction.clamp(0.0, 1.0), gradient),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.fraction, this.gradient);

  final double fraction;
  final LinearGradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    if (fraction <= 0) return;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * fraction, size.height),
      Paint()..shader = gradient.createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.fraction != fraction || old.gradient != gradient;
}
