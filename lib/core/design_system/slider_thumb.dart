import 'package:flutter/material.dart';

/// The generic slider's thumb (§9.3): 14 px at rest, growing to 18 px while
/// it is pressed or dragged. [SliderComponentShape.paint] gets the press
/// animation as `activationAnimation`, so the growth follows the finger
/// without any state of its own.
class GrowingThumbShape extends SliderComponentShape {
  const GrowingThumbShape();

  /// Radii: 7 -> diameter 14, 9 -> diameter 18.
  static const double restRadius = 7;
  static const double pressedRadius = 9;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(pressedRadius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final radius =
        restRadius + (pressedRadius - restRadius) * activationAnimation.value;
    context.canvas.drawCircle(
      center,
      radius,
      Paint()..color = sliderTheme.thumbColor ?? const Color(0xFF000000),
    );
  }
}
