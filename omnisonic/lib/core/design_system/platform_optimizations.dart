import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Platform-specific optimizations for UI components and interactions
class PlatformOptimizations {
  static const PlatformOptimizations _instance = PlatformOptimizations._internal();
  factory PlatformOptimizations() => _instance;
  const PlatformOptimizations._internal();

  /// Get the current platform type
  PlatformType get currentPlatform {
    if (kIsWeb) return PlatformType.web;
    if (Platform.isIOS) return PlatformType.ios;
    if (Platform.isAndroid) return PlatformType.android;
    if (Platform.isMacOS) return PlatformType.macos;
    if (Platform.isWindows) return PlatformType.windows;
    if (Platform.isLinux) return PlatformType.linux;
    return PlatformType.unknown;
  }

  /// Check if the current platform supports hover interactions
  bool get supportsHover {
    return currentPlatform.isDesktop || kIsWeb;
  }

  /// Check if the current platform supports haptic feedback
  bool get supportsHaptics {
    return currentPlatform.isMobile;
  }

  /// Get platform-appropriate touch target size
  double get touchTargetSize {
    switch (currentPlatform) {
      case PlatformType.ios:
        return 44.0; // iOS HIG minimum
      case PlatformType.android:
        return 48.0; // Material Design minimum
      case PlatformType.web:
      case PlatformType.macos:
      case PlatformType.windows:
      case PlatformType.linux:
        return 32.0; // Desktop can be smaller due to precise cursor
      case PlatformType.unknown:
        return 44.0; // Safe default
    }
  }

  /// Get platform-appropriate animation duration multiplier
  double get animationDurationMultiplier {
    switch (currentPlatform) {
      case PlatformType.ios:
        return 1.0; // iOS standard timing
      case PlatformType.android:
        return 1.0; // Material standard timing
      case PlatformType.web:
        return 0.8; // Slightly faster for web responsiveness
      case PlatformType.macos:
        return 1.2; // macOS prefers slightly longer animations
      case PlatformType.windows:
      case PlatformType.linux:
        return 0.9; // Desktop slightly faster
      case PlatformType.unknown:
        return 1.0;
    }
  }

  /// Get platform-appropriate border radius
  double get defaultBorderRadius {
    switch (currentPlatform) {
      case PlatformType.ios:
        return 12.0; // iOS rounded corners
      case PlatformType.android:
        return 8.0; // Material Design
      case PlatformType.web:
      case PlatformType.macos:
      case PlatformType.windows:
      case PlatformType.linux:
        return 6.0; // Desktop more subtle
      case PlatformType.unknown:
        return 8.0;
    }
  }

  /// Get platform-appropriate elevation
  double get defaultElevation {
    switch (currentPlatform) {
      case PlatformType.ios:
        return 1.0; // iOS subtle shadows
      case PlatformType.android:
        return 2.0; // Material Design standard
      case PlatformType.web:
      case PlatformType.macos:
      case PlatformType.windows:
      case PlatformType.linux:
        return 4.0; // Desktop more pronounced
      case PlatformType.unknown:
        return 2.0;
    }
  }

  /// Trigger platform-appropriate haptic feedback
  Future<void> triggerHapticFeedback(HapticFeedbackType type) async {
    if (!supportsHaptics) return;

    switch (type) {
      case HapticFeedbackType.light:
        await HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        await HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        await HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        await HapticFeedback.selectionClick();
        break;
    }
  }

  /// Get platform-appropriate scroll physics
  ScrollPhysics get scrollPhysics {
    switch (currentPlatform) {
      case PlatformType.ios:
        return const BouncingScrollPhysics();
      case PlatformType.android:
        return const ClampingScrollPhysics();
      case PlatformType.web:
      case PlatformType.macos:
      case PlatformType.windows:
      case PlatformType.linux:
        return const ClampingScrollPhysics();
      case PlatformType.unknown:
        return const ClampingScrollPhysics();
    }
  }

  /// Get platform-appropriate cursor for interactive elements
  SystemMouseCursor get interactiveCursor {
    if (supportsHover) {
      return SystemMouseCursors.click;
    }
    return SystemMouseCursors.basic;
  }

  /// Get platform-appropriate focus highlight color
  Color getFocusHighlightColor(BuildContext context) {
    final theme = Theme.of(context);
    
    switch (currentPlatform) {
      case PlatformType.ios:
        return theme.colorScheme.primary.withValues(alpha: 0.3);
      case PlatformType.android:
        return theme.colorScheme.primary.withValues(alpha: 0.12);
      case PlatformType.web:
      case PlatformType.macos:
      case PlatformType.windows:
      case PlatformType.linux:
        return theme.colorScheme.primary.withValues(alpha: 0.2);
      case PlatformType.unknown:
        return theme.colorScheme.primary.withValues(alpha: 0.2);
    }
  }
}

/// Platform-specific hover effect widget
class PlatformHoverEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onHover;
  final double? hoverScale;
  final double? hoverElevation;
  final Color? hoverColor;
  final Duration? duration;

  const PlatformHoverEffect({
    super.key,
    required this.child,
    this.onTap,
    this.onHover,
    this.hoverScale,
    this.hoverElevation,
    this.hoverColor,
    this.duration,
  });

  @override
  State<PlatformHoverEffect> createState() => _PlatformHoverEffectState();
}

class _PlatformHoverEffectState extends State<PlatformHoverEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? 
        Duration(milliseconds: (200 * PlatformOptimizations().animationDurationMultiplier).round()),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.hoverScale ?? _getDefaultHoverScale(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _elevationAnimation = Tween<double>(
      begin: PlatformOptimizations().defaultElevation,
      end: widget.hoverElevation ?? _getDefaultHoverElevation(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  double _getDefaultHoverScale() {
    switch (PlatformOptimizations().currentPlatform) {
      case PlatformType.ios:
        return 0.98; // iOS subtle scale down
      case PlatformType.android:
        return 1.02; // Android subtle scale up
      case PlatformType.web:
      case PlatformType.macos:
      case PlatformType.windows:
      case PlatformType.linux:
        return 1.05; // Desktop more pronounced
      case PlatformType.unknown:
        return 1.02;
    }
  }

  double _getDefaultHoverElevation() {
    return PlatformOptimizations().defaultElevation * 2;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovering) {
    if (!PlatformOptimizations().supportsHover) return;
    
    if (isHovering) {
      _controller.forward();
      widget.onHover?.call();
    } else {
      _controller.reverse();
    }
  }

  void _handleTap() {
    if (PlatformOptimizations().supportsHaptics) {
      PlatformOptimizations().triggerHapticFeedback(HapticFeedbackType.light);
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!PlatformOptimizations().supportsHover) {
      return GestureDetector(
        onTap: _handleTap,
        child: widget.child,
      );
    }

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      cursor: PlatformOptimizations().interactiveCursor,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Material(
                elevation: _elevationAnimation.value,
                borderRadius: BorderRadius.circular(PlatformOptimizations().defaultBorderRadius),
                color: widget.hoverColor ?? Colors.transparent,
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Platform-specific touch target optimization widget
class PlatformTouchTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? minSize;

  const PlatformTouchTarget({
    super.key,
    required this.child,
    this.onTap,
    this.minSize,
  });

  @override
  Widget build(BuildContext context) {
    final targetSize = minSize ?? PlatformOptimizations().touchTargetSize;
    
    return SizedBox(
      width: targetSize,
      height: targetSize,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PlatformOptimizations().defaultBorderRadius),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Platform-specific scroll view with appropriate physics
class PlatformScrollView extends StatelessWidget {
  final List<Widget> children;
  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  const PlatformScrollView({
    super.key,
    required this.children,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      scrollDirection: scrollDirection,
      physics: PlatformOptimizations().scrollPhysics,
      padding: padding,
      children: children,
    );
  }
}

/// Platform types enumeration
enum PlatformType {
  ios,
  android,
  web,
  macos,
  windows,
  linux,
  unknown;

  bool get isMobile => this == ios || this == android;
  bool get isDesktop => this == macos || this == windows || this == linux;
  bool get isWeb => this == web;
}

/// Haptic feedback types
enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
}