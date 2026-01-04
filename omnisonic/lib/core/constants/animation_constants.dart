import 'package:flutter/material.dart';

/// Animation constants for consistent UI animations throughout the app
class AnimationConstants {
  // Durations
  static const Duration quickAnimation = Duration(milliseconds: 200);
  static const Duration standardAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  static const Duration loadingAnimation = Duration(milliseconds: 1500);
  
  // Curves
  static const Curve standardCurve = Curves.easeOut;
  static const Curve loadingCurve = Curves.easeInOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve springCurve = Curves.elasticOut;
  
  // Specific animation curves for different UI elements
  static const Curve dialogCurve = Curves.easeOutCubic;
  static const Curve bottomSheetCurve = Curves.easeOutQuart;
  static const Curve playerCurve = Curves.easeInOutCubic;
}