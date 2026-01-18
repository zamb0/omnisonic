import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'platform_optimizations.dart';

/// Platform-specific animation styles and configurations
class PlatformAnimations {
  static const PlatformAnimations _instance = PlatformAnimations._internal();
  factory PlatformAnimations() => _instance;
  const PlatformAnimations._internal();

  /// Get platform-appropriate page transition
  PageTransitionsBuilder get pageTransitionBuilder {
    switch (PlatformOptimizations().currentPlatform) {
      case PlatformType.ios:
        return const CupertinoPageTransitionsBuilder();
      case PlatformType.android:
        return const FadeUpwardsPageTransitionsBuilder();
      case PlatformType.web:
        return const FadeUpwardsPageTransitionsBuilder();
      case PlatformType.macos:
        return const CupertinoPageTransitionsBuilder();
      case PlatformType.windows:
      case PlatformType.linux:
        return const OpenUpwardsPageTransitionsBuilder();
      case PlatformType.unknown:
        return const FadeUpwardsPageTransitionsBuilder();
    }
  }

  /// Get platform-appropriate animation curves
  PlatformAnimationCurves get curves => PlatformAnimationCurves();

  /// Get platform-appropriate animation durations
  PlatformAnimationDurations get durations => PlatformAnimationDurations();

  /// Create platform-appropriate slide transition
  Widget slideTransition({
    required Widget child,
    required Animation<double> animation,
    SlideDirection direction = SlideDirection.fromRight,
  }) {
    Offset begin;
    switch (direction) {
      case SlideDirection.fromLeft:
        begin = const Offset(-1.0, 0.0);
        break;
      case SlideDirection.fromRight:
        begin = const Offset(1.0, 0.0);
        break;
      case SlideDirection.fromTop:
        begin = const Offset(0.0, -1.0);
        break;
      case SlideDirection.fromBottom:
        begin = const Offset(0.0, 1.0);
        break;
    }

    final curve = _getPlatformSlideCurve();
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve,
      )),
      child: child,
    );
  }

  /// Create platform-appropriate fade transition
  Widget fadeTransition({
    required Widget child,
    required Animation<double> animation,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: _getPlatformFadeCurve(),
      ),
      child: child,
    );
  }

  /// Create platform-appropriate scale transition
  Widget scaleTransition({
    required Widget child,
    required Animation<double> animation,
    double beginScale = 0.0,
  }) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: beginScale,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: _getPlatformScaleCurve(),
      )),
      child: child,
    );
  }

  /// Create platform-appropriate rotation transition
  Widget rotationTransition({
    required Widget child,
    required Animation<double> animation,
    double turns = 0.25,
  }) {
    return RotationTransition(
      turns: Tween<double>(
        begin: turns,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: _getPlatformRotationCurve(),
      )),
      child: child,
    );
  }

  Curve _getPlatformSlideCurve() {
    switch (PlatformOptimizations().currentPlatform) {
      case PlatformType.ios:
        return Curves.easeOutCubic;
      case PlatformType.android:
        return Curves.fastOutSlowIn;
      case PlatformType.web:
        return Curves.easeInOutQuart;
      case PlatformType.macos:
        return Curves.easeOutExpo;
      case PlatformType.windows:
      case PlatformType.linux:
        return Curves.easeOutQuint;
      case PlatformType.unknown:
        return Curves.easeOutCubic;
    }
  }

  Curve _getPlatformFadeCurve() {
    switch (PlatformOptimizations().currentPlatform) {
      case PlatformType.ios:
        return Curves.easeInOut;
      case PlatformType.android:
        return Curves.fastOutSlowIn;
      case PlatformType.web:
        return Curves.easeInOutCubic;
      case PlatformType.macos:
        return Curves.easeInOutExpo;
      case PlatformType.windows:
      case PlatformType.linux:
        return Curves.easeInOutQuart;
      case PlatformType.unknown:
        return Curves.easeInOut;
    }
  }

  Curve _getPlatformScaleCurve() {
    switch (PlatformOptimizations().currentPlatform) {
      case PlatformType.ios:
        return Curves.elasticOut;
      case PlatformType.android:
        return Curves.fastOutSlowIn;
      case PlatformType.web:
        return Curves.easeOutBack;
      case PlatformType.macos:
        return Curves.easeOutExpo;
      case PlatformType.windows:
      case PlatformType.linux:
        return Curves.easeOutQuint;
      case PlatformType.unknown:
        return Curves.easeOutBack;
    }
  }

  Curve _getPlatformRotationCurve() {
    switch (PlatformOptimizations().currentPlatform) {
      case PlatformType.ios:
        return Curves.easeOutCubic;
      case PlatformType.android:
        return Curves.fastOutSlowIn;
      case PlatformType.web:
        return Curves.easeInOutQuart;
      case PlatformType.macos:
        return Curves.easeOutExpo;
      case PlatformType.windows:
      case PlatformType.linux:
        return Curves.easeOutQuint;
      case PlatformType.unknown:
        return Curves.easeOutCubic;
    }
  }
}

/// Platform-specific animation curves
class PlatformAnimationCurves {
  Curve get standard {
    switch (PlatformOptimizations().currentPlatform) {
      case PlatformType.ios:
        return Curves.easeInOut;
      case PlatformType.android:
        return Curves.fastOutSlowIn;
      case PlatformType.web:
        return Curves.easeInOutCubic;
      case PlatformType.macos:
        return Curves.easeInOutExpo;
      case PlatformType.windows:
      case PlatformType.linux:
        return Curves.easeInOutQuart;
      case PlatformType.unknown:
        return Curves.easeInOut;
    }
  }

  Curve get emphasized {
    switch (PlatformOptimizations().currentPlatform) {
      case PlatformType.ios:
        return Curves.elasticOut;
      case PlatformType.android:
        return Curves.fastOutSlowIn;
      case PlatformType.web:
        return Curves.easeOutBack;
      case PlatformType.macos:
        return Curves.easeOutExpo;
      case PlatformType.windows:
      case PlatformType.linux:
        return Curves.easeOutQuint;
      case PlatformType.unknown:
        return Curves.easeOutBack;
    }
  }

  Curve get decelerated {
    switch (PlatformOptimizations().currentPlatform) {
      case PlatformType.ios:
        return Curves.easeOut;
      case PlatformType.android:
        return Curves.fastOutSlowIn;
      case PlatformType.web:
        return Curves.easeOutQuart;
      case PlatformType.macos:
        return Curves.easeOutExpo;
      case PlatformType.windows:
      case PlatformType.linux:
        return Curves.easeOutQuint;
      case PlatformType.unknown:
        return Curves.easeOut;
    }
  }

  Curve get accelerated {
    switch (PlatformOptimizations().currentPlatform) {
      case PlatformType.ios:
        return Curves.easeIn;
      case PlatformType.android:
        return Curves.linearToEaseOut;
      case PlatformType.web:
        return Curves.easeInQuart;
      case PlatformType.macos:
        return Curves.easeInExpo;
      case PlatformType.windows:
      case PlatformType.linux:
        return Curves.easeInQuint;
      case PlatformType.unknown:
        return Curves.easeIn;
    }
  }
}

/// Platform-specific animation durations
class PlatformAnimationDurations {
  Duration get short {
    final base = const Duration(milliseconds: 150);
    final multiplier = PlatformOptimizations().animationDurationMultiplier;
    return Duration(milliseconds: (base.inMilliseconds * multiplier).round());
  }

  Duration get medium {
    final base = const Duration(milliseconds: 300);
    final multiplier = PlatformOptimizations().animationDurationMultiplier;
    return Duration(milliseconds: (base.inMilliseconds * multiplier).round());
  }

  Duration get long {
    final base = const Duration(milliseconds: 500);
    final multiplier = PlatformOptimizations().animationDurationMultiplier;
    return Duration(milliseconds: (base.inMilliseconds * multiplier).round());
  }

  Duration get extraLong {
    final base = const Duration(milliseconds: 700);
    final multiplier = PlatformOptimizations().animationDurationMultiplier;
    return Duration(milliseconds: (base.inMilliseconds * multiplier).round());
  }

  /// Get duration for specific animation type
  Duration forType(AnimationType type) {
    switch (type) {
      case AnimationType.microInteraction:
        return short;
      case AnimationType.pageTransition:
        return medium;
      case AnimationType.loading:
        return long;
      case AnimationType.emphasis:
        return extraLong;
    }
  }
}

/// Platform-specific list animations
class PlatformListAnimations {
  /// Create platform-appropriate list item insertion animation
  static Widget insertionAnimation({
    required Widget child,
    required Animation<double> animation,
  }) {
    switch (PlatformOptimizations().currentPlatform) {
      case PlatformType.ios:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      case PlatformType.android:
        return SizeTransition(
          sizeFactor: CurvedAnimation(
            parent: animation,
            curve: Curves.fastOutSlowIn,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      case PlatformType.web:
      case PlatformType.macos:
      case PlatformType.windows:
      case PlatformType.linux:
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      case PlatformType.unknown:
        return FadeTransition(
          opacity: animation,
          child: child,
        );
    }
  }

  /// Create platform-appropriate list item removal animation
  static Widget removalAnimation({
    required Widget child,
    required Animation<double> animation,
  }) {
    switch (PlatformOptimizations().currentPlatform) {
      case PlatformType.ios:
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-1.0, 0.0),
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      case PlatformType.android:
        return SizeTransition(
          sizeFactor: CurvedAnimation(
            parent: animation,
            curve: Curves.fastOutSlowIn,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      case PlatformType.web:
      case PlatformType.macos:
      case PlatformType.windows:
      case PlatformType.linux:
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInBack,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      case PlatformType.unknown:
        return FadeTransition(
          opacity: animation,
          child: child,
        );
    }
  }
}

/// Animation types for duration selection
enum AnimationType {
  microInteraction,
  pageTransition,
  loading,
  emphasis,
}

/// Slide direction for slide transitions
enum SlideDirection {
  fromLeft,
  fromRight,
  fromTop,
  fromBottom,
}