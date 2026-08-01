import 'package:flutter/material.dart';

/// Standard animation durations and curves used across the app.
///
/// This used to be backed by an animation-coordination/performance-monitoring
/// subsystem (queueing, priority levels, adaptive scaling) that had no real
/// callers anywhere in the app — only these constants and
/// [OmnisonicAnimationExtension] were ever consumed. Trimmed to just that.
class AnimationManager {
  // Durations
  static const Duration fastDuration = Duration(milliseconds: 150);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);
  static const Duration extraSlowDuration = Duration(milliseconds: 800);

  // Curves
  static const Curve standardCurve = Curves.easeInOutCubic;
  static const Curve fastCurve = Curves.easeOutQuart;
  static const Curve slowCurve = Curves.easeInOutQuint;
}

/// Theme extension exposing [AnimationManager]'s defaults, so they can be
/// looked up via `Theme.of(context).extension<OmnisonicAnimationExtension>()`
/// and overridden per-theme if a future theme ever needs different pacing.
class OmnisonicAnimationExtension
    extends ThemeExtension<OmnisonicAnimationExtension> {
  final Duration fastDuration;
  final Duration normalDuration;
  final Duration slowDuration;
  final Curve standardCurve;
  final Curve fastCurve;
  final Curve slowCurve;

  const OmnisonicAnimationExtension({
    this.fastDuration = AnimationManager.fastDuration,
    this.normalDuration = AnimationManager.normalDuration,
    this.slowDuration = AnimationManager.slowDuration,
    this.standardCurve = AnimationManager.standardCurve,
    this.fastCurve = AnimationManager.fastCurve,
    this.slowCurve = AnimationManager.slowCurve,
  });

  @override
  ThemeExtension<OmnisonicAnimationExtension> copyWith({
    Duration? fastDuration,
    Duration? normalDuration,
    Duration? slowDuration,
    Curve? standardCurve,
    Curve? fastCurve,
    Curve? slowCurve,
  }) {
    return OmnisonicAnimationExtension(
      fastDuration: fastDuration ?? this.fastDuration,
      normalDuration: normalDuration ?? this.normalDuration,
      slowDuration: slowDuration ?? this.slowDuration,
      standardCurve: standardCurve ?? this.standardCurve,
      fastCurve: fastCurve ?? this.fastCurve,
      slowCurve: slowCurve ?? this.slowCurve,
    );
  }

  @override
  ThemeExtension<OmnisonicAnimationExtension> lerp(
    ThemeExtension<OmnisonicAnimationExtension>? other,
    double t,
  ) {
    if (other is! OmnisonicAnimationExtension) {
      return this;
    }

    return OmnisonicAnimationExtension(
      fastDuration: Duration(
        milliseconds:
            (fastDuration.inMilliseconds * (1 - t) +
                    other.fastDuration.inMilliseconds * t)
                .round(),
      ),
      normalDuration: Duration(
        milliseconds:
            (normalDuration.inMilliseconds * (1 - t) +
                    other.normalDuration.inMilliseconds * t)
                .round(),
      ),
      slowDuration: Duration(
        milliseconds:
            (slowDuration.inMilliseconds * (1 - t) +
                    other.slowDuration.inMilliseconds * t)
                .round(),
      ),
      standardCurve: t < 0.5 ? standardCurve : other.standardCurve,
      fastCurve: t < 0.5 ? fastCurve : other.fastCurve,
      slowCurve: t < 0.5 ? slowCurve : other.slowCurve,
    );
  }
}
