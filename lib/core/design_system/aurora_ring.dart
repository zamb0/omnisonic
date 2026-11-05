import 'package:flutter/material.dart';

import 'brand.dart';

/// A 2 px ring in the `auroraSoft` gradient, drawn to fill its box as an
/// oval: round an artist portrait on hover, haloing the icon disc of an
/// empty state. Decorative.
class AuroraRing extends StatelessWidget {
  const AuroraRing({super.key, this.width = defaultWidth});

  static const double defaultWidth = 2;

  final double width;

  @override
  Widget build(BuildContext context) {
    final gradient = OmnisonicBrand.of(context).auroraSoft;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(painter: AuroraRingPainter(gradient, width)),
      ),
    );
  }
}

/// Paints the ring of [AuroraRing]; public so a caller that already has a
/// `CustomPaint` slot (the artist card) can reuse it.
class AuroraRingPainter extends CustomPainter {
  const AuroraRingPainter(
    this.gradient, [
    this.width = AuroraRing.defaultWidth,
  ]);

  final LinearGradient gradient;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawOval(
      rect.deflate(width / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = gradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(AuroraRingPainter old) =>
      old.gradient != gradient || old.width != width;
}
