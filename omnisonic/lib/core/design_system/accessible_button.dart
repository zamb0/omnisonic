import 'package:flutter/material.dart';
import 'accessibility.dart';
import 'accessibility_preferences.dart';
import 'animation_manager.dart';
import 'spacing.dart';
import 'gesture_feedback.dart';

/// Accessible button component with WCAG compliance and reduced motion support
class AccessibleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final String? tooltip;
  final ButtonStyle? style;
  final bool autofocus;
  final FocusNode? focusNode;
  final AccessibleButtonType type;
  final AccessibleButtonSize size;
  final bool enabled;
  final IconData? icon;
  final bool loading;

  const AccessibleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.semanticLabel,
    this.tooltip,
    this.style,
    this.autofocus = false,
    this.focusNode,
    this.type = AccessibleButtonType.elevated,
    this.size = AccessibleButtonSize.medium,
    this.enabled = true,
    this.icon,
    this.loading = false,
  });

  /// Create an accessible elevated button
  factory AccessibleButton.elevated({
    Key? key,
    required Widget child,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    String? semanticLabel,
    String? tooltip,
    ButtonStyle? style,
    bool autofocus = false,
    FocusNode? focusNode,
    AccessibleButtonSize size = AccessibleButtonSize.medium,
    bool enabled = true,
    IconData? icon,
    bool loading = false,
  }) {
    return AccessibleButton(
      key: key,
      onPressed: onPressed,
      onLongPress: onLongPress,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      style: style,
      autofocus: autofocus,
      focusNode: focusNode,
      type: AccessibleButtonType.elevated,
      size: size,
      enabled: enabled,
      icon: icon,
      loading: loading,
      child: child,
    );
  }

  /// Create an accessible text button
  factory AccessibleButton.text({
    Key? key,
    required Widget child,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    String? semanticLabel,
    String? tooltip,
    ButtonStyle? style,
    bool autofocus = false,
    FocusNode? focusNode,
    AccessibleButtonSize size = AccessibleButtonSize.medium,
    bool enabled = true,
    IconData? icon,
    bool loading = false,
  }) {
    return AccessibleButton(
      key: key,
      onPressed: onPressed,
      onLongPress: onLongPress,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      style: style,
      autofocus: autofocus,
      focusNode: focusNode,
      type: AccessibleButtonType.text,
      size: size,
      enabled: enabled,
      icon: icon,
      loading: loading,
      child: child,
    );
  }

  /// Create an accessible outlined button
  factory AccessibleButton.outlined({
    Key? key,
    required Widget child,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    String? semanticLabel,
    String? tooltip,
    ButtonStyle? style,
    bool autofocus = false,
    FocusNode? focusNode,
    AccessibleButtonSize size = AccessibleButtonSize.medium,
    bool enabled = true,
    IconData? icon,
    bool loading = false,
  }) {
    return AccessibleButton(
      key: key,
      onPressed: onPressed,
      onLongPress: onLongPress,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      style: style,
      autofocus: autofocus,
      focusNode: focusNode,
      type: AccessibleButtonType.outlined,
      size: size,
      enabled: enabled,
      icon: icon,
      loading: loading,
      child: child,
    );
  }

  /// Create an accessible icon button
  factory AccessibleButton.icon({
    Key? key,
    required IconData icon,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    String? semanticLabel,
    String? tooltip,
    ButtonStyle? style,
    bool autofocus = false,
    FocusNode? focusNode,
    AccessibleButtonSize size = AccessibleButtonSize.medium,
    bool enabled = true,
    bool loading = false,
  }) {
    return AccessibleButton(
      key: key,
      onPressed: onPressed,
      onLongPress: onLongPress,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      style: style,
      autofocus: autofocus,
      focusNode: focusNode,
      type: AccessibleButtonType.icon,
      size: size,
      enabled: enabled,
      icon: icon,
      loading: loading,
      child: Icon(icon),
    );
  }

  @override
  State<AccessibleButton> createState() => _AccessibleButtonState();
}

class _AccessibleButtonState extends State<AccessibleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    
    _animationController = AccessibleAnimationManager.createController(
      vsync: this,
      duration: AnimationManager.tapDuration,
    );
    
    _scaleAnimation = AccessibleAnimationManager.createTween<double>(
      parent: _animationController,
      tween: Tween<double>(begin: 1.0, end: 0.95),
      curve: AnimationManager.tapCurve,
    );
    
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChanged);
    }
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _handleTap() {
    if (widget.enabled && !widget.loading) {
      AnimationManager().triggerHapticFeedback(
        type: HapticFeedbackType.light,
      );
      widget.onPressed?.call();
    }
  }

  void _handleLongPress() {
    if (widget.enabled && !widget.loading) {
      AnimationManager().triggerHapticFeedback(
        type: HapticFeedbackType.medium,
      );
      widget.onLongPress?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle(context);
    final constraints = _getButtonConstraints();
    final semanticLabel = widget.semanticLabel ?? _getDefaultSemanticLabel();
    
    Widget button = _buildButton(context, buttonStyle, constraints);
    
    // Add tooltip if provided
    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }
    
    // Add semantics
    button = Semantics(
      label: semanticLabel,
      hint: widget.enabled 
          ? OmnisonicSemantics.interactionHint('activate')
          : 'Button is disabled',
      button: true,
      enabled: widget.enabled && !widget.loading,
      focusable: widget.enabled,
      child: button,
    );
    
    // Add focus indicator
    button = Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      child: Builder(
        builder: (context) {
          return OmnisonicFocusManager.buildFocusIndicator(
            hasFocus: _isFocused,
            child: button,
          );
        },
      ),
    );
    
    return button;
  }

  Widget _buildButton(BuildContext context, ButtonStyle style, BoxConstraints constraints) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ConstrainedBox(
            constraints: constraints,
            child: _buildButtonByType(context, style),
          ),
        );
      },
    );
  }

  Widget _buildButtonByType(BuildContext context, ButtonStyle style) {
    final child = _buildButtonChild();
    
    switch (widget.type) {
      case AccessibleButtonType.elevated:
        return ElevatedButton(
          onPressed: widget.enabled && !widget.loading ? _handleTap : null,
          onLongPress: widget.enabled && !widget.loading ? _handleLongPress : null,
          style: style,
          child: child,
        );
      case AccessibleButtonType.text:
        return TextButton(
          onPressed: widget.enabled && !widget.loading ? _handleTap : null,
          onLongPress: widget.enabled && !widget.loading ? _handleLongPress : null,
          style: style,
          child: child,
        );
      case AccessibleButtonType.outlined:
        return OutlinedButton(
          onPressed: widget.enabled && !widget.loading ? _handleTap : null,
          onLongPress: widget.enabled && !widget.loading ? _handleLongPress : null,
          style: style,
          child: child,
        );
      case AccessibleButtonType.icon:
        return IconButton(
          onPressed: widget.enabled && !widget.loading ? _handleTap : null,
          style: style,
          icon: child,
        );
    }
  }

  Widget _buildButtonChild() {
    if (widget.loading) {
      return SizedBox(
        width: _getLoadingSize(),
        height: _getLoadingSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.enabled 
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).disabledColor,
          ),
        ),
      );
    }

    if (widget.icon != null && widget.type != AccessibleButtonType.icon) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: _getIconSize()),
          const SizedBox(width: 8),
          widget.child,
        ],
      );
    }

    return widget.child;
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    final baseStyle = widget.style ?? _getDefaultButtonStyle(context);
    
    return baseStyle.copyWith(
      minimumSize: WidgetStateProperty.all(_getMinimumSize()),
      padding: WidgetStateProperty.all(_getPadding()),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  ButtonStyle _getDefaultButtonStyle(BuildContext context) {
    switch (widget.type) {
      case AccessibleButtonType.elevated:
        return ElevatedButton.styleFrom();
      case AccessibleButtonType.text:
        return TextButton.styleFrom();
      case AccessibleButtonType.outlined:
        return OutlinedButton.styleFrom();
      case AccessibleButtonType.icon:
        return IconButton.styleFrom();
    }
  }

  BoxConstraints _getButtonConstraints() {
    final minSize = _getMinimumSize();
    return BoxConstraints(
      minWidth: minSize.width,
      minHeight: minSize.height,
    );
  }

  Size _getMinimumSize() {
    switch (widget.size) {
      case AccessibleButtonSize.small:
        return const Size(OmnisonicTouchTargets.minimum, OmnisonicTouchTargets.minimum);
      case AccessibleButtonSize.medium:
        return const Size(OmnisonicTouchTargets.comfortable, OmnisonicTouchTargets.comfortable);
      case AccessibleButtonSize.large:
        return const Size(OmnisonicTouchTargets.large, OmnisonicTouchTargets.large);
    }
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case AccessibleButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case AccessibleButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case AccessibleButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case AccessibleButtonSize.small:
        return 16;
      case AccessibleButtonSize.medium:
        return 20;
      case AccessibleButtonSize.large:
        return 24;
    }
  }

  double _getLoadingSize() {
    switch (widget.size) {
      case AccessibleButtonSize.small:
        return 16;
      case AccessibleButtonSize.medium:
        return 20;
      case AccessibleButtonSize.large:
        return 24;
    }
  }

  String _getDefaultSemanticLabel() {
    if (widget.loading) {
      return 'Loading, please wait';
    }
    
    if (widget.child is Text) {
      return (widget.child as Text).data ?? '';
    }
    
    if (widget.icon != null) {
      return 'Button with ${widget.icon.toString()} icon';
    }
    
    return 'Button';
  }
}

/// Button type enumeration
enum AccessibleButtonType {
  elevated,
  text,
  outlined,
  icon,
}

/// Button size enumeration
enum AccessibleButtonSize {
  small,
  medium,
  large,
}

/// Accessible floating action button
class AccessibleFloatingActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticLabel;
  final String? tooltip;
  final bool mini;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final bool autofocus;
  final FocusNode? focusNode;

  const AccessibleFloatingActionButton({
    super.key,
    this.onPressed,
    required this.child,
    this.semanticLabel,
    this.tooltip,
    this.mini = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.shape,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<AccessibleFloatingActionButton> createState() => _AccessibleFloatingActionButtonState();
}

class _AccessibleFloatingActionButtonState extends State<AccessibleFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    
    _animationController = AccessibleAnimationManager.createController(
      vsync: this,
      duration: AnimationManager.tapDuration,
    );
    
    _scaleAnimation = AccessibleAnimationManager.createTween<double>(
      parent: _animationController,
      tween: Tween<double>(begin: 1.0, end: 0.9),
      curve: AnimationManager.tapCurve,
    );
    
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChanged);
    }
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _handleTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    AnimationManager().triggerHapticFeedback(
      type: HapticFeedbackType.light,
    );
    
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final semanticLabel = widget.semanticLabel ?? _getDefaultSemanticLabel();
    
    Widget fab = AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FloatingActionButton(
            onPressed: widget.onPressed != null ? _handleTap : null,
            mini: widget.mini,
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor,
            elevation: widget.elevation,
            shape: widget.shape,
            child: widget.child,
          ),
        );
      },
    );

    // Add tooltip if provided
    if (widget.tooltip != null) {
      fab = Tooltip(
        message: widget.tooltip!,
        child: fab,
      );
    }

    // Add semantics
    fab = Semantics(
      label: semanticLabel,
      hint: OmnisonicSemantics.interactionHint('activate'),
      button: true,
      enabled: widget.onPressed != null,
      child: fab,
    );

    // Add focus support
    fab = Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      child: Builder(
        builder: (context) {
          return OmnisonicFocusManager.buildFocusIndicator(
            hasFocus: _isFocused,
            child: fab,
          );
        },
      ),
    );

    return fab;
  }

  String _getDefaultSemanticLabel() {
    if (widget.child is Icon) {
      return 'Floating action button';
    }
    return 'Floating action button';
  }
}