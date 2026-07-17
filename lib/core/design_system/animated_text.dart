import 'package:flutter/material.dart';
import 'animation_manager.dart';

/// Animated text widget with various text animation effects
class AnimatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAnimationType animationType;
  final Duration? duration;
  final Curve? curve;
  final bool autoStart;
  final VoidCallback? onComplete;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AnimatedText(
    this.text, {
    super.key,
    this.style,
    this.animationType = TextAnimationType.fadeIn,
    this.duration,
    this.curve,
    this.autoStart = true,
    this.onComplete,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  State<AnimatedText> createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    if (widget.autoStart) {
      _controller.forward();
    }
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: widget.duration ?? _getDefaultDuration(),
      vsync: this,
    );

    final curve = CurvedAnimation(
      parent: _controller,
      curve: widget.curve ?? _getDefaultCurve(),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);

    _slideAnimation = Tween<Offset>(
      begin: _getSlideBegin(),
      end: Offset.zero,
    ).animate(curve);

    _scaleAnimation = Tween<double>(
      begin: _getScaleBegin(),
      end: 1.0,
    ).animate(curve);

    if (widget.onComplete != null) {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete!();
        }
      });
    }
  }

  Duration _getDefaultDuration() {
    switch (widget.animationType) {
      case TextAnimationType.fadeIn:
      case TextAnimationType.fadeOut:
        return AnimationManager.normalDuration;
      case TextAnimationType.slideUp:
      case TextAnimationType.slideDown:
      case TextAnimationType.slideLeft:
      case TextAnimationType.slideRight:
        return AnimationManager.normalDuration;
      case TextAnimationType.scaleIn:
      case TextAnimationType.scaleOut:
        return AnimationManager.fastDuration;
      case TextAnimationType.bounce:
        return AnimationManager.slowDuration;
      case TextAnimationType.typewriter:
        return Duration(milliseconds: widget.text.length * 50);
      case TextAnimationType.shimmer:
        return const Duration(milliseconds: 1500);
    }
  }

  Curve _getDefaultCurve() {
    switch (widget.animationType) {
      case TextAnimationType.fadeIn:
      case TextAnimationType.fadeOut:
        return AnimationManager.standardCurve;
      case TextAnimationType.slideUp:
      case TextAnimationType.slideDown:
      case TextAnimationType.slideLeft:
      case TextAnimationType.slideRight:
        return AnimationManager.slideOutCurve;
      case TextAnimationType.scaleIn:
      case TextAnimationType.scaleOut:
        return AnimationManager.springCurve;
      case TextAnimationType.bounce:
        return Curves.elasticOut;
      case TextAnimationType.typewriter:
        return Curves.linear;
      case TextAnimationType.shimmer:
        return Curves.linear;
    }
  }

  Offset _getSlideBegin() {
    switch (widget.animationType) {
      case TextAnimationType.slideUp:
        return const Offset(0, 1);
      case TextAnimationType.slideDown:
        return const Offset(0, -1);
      case TextAnimationType.slideLeft:
        return const Offset(1, 0);
      case TextAnimationType.slideRight:
        return const Offset(-1, 0);
      default:
        return Offset.zero;
    }
  }

  double _getScaleBegin() {
    switch (widget.animationType) {
      case TextAnimationType.scaleIn:
        return 0.0;
      case TextAnimationType.scaleOut:
        return 1.2;
      case TextAnimationType.bounce:
        return 0.0;
      default:
        return 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void startAnimation() {
    _controller.forward();
  }

  void reverseAnimation() {
    _controller.reverse();
  }

  void resetAnimation() {
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.animationType) {
      case TextAnimationType.fadeIn:
      case TextAnimationType.fadeOut:
        return FadeTransition(opacity: _animation, child: _buildText());

      case TextAnimationType.slideUp:
      case TextAnimationType.slideDown:
      case TextAnimationType.slideLeft:
      case TextAnimationType.slideRight:
        return SlideTransition(position: _slideAnimation, child: _buildText());

      case TextAnimationType.scaleIn:
      case TextAnimationType.scaleOut:
      case TextAnimationType.bounce:
        return ScaleTransition(scale: _scaleAnimation, child: _buildText());

      case TextAnimationType.typewriter:
        return _buildTypewriterText();

      case TextAnimationType.shimmer:
        return _buildShimmerText();
    }
  }

  Widget _buildText() {
    return Text(
      widget.text,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }

  Widget _buildTypewriterText() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final visibleCharacters = (_animation.value * widget.text.length)
            .floor();
        final visibleText = widget.text.substring(0, visibleCharacters);

        return Text(
          visibleText,
          style: widget.style,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        );
      },
    );
  }

  Widget _buildShimmerText() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.transparent,
                Colors.white,
                Colors.transparent,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: widget.style?.copyWith(color: Colors.white),
            textAlign: widget.textAlign,
            maxLines: widget.maxLines,
            overflow: widget.overflow,
          ),
        );
      },
    );
  }
}

/// Animation types for text animations
enum TextAnimationType {
  fadeIn,
  fadeOut,
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
  scaleIn,
  scaleOut,
  bounce,
  typewriter,
  shimmer,
}

/// Animated text widget for state changes with smooth transitions
class StateChangeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration? duration;
  final Curve? curve;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const StateChangeText(
    this.text, {
    super.key,
    this.style,
    this.duration,
    this.curve,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  State<StateChangeText> createState() => _StateChangeTextState();
}

class _StateChangeTextState extends State<StateChangeText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  String _currentText = '';

  @override
  void initState() {
    super.initState();
    _currentText = widget.text;
    _controller = AnimationController(
      duration: widget.duration ?? AnimationManager.fastDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve ?? AnimationManager.standardCurve,
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(StateChangeText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text) {
      _currentText = widget.text;
      _animateTextChange();
    }
  }

  void _animateTextChange() {
    _controller.reverse().then((_) {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        _currentText,
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      ),
    );
  }
}

/// Animated text widget for emphasis effects
class EmphasisText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final EmphasisType emphasisType;
  final Duration? duration;
  final bool autoStart;
  final VoidCallback? onTap;

  const EmphasisText(
    this.text, {
    super.key,
    this.style,
    this.emphasisType = EmphasisType.pulse,
    this.duration,
    this.autoStart = false,
    this.onTap,
  });

  @override
  State<EmphasisText> createState() => _EmphasisTextState();
}

class _EmphasisTextState extends State<EmphasisText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? AnimationManager.normalDuration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: _getBeginValue(),
      end: _getEndValue(),
    ).animate(CurvedAnimation(parent: _controller, curve: _getCurve()));

    if (widget.autoStart) {
      _startEmphasis();
    }
  }

  double _getBeginValue() {
    switch (widget.emphasisType) {
      case EmphasisType.pulse:
      case EmphasisType.bounce:
        return 1.0;
      case EmphasisType.glow:
        return 0.0;
      case EmphasisType.shake:
        return 0.0;
    }
  }

  double _getEndValue() {
    switch (widget.emphasisType) {
      case EmphasisType.pulse:
        return 1.1;
      case EmphasisType.bounce:
        return 1.2;
      case EmphasisType.glow:
        return 1.0;
      case EmphasisType.shake:
        return 1.0;
    }
  }

  Curve _getCurve() {
    switch (widget.emphasisType) {
      case EmphasisType.pulse:
        return Curves.easeInOut;
      case EmphasisType.bounce:
        return Curves.elasticOut;
      case EmphasisType.glow:
        return Curves.easeInOut;
      case EmphasisType.shake:
        return Curves.elasticInOut;
    }
  }

  void _startEmphasis() {
    switch (widget.emphasisType) {
      case EmphasisType.pulse:
      case EmphasisType.bounce:
        _controller.forward().then((_) {
          if (mounted) {
            _controller.reverse();
          }
        });
        break;
      case EmphasisType.glow:
        _controller.repeat(reverse: true);
        break;
      case EmphasisType.shake:
        _controller.repeat(
          reverse: true,
          period: const Duration(milliseconds: 100),
        );
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Text(widget.text, style: widget.style);

    if (widget.onTap != null) {
      child = GestureDetector(
        onTap: () {
          _startEmphasis();
          widget.onTap?.call();
        },
        child: child,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        switch (widget.emphasisType) {
          case EmphasisType.pulse:
          case EmphasisType.bounce:
            return Transform.scale(scale: _animation.value, child: child);

          case EmphasisType.glow:
            return Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: _animation.value * 0.5,
                    ),
                    blurRadius: _animation.value * 10,
                    spreadRadius: _animation.value * 2,
                  ),
                ],
              ),
              child: child,
            );

          case EmphasisType.shake:
            return Transform.translate(
              offset: Offset(
                _animation.value *
                    2 *
                    ((_controller.value * 4).floor() % 2 == 0 ? 1 : -1),
                0,
              ),
              child: child,
            );
        }
      },
      child: child,
    );
  }
}

/// Emphasis types for text emphasis animations
enum EmphasisType { pulse, bounce, glow, shake }

/// Animated loading text widget with various loading states
class LoadingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final LoadingType loadingType;
  final Duration? duration;

  const LoadingText(
    this.text, {
    super.key,
    this.style,
    this.loadingType = LoadingType.dots,
    this.duration,
  });

  @override
  State<LoadingText> createState() => _LoadingTextState();
}

class _LoadingTextState extends State<LoadingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animation = IntTween(begin: 0, end: _getMaxSteps()).animate(_controller);

    _controller.repeat();
  }

  int _getMaxSteps() {
    switch (widget.loadingType) {
      case LoadingType.dots:
        return 3;
      case LoadingType.wave:
        return widget.text.length;
      case LoadingType.fade:
        return 1;
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
      animation: _animation,
      builder: (context, child) {
        switch (widget.loadingType) {
          case LoadingType.dots:
            return Text(
              '${widget.text}${'.' * (_animation.value + 1)}',
              style: widget.style,
            );

          case LoadingType.wave:
            return _buildWaveText();

          case LoadingType.fade:
            return Opacity(
              opacity: (_controller.value * 2).clamp(0.0, 1.0),
              child: Text(widget.text, style: widget.style),
            );
        }
      },
    );
  }

  Widget _buildWaveText() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.text.length, (index) {
        final progress = (_animation.value - index).clamp(0, 1).toDouble();
        final scale = 1.0 + (0.3 * progress);

        return Transform.scale(
          scale: scale,
          child: Text(
            widget.text[index],
            style: widget.style?.copyWith(
              color: widget.style?.color?.withValues(
                alpha: 0.5 + (0.5 * progress),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Loading types for text loading animations
enum LoadingType { dots, wave, fade }
