import 'package:flutter/material.dart';
import 'platform_optimizations.dart';
import 'platform_theme_extensions.dart';
import 'platform_animations.dart';

/// Platform-optimized button with platform-specific touch targets and interactions
/// Implements Requirements: 2.4, 5.2
class PlatformButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ButtonStyle? style;
  final PlatformButtonType type;
  final bool autofocus;
  final Clip clipBehavior;

  const PlatformButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.style,
    this.type = PlatformButtonType.elevated,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
  });

  @override
  State<PlatformButton> createState() => _PlatformButtonState();
}

class _PlatformButtonState extends State<PlatformButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    final platformAnimations = PlatformAnimations();
    
    _animationController = AnimationController(
      duration: platformAnimations.durations.short,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: _getPlatformPressScale(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: platformAnimations.curves.standard,
    ));
  }
  
  double _getPlatformPressScale() {
    switch (PlatformOptimizations().currentPlatform) {
      case PlatformType.ios:
        return 0.95; // iOS press down effect
      case PlatformType.android:
        return 0.98; // Android subtle press
      case PlatformType.web:
      case PlatformType.macos:
      case PlatformType.windows:
      case PlatformType.linux:
        return 0.97; // Desktop press effect
      case PlatformType.unknown:
        return 0.97;
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
      
      // Trigger platform-appropriate haptic feedback
      PlatformOptimizations().triggerHapticFeedback(HapticFeedbackType.light);
    }
  }
  
  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }
  
  void _handleTapCancel() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }
  
  void _handleTap() {
    widget.onPressed?.call();
  }
  
  void _handleLongPress() {
    PlatformOptimizations().triggerHapticFeedback(HapticFeedbackType.medium);
    widget.onLongPress?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    final platformTheme = context.platformTheme;
    final baseStyle = _getBaseStyle(context, platformTheme);
    final finalStyle = widget.style != null 
        ? baseStyle.merge(widget.style)
        : baseStyle;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: _buildButton(context, finalStyle, platformTheme),
        );
      },
    );
  }
  
  Widget _buildButton(BuildContext context, ButtonStyle style, PlatformThemeExtension platformTheme) {
    final button = _createButtonByType(context, style);
    
    // Wrap with gesture detector for platform-specific interactions
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      onLongPress: widget.onLongPress != null ? _handleLongPress : null,
      child: MouseRegion(
        cursor: platformTheme.interactiveCursor,
        child: button,
      ),
    );
  }
  
  Widget _createButtonByType(BuildContext context, ButtonStyle style) {
    switch (widget.type) {
      case PlatformButtonType.elevated:
        return ElevatedButton(
          onPressed: null, // We handle press through GestureDetector
          style: style,
          autofocus: widget.autofocus,
          clipBehavior: widget.clipBehavior,
          child: widget.child,
        );
      case PlatformButtonType.filled:
        return FilledButton(
          onPressed: null,
          style: style,
          autofocus: widget.autofocus,
          clipBehavior: widget.clipBehavior,
          child: widget.child,
        );
      case PlatformButtonType.outlined:
        return OutlinedButton(
          onPressed: null,
          style: style,
          autofocus: widget.autofocus,
          clipBehavior: widget.clipBehavior,
          child: widget.child,
        );
      case PlatformButtonType.text:
        return TextButton(
          onPressed: null,
          style: style,
          autofocus: widget.autofocus,
          clipBehavior: widget.clipBehavior,
          child: widget.child,
        );
    }
  }
  
  ButtonStyle _getBaseStyle(BuildContext context, PlatformThemeExtension platformTheme) {
    return ButtonStyle(
      minimumSize: WidgetStateProperty.all(
        Size(platformTheme.touchTargetSize, platformTheme.touchTargetSize),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(platformTheme.borderRadius),
        ),
      ),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return platformTheme.elevation * 0.5;
        }
        if (states.contains(WidgetState.hovered)) {
          return platformTheme.elevation * 1.5;
        }
        return platformTheme.elevation;
      }),
    );
  }
}

/// Platform-optimized icon button
class PlatformIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final double? iconSize;
  final Color? color;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? highlightColor;
  final Color? splashColor;
  final Color? disabledColor;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;
  final double? splashRadius;
  final bool autofocus;
  final String? tooltip;

  const PlatformIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.onLongPress,
    this.iconSize,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.disabledColor,
    this.padding,
    this.alignment = Alignment.center,
    this.splashRadius,
    this.autofocus = false,
    this.tooltip,
  });

  @override
  State<PlatformIconButton> createState() => _PlatformIconButtonState();
}

class _PlatformIconButtonState extends State<PlatformIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    final platformAnimations = PlatformAnimations();
    
    _animationController = AnimationController(
      duration: platformAnimations.durations.short,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: platformAnimations.curves.standard,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
      PlatformOptimizations().triggerHapticFeedback(HapticFeedbackType.light);
    }
  }
  
  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }
  
  void _handleTapCancel() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final platformTheme = context.platformTheme;
    
    Widget iconButton = IconButton(
      onPressed: null, // We handle press through GestureDetector
      icon: widget.icon,
      iconSize: widget.iconSize,
      color: widget.color,
      focusColor: widget.focusColor,
      hoverColor: widget.hoverColor,
      highlightColor: widget.highlightColor,
      splashColor: widget.splashColor,
      disabledColor: widget.disabledColor,
      padding: widget.padding,
      alignment: widget.alignment,
      splashRadius: widget.splashRadius,
      autofocus: widget.autofocus,
      tooltip: widget.tooltip,
      style: IconButton.styleFrom(
        minimumSize: Size(platformTheme.touchTargetSize, platformTheme.touchTargetSize),
      ),
    );
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.onPressed,
            onLongPress: widget.onLongPress != null 
                ? () {
                    PlatformOptimizations().triggerHapticFeedback(HapticFeedbackType.medium);
                    widget.onLongPress?.call();
                  }
                : null,
            child: MouseRegion(
              cursor: platformTheme.interactiveCursor,
              child: iconButton,
            ),
          ),
        );
      },
    );
  }
}

/// Platform-optimized floating action button
class PlatformFloatingActionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? splashColor;
  final Object? heroTag;
  final double? elevation;
  final double? focusElevation;
  final double? hoverElevation;
  final double? highlightElevation;
  final double? disabledElevation;
  final ShapeBorder? shape;
  final Clip clipBehavior;
  final bool autofocus;
  final MaterialTapTargetSize? materialTapTargetSize;

  const PlatformFloatingActionButton({
    super.key,
    required this.child,
    this.onPressed,
    this.tooltip,
    this.foregroundColor,
    this.backgroundColor,
    this.focusColor,
    this.hoverColor,
    this.splashColor,
    this.heroTag,
    this.elevation,
    this.focusElevation,
    this.hoverElevation,
    this.highlightElevation,
    this.disabledElevation,
    this.shape,
    this.clipBehavior = Clip.none,
    this.autofocus = false,
    this.materialTapTargetSize,
  });

  @override
  State<PlatformFloatingActionButton> createState() => _PlatformFloatingActionButtonState();
}

class _PlatformFloatingActionButtonState extends State<PlatformFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    final platformAnimations = PlatformAnimations();
    
    _animationController = AnimationController(
      duration: platformAnimations.durations.short,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: platformAnimations.curves.emphasized,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _animationController.forward();
      PlatformOptimizations().triggerHapticFeedback(HapticFeedbackType.medium);
    }
  }
  
  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
  }
  
  void _handleTapCancel() {
    _animationController.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    final platformTheme = context.platformTheme;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: FloatingActionButton(
              onPressed: widget.onPressed,
              tooltip: widget.tooltip,
              foregroundColor: widget.foregroundColor,
              backgroundColor: widget.backgroundColor,
              focusColor: widget.focusColor,
              hoverColor: widget.hoverColor,
              splashColor: widget.splashColor,
              heroTag: widget.heroTag,
              elevation: widget.elevation ?? platformTheme.elevation,
              focusElevation: widget.focusElevation ?? platformTheme.elevation * 1.5,
              hoverElevation: widget.hoverElevation ?? platformTheme.elevation * 2,
              highlightElevation: widget.highlightElevation ?? platformTheme.elevation * 0.5,
              disabledElevation: widget.disabledElevation ?? 0,
              shape: widget.shape ?? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(platformTheme.borderRadius * 2),
              ),
              clipBehavior: widget.clipBehavior,
              autofocus: widget.autofocus,
              materialTapTargetSize: widget.materialTapTargetSize,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// Button types for platform optimization
enum PlatformButtonType {
  elevated,
  filled,
  outlined,
  text,
}