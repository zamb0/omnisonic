import 'package:flutter/material.dart';

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
  // Durations
  // ---------------------------------------------------------------------

  /// State changes inside a widget: a pressed state, an icon swap.
  static const Duration fastDuration = Duration(milliseconds: 150);

  /// Page transitions and content swaps — the default reach-for.
  static const Duration quickDuration = Duration(milliseconds: 200);

  /// Motion that covers real distance: a sheet rising, the player sliding up.
  static const Duration normalDuration = Duration(milliseconds: 300);

  /// The upper bound for anything the user is waiting on.
  static const Duration slowDuration = Duration(milliseconds: 500);

  /// Ambient, non-blocking motion: shimmer sweeps, the glass sheen.
  static const Duration loadingDuration = Duration(milliseconds: 1500);

  // ---------------------------------------------------------------------
  // Curves
  // ---------------------------------------------------------------------

  /// Default for anything that both enters and leaves.
  static const Curve standardCurve = Curves.easeInOutCubic;

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
