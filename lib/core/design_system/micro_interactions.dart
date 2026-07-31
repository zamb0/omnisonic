import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'animation_manager.dart';

/// Comprehensive micro-interactions system for enhanced user feedback
/// Provides button press, card tap, list interactions, and haptic feedback
class MicroInteractions {
  /// Create an interactive button with micro-interactions
  static Widget interactiveButton({
    required Widget child,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
    bool enableHapticFeedback = true,
    bool enableScaleAnimation = true,
    bool enableRippleEffect = true,
    double scaleAmount = 0.95,
    Duration animationDuration = AnimationManager.tapDuration,
    Color? rippleColor,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    double? elevation,
  }) {
    return _InteractiveButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      enableHapticFeedback: enableHapticFeedback,
      enableScaleAnimation: enableScaleAnimation,
      enableRippleEffect: enableRippleEffect,
      scaleAmount: scaleAmount,
      animationDuration: animationDuration,
      rippleColor: rippleColor,
      borderRadius: borderRadius,
      padding: padding,
      backgroundColor: backgroundColor,
      elevation: elevation,
      child: child,
    );
  }

  /// Create an interactive card with hover and tap animations
  static Widget interactiveCard({
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool enableHoverAnimation = true,
    bool enableTapAnimation = true,
    bool enableHapticFeedback = true,
    double hoverElevation = 8.0,
    double restingElevation = 2.0,
    double hoverScale = 1.02,
    double tapScale = 0.98,
    Duration hoverDuration = AnimationManager.hoverDuration,
    Duration tapDuration = AnimationManager.tapDuration,
    BorderRadius? borderRadius,
    Color? color,
    Color? shadowColor,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    return _InteractiveCard(
      onTap: onTap,
      onLongPress: onLongPress,
      enableHoverAnimation: enableHoverAnimation,
      enableTapAnimation: enableTapAnimation,
      enableHapticFeedback: enableHapticFeedback,
      hoverElevation: hoverElevation,
      restingElevation: restingElevation,
      hoverScale: hoverScale,
      tapScale: tapScale,
      hoverDuration: hoverDuration,
      tapDuration: tapDuration,
      borderRadius: borderRadius,
      color: color,
      shadowColor: shadowColor,
      margin: margin,
      padding: padding,
      child: child,
    );
  }

  /// Create an interactive list item with smooth animations
  static Widget interactiveListItem({
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool enableSlideAnimation = true,
    bool enableFadeAnimation = true,
    bool enableHapticFeedback = true,
    Duration animationDuration = AnimationManager.normalDuration,
    Curve animationCurve = AnimationManager.standardCurve,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    Color? hoverColor,
    int? index,
  }) {
    return _InteractiveListItem(
      onTap: onTap,
      onLongPress: onLongPress,
      enableSlideAnimation: enableSlideAnimation,
      enableFadeAnimation: enableFadeAnimation,
      enableHapticFeedback: enableHapticFeedback,
      animationDuration: animationDuration,
      animationCurve: animationCurve,
      padding: padding,
      backgroundColor: backgroundColor,
      hoverColor: hoverColor,
      index: index,
      child: child,
    );
  }

  /// Create a hover effect for desktop platforms
  static Widget hoverEffect({
    required Widget child,
    required Widget Function(bool isHovering) builder,
    Duration duration = AnimationManager.hoverDuration,
    Curve curve = AnimationManager.hoverCurve,
  }) {
    if (!kIsWeb &&
        (defaultTargetPlatform != TargetPlatform.windows &&
            defaultTargetPlatform != TargetPlatform.macOS &&
            defaultTargetPlatform != TargetPlatform.linux)) {
      return child;
    }

    return _HoverEffect(
      duration: duration,
      curve: curve,
      builder: builder,
      child: child,
    );
  }

  /// Trigger haptic feedback with different intensities
  static void triggerHapticFeedback({
    bool lightImpact = true,
    bool respectUserSettings = true,
  }) {
    if (!respectUserSettings) return;

    if (lightImpact) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  /// Create a ripple effect animation
  static Widget rippleEffect({
    required Widget child,
    required VoidCallback? onTap,
    Color? rippleColor,
    BorderRadius? borderRadius,
    Duration duration = AnimationManager.rippleDuration,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: rippleColor?.withValues(alpha: 0.3),
        highlightColor: rippleColor?.withValues(alpha: 0.1),
        borderRadius: borderRadius,
        splashFactory: InkRipple.splashFactory,
        child: child,
      ),
    );
  }

  /// Create a pulsing animation for emphasis
  static Widget pulseAnimation({
    required Widget child,
    bool enabled = true,
    Duration duration = AnimationManager.pulsingDuration,
    double minScale = 0.95,
    double maxScale = 1.05,
    Curve curve = AnimationManager.pulsingCurve,
  }) {
    if (!enabled) return child;

    return _PulseAnimation(
      duration: duration,
      minScale: minScale,
      maxScale: maxScale,
      curve: curve,
      child: child,
    );
  }
}

/// Interactive button implementation
class _InteractiveButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final bool enableHapticFeedback;
  final bool enableScaleAnimation;
  final bool enableRippleEffect;
  final double scaleAmount;
  final Duration animationDuration;
  final Color? rippleColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double? elevation;

  const _InteractiveButton({
    required this.child,
    required this.onPressed,
    this.onLongPress,
    this.enableHapticFeedback = true,
    this.enableScaleAnimation = true,
    this.enableRippleEffect = true,
    this.scaleAmount = 0.95,
    this.animationDuration = AnimationManager.tapDuration,
    this.rippleColor,
    this.borderRadius,
    this.padding,
    this.backgroundColor,
    this.elevation,
  });

  @override
  State<_InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<_InteractiveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationManager().createController(
      duration: widget.animationDuration,
      vsync: this,
      debugLabel: 'InteractiveButton',
    );

    _scaleAnimation = AnimationUtilities.createScaleAnimation(
      controller: _controller,
      minScale: widget.scaleAmount,
      maxScale: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableScaleAnimation) {
      _controller.forward();
    }
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableScaleAnimation) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enableScaleAnimation) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget button = widget.child;

    if (widget.padding != null) {
      button = Padding(padding: widget.padding!, child: button);
    }

    if (widget.enableScaleAnimation) {
      button = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: button,
      );
    }

    if (widget.backgroundColor != null || widget.elevation != null) {
      button = Card(
        color: widget.backgroundColor,
        elevation: widget.elevation ?? 0,
        shape: RoundedRectangleBorder(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        ),
        child: button,
      );
    }

    if (widget.enableRippleEffect) {
      button = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          onLongPress: widget.onLongPress,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          splashColor: widget.rippleColor?.withValues(alpha: 0.3),
          highlightColor: widget.rippleColor?.withValues(alpha: 0.1),
          borderRadius: widget.borderRadius,
          child: button,
        ),
      );
    } else {
      button = GestureDetector(
        onTap: widget.onPressed,
        onLongPress: widget.onLongPress,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: button,
      );
    }

    return button;
  }
}

/// Interactive card implementation
class _InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enableHoverAnimation;
  final bool enableTapAnimation;
  final bool enableHapticFeedback;
  final double hoverElevation;
  final double restingElevation;
  final double hoverScale;
  final double tapScale;
  final Duration hoverDuration;
  final Duration tapDuration;
  final BorderRadius? borderRadius;
  final Color? color;
  final Color? shadowColor;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const _InteractiveCard({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enableHoverAnimation = true,
    this.enableTapAnimation = true,
    this.enableHapticFeedback = true,
    this.hoverElevation = 8.0,
    this.restingElevation = 2.0,
    this.hoverScale = 1.02,
    this.tapScale = 0.98,
    this.hoverDuration = AnimationManager.hoverDuration,
    this.tapDuration = AnimationManager.tapDuration,
    this.borderRadius,
    this.color,
    this.shadowColor,
    this.margin,
    this.padding,
  });

  @override
  State<_InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<_InteractiveCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _tapController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _tapScaleAnimation;

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationManager().createController(
      duration: widget.hoverDuration,
      vsync: this,
      debugLabel: 'InteractiveCard_Hover',
    );

    _tapController = AnimationManager().createController(
      duration: widget.tapDuration,
      vsync: this,
      debugLabel: 'InteractiveCard_Tap',
    );

    _elevationAnimation =
        Tween<double>(
          begin: widget.restingElevation,
          end: widget.hoverElevation,
        ).animate(
          CurvedAnimation(
            parent: _hoverController,
            curve: AnimationManager.hoverCurve,
          ),
        );

    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.hoverScale).animate(
      CurvedAnimation(
        parent: _hoverController,
        curve: AnimationManager.hoverCurve,
      ),
    );

    _tapScaleAnimation = Tween<double>(begin: 1.0, end: widget.tapScale)
        .animate(
          CurvedAnimation(
            parent: _tapController,
            curve: AnimationManager.tapCurve,
          ),
        );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovering) {
    if (!widget.enableHoverAnimation) return;

    if (isHovering) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableTapAnimation) {
      _tapController.forward();
    }
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableTapAnimation) {
      _tapController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enableTapAnimation) {
      _tapController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_hoverController, _tapController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _tapScaleAnimation.value,
          child: Card(
            elevation: _elevationAnimation.value,
            color: widget.color,
            shadowColor: widget.shadowColor,
            margin: widget.margin,
            shape: RoundedRectangleBorder(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              onHover: _handleHover,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              child: Container(padding: widget.padding, child: widget.child),
            ),
          ),
        );
      },
    );
  }
}

/// Interactive list item implementation
class _InteractiveListItem extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enableSlideAnimation;
  final bool enableFadeAnimation;
  final bool enableHapticFeedback;
  final Duration animationDuration;
  final Curve animationCurve;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? hoverColor;
  final int? index;

  const _InteractiveListItem({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enableSlideAnimation = true,
    this.enableFadeAnimation = true,
    this.enableHapticFeedback = true,
    this.animationDuration = AnimationManager.normalDuration,
    this.animationCurve = AnimationManager.standardCurve,
    this.padding,
    this.backgroundColor,
    this.hoverColor,
    this.index,
  });

  @override
  State<_InteractiveListItem> createState() => _InteractiveListItemState();
}

class _InteractiveListItemState extends State<_InteractiveListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationManager().createController(
      duration: widget.animationDuration,
      vsync: this,
      debugLabel: 'InteractiveListItem_${widget.index ?? 0}',
    );

    _slideAnimation = AnimationUtilities.createSlideAnimation(
      controller: _controller,
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
      curve: widget.animationCurve,
    );

    _fadeAnimation = AnimationUtilities.createFadeAnimation(
      controller: _controller,
      curve: widget.animationCurve,
    );

    // Stagger the animation based on index
    if (widget.index != null) {
      Future.delayed(Duration(milliseconds: widget.index! * 50), () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    widget.onTap?.call();
  }

  void _handleLongPress() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    Widget item = widget.child;

    if (widget.padding != null) {
      item = Padding(padding: widget.padding!, child: item);
    }

    if (widget.enableSlideAnimation || widget.enableFadeAnimation) {
      item = AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          Widget animatedChild = child!;

          if (widget.enableSlideAnimation) {
            animatedChild = SlideTransition(
              position: _slideAnimation,
              child: animatedChild,
            );
          }

          if (widget.enableFadeAnimation) {
            animatedChild = FadeTransition(
              opacity: _fadeAnimation,
              child: animatedChild,
            );
          }

          return animatedChild;
        },
        child: item,
      );
    }

    return Material(
      color: widget.backgroundColor ?? Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        onLongPress: _handleLongPress,
        hoverColor: widget.hoverColor,
        child: item,
      ),
    );
  }
}

/// Hover effect implementation for desktop platforms
class _HoverEffect extends StatefulWidget {
  final Widget child;
  final Widget Function(bool isHovering) builder;
  final Duration duration;
  final Curve curve;

  const _HoverEffect({
    required this.child,
    required this.builder,
    this.duration = AnimationManager.hoverDuration,
    this.curve = AnimationManager.hoverCurve,
  });

  @override
  State<_HoverEffect> createState() => _HoverEffectState();
}

class _HoverEffectState extends State<_HoverEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationManager().createController(
      duration: widget.duration,
      vsync: this,
      debugLabel: 'HoverEffect',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
    });

    if (isHovering) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return widget.builder(_isHovering);
        },
      ),
    );
  }
}

/// Pulse animation implementation
class _PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final Curve curve;

  const _PulseAnimation({
    required this.child,
    this.duration = AnimationManager.pulsingDuration,
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.curve = AnimationManager.pulsingCurve,
  });

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationManager().createController(
      duration: widget.duration,
      vsync: this,
      debugLabel: 'PulseAnimation',
    );

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: widget.child,
    );
  }
}
