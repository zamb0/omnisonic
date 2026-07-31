import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'platform_optimizations.dart';

/// Comprehensive gesture feedback system for the Omnisonic design system.
/// Provides visual and haptic feedback for user interactions.
class OmnisonicGestureFeedback {
  OmnisonicGestureFeedback._();

  /// Provides haptic feedback based on the interaction type
  static Future<void> hapticFeedback(HapticFeedbackType type) async {
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

  /// Creates a ripple effect widget for tap feedback
  static Widget rippleEffect({
    required Widget child,
    required VoidCallback? onTap,
    Color? rippleColor,
    BorderRadius? borderRadius,
    HapticFeedbackType hapticType = HapticFeedbackType.light,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap != null
            ? () {
                hapticFeedback(hapticType);
                onTap();
              }
            : null,
        splashColor: rippleColor?.withValues(alpha: 0.2),
        highlightColor: rippleColor?.withValues(alpha: 0.1),
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }

  /// Creates a pressable widget with scale animation feedback
  static Widget pressableScale({
    required Widget child,
    required VoidCallback? onPressed,
    double scaleDown = 0.95,
    Duration duration = const Duration(milliseconds: 100),
    HapticFeedbackType hapticType = HapticFeedbackType.light,
  }) {
    return _PressableScaleWidget(
      onPressed: onPressed,
      scaleDown: scaleDown,
      duration: duration,
      hapticType: hapticType,
      child: child,
    );
  }

  /// Creates a long press feedback widget
  static Widget longPressable({
    required Widget child,
    required VoidCallback? onLongPress,
    VoidCallback? onTap,
    Duration longPressDuration = const Duration(milliseconds: 500),
    HapticFeedbackType hapticType = HapticFeedbackType.medium,
  }) {
    return _LongPressableWidget(
      onLongPress: onLongPress,
      onTap: onTap,
      longPressDuration: longPressDuration,
      hapticType: hapticType,
      child: child,
    );
  }

  /// Creates a swipeable widget with directional feedback
  static Widget swipeable({
    required Widget child,
    VoidCallback? onSwipeLeft,
    VoidCallback? onSwipeRight,
    VoidCallback? onSwipeUp,
    VoidCallback? onSwipeDown,
    double threshold = 100.0,
    HapticFeedbackType hapticType = HapticFeedbackType.light,
  }) {
    return _SwipeableWidget(
      onSwipeLeft: onSwipeLeft,
      onSwipeRight: onSwipeRight,
      onSwipeUp: onSwipeUp,
      onSwipeDown: onSwipeDown,
      threshold: threshold,
      hapticType: hapticType,
      child: child,
    );
  }

  /// Creates a draggable widget with visual feedback
  static Widget draggable<T extends Object>({
    required Widget child,
    required T data,
    Widget? feedback,
    Widget? childWhenDragging,
    VoidCallback? onDragStarted,
    VoidCallback? onDragEnd,
    HapticFeedbackType hapticType = HapticFeedbackType.medium,
  }) {
    return Draggable<T>(
      data: data,
      feedback:
          feedback ??
          Transform.scale(
            scale: 1.1,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: child,
            ),
          ),
      childWhenDragging:
          childWhenDragging ?? Opacity(opacity: 0.5, child: child),
      onDragStarted: () {
        hapticFeedback(hapticType);
        onDragStarted?.call();
      },
      onDragEnd: (details) {
        hapticFeedback(HapticFeedbackType.light);
        onDragEnd?.call();
      },
      child: child,
    );
  }

  /// Creates a drop target with visual feedback
  static Widget dropTarget<T extends Object>({
    required Widget child,
    required bool Function(T data) onWillAccept,
    required void Function(T data) onAccept,
    Color? highlightColor,
    HapticFeedbackType hapticType = HapticFeedbackType.medium,
  }) {
    return _DropTargetWidget<T>(
      onWillAccept: onWillAccept,
      onAccept: (data) {
        hapticFeedback(hapticType);
        onAccept(data);
      },
      highlightColor: highlightColor,
      child: child,
    );
  }

  /// Creates a widget with animated state changes
  static Widget animatedState({
    required Widget child,
    required ComponentState state,
    Duration duration = const Duration(milliseconds: 200),
    Curve curve = Curves.easeInOut,
  }) {
    return _AnimatedStateWidget(
      state: state,
      duration: duration,
      curve: curve,
      child: child,
    );
  }

  /// Creates a selectable widget with animated selection feedback
  static Widget selectable({
    required Widget child,
    required bool isSelected,
    required VoidCallback onTap,
    Color? selectedColor,
    Duration duration = const Duration(milliseconds: 200),
    HapticFeedbackType hapticType = HapticFeedbackType.selection,
  }) {
    return _SelectableWidget(
      isSelected: isSelected,
      onTap: onTap,
      selectedColor: selectedColor,
      duration: duration,
      hapticType: hapticType,
      child: child,
    );
  }

  /// Creates a loading state widget with animated transitions
  static Widget loadingState({
    required Widget child,
    required bool isLoading,
    Widget? loadingWidget,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return _LoadingStateWidget(
      isLoading: isLoading,
      loadingWidget: loadingWidget,
      duration: duration,
      child: child,
    );
  }

  /// Creates a disabled state widget with visual feedback
  static Widget disabledState({
    required Widget child,
    required bool isDisabled,
    double disabledOpacity = 0.5,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return _DisabledStateWidget(
      isDisabled: isDisabled,
      disabledOpacity: disabledOpacity,
      duration: duration,
      child: child,
    );
  }
}

// HapticFeedbackType is now imported from platform_optimizations.dart
// to avoid duplication

/// Enum for component states
enum ComponentState { normal, selected, disabled, loading, error, success }

/// Internal pressable scale widget
class _PressableScaleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double scaleDown;
  final Duration duration;
  final HapticFeedbackType hapticType;

  const _PressableScaleWidget({
    required this.child,
    required this.onPressed,
    required this.scaleDown,
    required this.duration,
    required this.hapticType,
  });

  @override
  State<_PressableScaleWidget> createState() => _PressableScaleWidgetState();
}

class _PressableScaleWidgetState extends State<_PressableScaleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        if (widget.onPressed != null) {
          OmnisonicGestureFeedback.hapticFeedback(widget.hapticType);
          widget.onPressed!();
        }
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Internal long pressable widget
class _LongPressableWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final Duration longPressDuration;
  final HapticFeedbackType hapticType;

  const _LongPressableWidget({
    required this.child,
    required this.onLongPress,
    this.onTap,
    required this.longPressDuration,
    required this.hapticType,
  });

  @override
  State<_LongPressableWidget> createState() => _LongPressableWidgetState();
}

class _LongPressableWidgetState extends State<_LongPressableWidget>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _scaleController;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: widget.longPressDuration,
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.onLongPress != null) {
          OmnisonicGestureFeedback.hapticFeedback(widget.hapticType);
          widget.onLongPress!();
        }
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _scaleController.forward();
        _progressController.forward();
      },
      onTapUp: (_) {
        _scaleController.reverse();
        if (_progressController.value < 1.0) {
          _progressController.reverse();
          if (widget.onTap != null) {
            OmnisonicGestureFeedback.hapticFeedback(HapticFeedbackType.light);
            widget.onTap!();
          }
        }
      },
      onTapCancel: () {
        _scaleController.reverse();
        _progressController.reverse();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_progressAnimation, _scaleAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              children: [
                widget.child,
                if (_progressAnimation.value > 0)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Internal swipeable widget
class _SwipeableWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final double threshold;
  final HapticFeedbackType hapticType;

  const _SwipeableWidget({
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    required this.threshold,
    required this.hapticType,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond;

        if (velocity.dx.abs() > velocity.dy.abs()) {
          // Horizontal swipe
          if (velocity.dx > threshold && onSwipeRight != null) {
            OmnisonicGestureFeedback.hapticFeedback(hapticType);
            onSwipeRight!();
          } else if (velocity.dx < -threshold && onSwipeLeft != null) {
            OmnisonicGestureFeedback.hapticFeedback(hapticType);
            onSwipeLeft!();
          }
        } else {
          // Vertical swipe
          if (velocity.dy > threshold && onSwipeDown != null) {
            OmnisonicGestureFeedback.hapticFeedback(hapticType);
            onSwipeDown!();
          } else if (velocity.dy < -threshold && onSwipeUp != null) {
            OmnisonicGestureFeedback.hapticFeedback(hapticType);
            onSwipeUp!();
          }
        }
      },
      child: child,
    );
  }
}

/// Internal drop target widget
class _DropTargetWidget<T extends Object> extends StatefulWidget {
  final Widget child;
  final bool Function(T data) onWillAccept;
  final void Function(T data) onAccept;
  final Color? highlightColor;

  const _DropTargetWidget({
    required this.child,
    required this.onWillAccept,
    required this.onAccept,
    this.highlightColor,
  });

  @override
  State<_DropTargetWidget<T>> createState() => _DropTargetWidgetState<T>();
}

class _DropTargetWidgetState<T extends Object>
    extends State<_DropTargetWidget<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isHighlighted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlightColor =
        widget.highlightColor ?? Theme.of(context).colorScheme.primary;

    return DragTarget<T>(
      onWillAccept: (data) {
        if (data != null && widget.onWillAccept(data)) {
          setState(() => _isHighlighted = true);
          _controller.forward();
          return true;
        }
        return false;
      },
      onAccept: (data) {
        widget.onAccept(data);
        setState(() => _isHighlighted = false);
        _controller.reverse();
      },
      onLeave: (data) {
        setState(() => _isHighlighted = false);
        _controller.reverse();
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                border: _isHighlighted
                    ? Border.all(
                        color: highlightColor.withValues(
                          alpha: _animation.value,
                        ),
                        width: 2,
                      )
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: widget.child,
            );
          },
        );
      },
    );
  }
}

/// Animated state widget for smooth state transitions
class _AnimatedStateWidget extends StatefulWidget {
  final Widget child;
  final ComponentState state;
  final Duration duration;
  final Curve curve;

  const _AnimatedStateWidget({
    required this.child,
    required this.state,
    required this.duration,
    required this.curve,
  });

  @override
  State<_AnimatedStateWidget> createState() => _AnimatedStateWidgetState();
}

class _AnimatedStateWidgetState extends State<_AnimatedStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: _getScaleForState(widget.state),
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: _getOpacityForState(widget.state),
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _updateAnimation();
  }

  @override
  void didUpdateWidget(_AnimatedStateWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    _scaleAnimation = Tween<double>(
      begin: _scaleAnimation.value,
      end: _getScaleForState(widget.state),
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _opacityAnimation = Tween<double>(
      begin: _opacityAnimation.value,
      end: _getOpacityForState(widget.state),
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _controller.reset();
    _controller.forward();
  }

  double _getScaleForState(ComponentState state) {
    switch (state) {
      case ComponentState.selected:
        return 1.05;
      case ComponentState.disabled:
        return 0.95;
      case ComponentState.loading:
        return 0.98;
      case ComponentState.error:
        return 1.02;
      case ComponentState.success:
        return 1.03;
      default:
        return 1.0;
    }
  }

  double _getOpacityForState(ComponentState state) {
    switch (state) {
      case ComponentState.disabled:
        return 0.5;
      case ComponentState.loading:
        return 0.7;
      default:
        return 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              decoration: _getDecorationForState(context, widget.state),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }

  BoxDecoration? _getDecorationForState(
    BuildContext context,
    ComponentState state,
  ) {
    final theme = Theme.of(context);

    switch (state) {
      case ComponentState.selected:
        return BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary, width: 2),
          borderRadius: BorderRadius.circular(8),
        );
      case ComponentState.error:
        return BoxDecoration(
          border: Border.all(color: theme.colorScheme.error, width: 1),
          borderRadius: BorderRadius.circular(8),
        );
      case ComponentState.success:
        return BoxDecoration(
          border: Border.all(color: Colors.green, width: 1),
          borderRadius: BorderRadius.circular(8),
        );
      default:
        return null;
    }
  }
}

/// Selectable widget with animated selection feedback
class _SelectableWidget extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? selectedColor;
  final Duration duration;
  final HapticFeedbackType hapticType;

  const _SelectableWidget({
    required this.child,
    required this.isSelected,
    required this.onTap,
    this.selectedColor,
    required this.duration,
    required this.hapticType,
  });

  @override
  State<_SelectableWidget> createState() => _SelectableWidgetState();
}

class _SelectableWidgetState extends State<_SelectableWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _updateAnimations();

    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_SelectableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      _updateAnimations();
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  void _updateAnimations() {
    final theme = Theme.of(context);
    final selectedColor = widget.selectedColor ?? theme.colorScheme.primary;

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: selectedColor.withValues(alpha: 0.1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        OmnisonicGestureFeedback.hapticFeedback(widget.hapticType);
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                borderRadius: BorderRadius.circular(8),
                border: widget.isSelected
                    ? Border.all(
                        color:
                            widget.selectedColor ??
                            Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Loading state widget with animated transitions
class _LoadingStateWidget extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Widget? loadingWidget;
  final Duration duration;

  const _LoadingStateWidget({
    required this.child,
    required this.isLoading,
    this.loadingWidget,
    required this.duration,
  });

  @override
  State<_LoadingStateWidget> createState() => _LoadingStateWidgetState();
}

class _LoadingStateWidgetState extends State<_LoadingStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isLoading) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_LoadingStateWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading) {
      if (widget.isLoading) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedOpacity(
          opacity: widget.isLoading ? 0.5 : 1.0,
          duration: widget.duration,
          child: widget.child,
        ),
        if (widget.isLoading)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.1),
                    child: Center(
                      child:
                          widget.loadingWidget ??
                          const CircularProgressIndicator(),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Disabled state widget with visual feedback
class _DisabledStateWidget extends StatelessWidget {
  final Widget child;
  final bool isDisabled;
  final double disabledOpacity;
  final Duration duration;

  const _DisabledStateWidget({
    required this.child,
    required this.isDisabled,
    required this.disabledOpacity,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isDisabled ? disabledOpacity : 1.0,
      duration: duration,
      child: IgnorePointer(ignoring: isDisabled, child: child),
    );
  }
}
