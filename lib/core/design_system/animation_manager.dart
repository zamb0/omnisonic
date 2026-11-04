import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// The app's motion tokens: how long things take and how they ease.
///
/// There used to be three of these — this one, `AnimationConstants` under
/// `core/constants/`, and a per-platform set in `platform_animations.dart` —
/// with overlapping values under different names, so the same transition was
/// 200ms or 300ms depending on which file the author reached for. They are
/// merged here, in the design system, next to the colour and spacing tokens.
///
/// These are values, not behaviour. Anything that has to *decide* something
/// (reduced motion, sheet vs dialog presentation) lives in
/// `core/utils/animation_utils.dart` and reads from here.
class AnimationManager {
  const AnimationManager._();

  // ---------------------------------------------------------------------
  // Durations (docs/design-system.md §7)
  // ---------------------------------------------------------------------

  /// A press: the 0.97 scale-down. Must feel immediate.
  static const Duration instantDuration = Duration(milliseconds: 100);

  /// State changes inside a widget: hover, an icon swap.
  static const Duration fastDuration = Duration(milliseconds: 150);

  /// Page transitions and content swaps — the default reach-for.
  static const Duration quickDuration = Duration(milliseconds: 200);

  /// Motion that covers real distance: a sheet rising, the player sliding up.
  static const Duration normalDuration = Duration(milliseconds: 300);

  /// Opening Now Playing, the cover Hero.
  static const Duration emphasisDuration = Duration(milliseconds: 450);

  /// Cross-fade when the artwork tint changes.
  static const Duration tintDuration = Duration(milliseconds: 600);

  /// Ambient, non-blocking motion: shimmer sweeps, the glass sheen.
  static const Duration loadingDuration = Duration(milliseconds: 1500);

  /// Exits run at 70 % of the matching enter, so things leave faster than
  /// they arrive.
  static Duration exitOf(Duration enter) =>
      Duration(microseconds: (enter.inMicroseconds * 0.7).round());

  /// One bar of the "now playing" equalizer. Out of phase on purpose: three
  /// bars on the same period read as a single pulsing block.
  static Duration equalizerBarDuration(int index) =>
      Duration(milliseconds: 320 + index * 90);

  // ---------------------------------------------------------------------
  // Stagger
  // ---------------------------------------------------------------------

  /// Gap between consecutive items entering a grid or list.
  static const Duration staggerStep = Duration(milliseconds: 40);

  /// Only the first items stagger; anything further down is off-screen or
  /// would make the entrance drag on.
  static const int staggerMaxItems = 12;

  /// The delay before item [index] enters. Items past [staggerMaxItems]
  /// enter with the last one, not later.
  static Duration staggered(int index) {
    final i = index.clamp(0, staggerMaxItems - 1);
    return staggerStep * i;
  }

  // ---------------------------------------------------------------------
  // Curves
  // ---------------------------------------------------------------------

  /// Default for anything that both enters and leaves.
  static const Curve standardCurve = Curves.easeInOutCubic;

  /// Things arriving: decelerate into place.
  static const Curve enterCurve = Curves.easeOutCubic;

  /// Things leaving: accelerate away.
  static const Curve exitCurve = Curves.easeInCubic;

  /// Press release and toggles: mass 1, stiffness 380, damping 30.
  static const Curve springCurve = SpringCurve();

  /// For short movements where the ease-in would not be perceptible anyway.
  static const Curve fastCurve = Curves.easeOutQuart;

  /// Long movements, where a gentler settle reads as less abrupt.
  static const Curve slowCurve = Curves.easeInOutQuint;

  /// Dialogs, which appear in place rather than travelling.
  static const Curve dialogCurve = Curves.easeOutCubic;

  /// Bottom sheets, which decelerate into their resting position.
  static const Curve sheetCurve = fastCurve;

  /// Looping ambient motion, which has no start or end to emphasise.
  static const Curve loadingCurve = Curves.easeInOut;
}

/// A spring settling from 0 to 1 (mass 1, stiffness 380, damping 30: slightly
/// underdamped, so it overshoots by ~2 % like a real press release).
///
/// A [Curve] is normalised to t in [0, 1], so the physical settle time is
/// mapped onto it: the spring is sampled over [_settleSeconds].
class SpringCurve extends Curve {
  const SpringCurve();

  static const double _settleSeconds = 0.45;
  static final SpringDescription _description = SpringDescription(
    mass: 1,
    stiffness: 380,
    damping: 30,
  );
  static final SpringSimulation _simulation = SpringSimulation(
    _description,
    0,
    1,
    0,
  );

  @override
  double transformInternal(double t) => _simulation.x(t * _settleSeconds);
}
