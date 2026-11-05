import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'brand.dart';

/// Three soft Aurora blobs (violet, magenta, coral) as a background
/// (docs/design-system.md §2.4): Now Playing over the cover tint, and the
/// fallback for screens that have no artwork to tint them.
///
/// With [drift] the blobs wander slowly (one lap per [driftPeriod]); with
/// reduce motion, or by default, they sit still. Purely decorative: it
/// ignores pointers and is excluded from semantics.
class AuroraMesh extends StatefulWidget {
  const AuroraMesh({
    super.key,
    this.opacity = 1,
    this.drift = false,
    this.driftPeriod = const Duration(seconds: 20),
    this.brand,
  });

  /// Scales the blobs' own alpha (35 % dark, 22 % light): 1 keeps the brand
  /// values, less fades them.
  final double opacity;

  /// Whether the blobs slowly move.
  final bool drift;

  final Duration driftPeriod;

  /// Overrides the ambient [OmnisonicBrand], e.g. the dark one on a surface
  /// that is always dark.
  final OmnisonicBrand? brand;

  /// How far a blob wanders from its base position, in alignment units.
  static const double driftRadius = 0.12;

  @override
  State<AuroraMesh> createState() => _AuroraMeshState();
}

class _AuroraMeshState extends State<AuroraMesh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.driftPeriod,
  );

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(AuroraMesh old) {
    super.didUpdateWidget(old);
    _controller.duration = widget.driftPeriod;
    _sync();
  }

  void _sync() {
    final moving = widget.drift && !_reduceMotion;
    if (moving) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = widget.brand ?? OmnisonicBrand.of(context);
    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value * 2 * math.pi;
              return Stack(
                fit: StackFit.expand,
                children: [
                  for (var i = 0; i < brand.auroraMesh.length; i++)
                    _blob(brand.auroraMesh[i], i, t),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _blob(RadialGradient blob, int index, double t) {
    // Each blob orbits on its own phase, so they never line up.
    final phase = index * 2 * math.pi / 3;
    final base = blob.center as Alignment;
    final center = Alignment(
      base.x + math.cos(t + phase) * AuroraMesh.driftRadius,
      base.y + math.sin(t + phase) * AuroraMesh.driftRadius,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: center,
          radius: blob.radius,
          colors: [
            for (final c in blob.colors)
              c.withValues(alpha: c.a * widget.opacity),
          ],
        ),
      ),
    );
  }
}
