import 'dart:ui';
import 'package:flutter/material.dart';
import 'colors.dart';

/// Utility class for creating animated gradients and visual depth effects
class OmnisonicGradientAnimations {
  /// Create an animated gradient container with smooth transitions
  static Widget animatedGradientContainer({
    required Widget child,
    required LinearGradient gradient,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOutCubic,
    BorderRadius? borderRadius,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(gradient: gradient, borderRadius: borderRadius),
      child: child,
    );
  }

  /// Create a shimmer loading effect with gradient animation
  static Widget shimmerEffect({
    required Widget child,
    bool isLoading = true,
    Duration duration = const Duration(milliseconds: 1500),
    LinearGradient? shimmerGradient,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isLoading
          ? _ShimmerWidget(
              duration: duration,
              gradient: shimmerGradient ?? OmnisonicColors.shimmerGradient,
              child: child,
            )
          : child,
    );
  }

  /// Create a glass morphism effect with gradient background
  static Widget glassMorphismEffect({
    required Widget child,
    LinearGradient? gradient,
    double blur = 10.0,
    double opacity = 0.2,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradient ?? OmnisonicColors.glassMorphismLight,
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Create a depth effect with multiple shadow layers
  static Widget depthEffect({
    required Widget child,
    double depth = 8.0,
    Color shadowColor = Colors.black,
    double shadowOpacity = 0.1,
    BorderRadius? borderRadius,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          // Primary shadow
          BoxShadow(
            color: shadowColor.withValues(alpha: shadowOpacity),
            offset: Offset(0, depth * 0.5),
            blurRadius: depth,
            spreadRadius: 0,
          ),
          // Secondary shadow for depth
          BoxShadow(
            color: shadowColor.withValues(alpha: shadowOpacity * 0.5),
            offset: Offset(0, depth * 0.25),
            blurRadius: depth * 0.5,
            spreadRadius: -depth * 0.25,
          ),
          // Ambient shadow
          BoxShadow(
            color: shadowColor.withValues(alpha: shadowOpacity * 0.3),
            offset: const Offset(0, 1),
            blurRadius: depth * 0.25,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }

  /// Create an animated progress bar with gradient
  static Widget animatedProgressBar({
    required double progress,
    double height = 4.0,
    LinearGradient? gradient,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOutCubic,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.withValues(alpha: 0.3),
        borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
      ),
      child: AnimatedContainer(
        duration: duration,
        curve: curve,
        width: double.infinity,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient ?? OmnisonicColors.progressBarGradient,
              borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
            ),
          ),
        ),
      ),
    );
  }

  /// Create a pulsing gradient effect for emphasis
  static Widget pulsingGradient({
    required Widget child,
    required LinearGradient gradient,
    Duration duration = const Duration(milliseconds: 1000),
    double minOpacity = 0.5,
    double maxOpacity = 1.0,
  }) {
    return _PulsingGradientWidget(
      gradient: gradient,
      duration: duration,
      minOpacity: minOpacity,
      maxOpacity: maxOpacity,
      child: child,
    );
  }
}

/// Internal shimmer widget implementation
class _ShimmerWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final LinearGradient gradient;

  const _ShimmerWidget({
    required this.child,
    required this.duration,
    required this.gradient,
  });

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: widget.gradient.colors,
              stops: widget.gradient.stops,
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Internal pulsing gradient widget implementation
class _PulsingGradientWidget extends StatefulWidget {
  final Widget child;
  final LinearGradient gradient;
  final Duration duration;
  final double minOpacity;
  final double maxOpacity;

  const _PulsingGradientWidget({
    required this.child,
    required this.gradient,
    required this.duration,
    required this.minOpacity,
    required this.maxOpacity,
  });

  @override
  State<_PulsingGradientWidget> createState() => _PulsingGradientWidgetState();
}

class _PulsingGradientWidgetState extends State<_PulsingGradientWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: widget.minOpacity,
      end: widget.maxOpacity,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

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
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            decoration: BoxDecoration(gradient: widget.gradient),
            child: widget.child,
          ),
        );
      },
    );
  }
}
