import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../../core/design_system/design_system.dart';

/// Audio visualizer widget with animated equalizer and waveform displays
///
/// Features:
/// - Animated equalizer visualizations
/// - Waveform displays during playback
/// - Customizable colors and animation styles
/// - Performance-optimized animations
class AudioVisualizer extends StatefulWidget {
  const AudioVisualizer({
    super.key,
    required this.isPlaying,
    this.type = AudioVisualizerType.equalizer,
    this.barCount = 32,
    this.height = 100,
    this.color,
    this.animationSpeed = 1.0,
  });

  final bool isPlaying;
  final AudioVisualizerType type;
  final int barCount;
  final double height;
  final Color? color;
  final double animationSpeed;

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _barControllers;
  late List<Animation<double>> _barAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: (1000 / widget.animationSpeed).round()),
      vsync: this,
    );

    _barControllers = List.generate(
      widget.barCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: (200 + (index * 50) % 800).round()),
        vsync: this,
      ),
    );

    _barAnimations = _barControllers.map((controller) {
      return Tween<double>(
        begin: 0.1,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    if (widget.isPlaying) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  void _startAnimations() {
    _animationController.repeat();

    for (int i = 0; i < _barControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (mounted && widget.isPlaying) {
          _barControllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimations() {
    _animationController.stop();
    for (final controller in _barControllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (final controller in _barControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case AudioVisualizerType.equalizer:
        return _buildEqualizer();
      case AudioVisualizerType.waveform:
        return _buildWaveform();
      case AudioVisualizerType.circular:
        return _buildCircularVisualizer();
    }
  }

  Widget _buildEqualizer() {
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          return AnimatedBuilder(
            animation: _barAnimations[index],
            builder: (context, child) {
              final height = widget.height * _barAnimations[index].value;
              return Container(
                width: math.max(2.0, (300 / widget.barCount) - 2),
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      widget.color ?? OmnisonicColors.primaryPurple,
                      (widget.color ?? OmnisonicColors.primaryBlue).withValues(
                        alpha: 0.6,
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildWaveform() {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            painter: WaveformPainter(
              progress: _animationController.value,
              color: widget.color ?? OmnisonicColors.primaryPurple,
              isPlaying: widget.isPlaying,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildCircularVisualizer() {
    return SizedBox(
      width: widget.height,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            painter: CircularVisualizerPainter(
              progress: _animationController.value,
              barAnimations: _barAnimations,
              color: widget.color ?? OmnisonicColors.primaryPurple,
              isPlaying: widget.isPlaying,
            ),
            size: Size(widget.height, widget.height),
          );
        },
      ),
    );
  }
}

/// Custom painter for waveform visualization
class WaveformPainter extends CustomPainter {
  const WaveformPainter({
    required this.progress,
    required this.color,
    required this.isPlaying,
  });

  final double progress;
  final Color color;
  final bool isPlaying;

  @override
  void paint(Canvas canvas, Size size) {
    if (!isPlaying) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final centerY = size.height / 2;

    // Generate waveform points
    for (double x = 0; x < size.width; x += 2) {
      final normalizedX = x / size.width;
      final frequency = 4 + (normalizedX * 8); // Varying frequency
      final amplitude =
          (size.height / 4) *
          math.sin(normalizedX * math.pi * 2) *
          math.sin((progress + normalizedX) * math.pi * frequency);

      final y = centerY + amplitude;

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        isPlaying != oldDelegate.isPlaying;
  }
}

/// Custom painter for circular visualization
class CircularVisualizerPainter extends CustomPainter {
  const CircularVisualizerPainter({
    required this.progress,
    required this.barAnimations,
    required this.color,
    required this.isPlaying,
  });

  final double progress;
  final List<Animation<double>> barAnimations;
  final Color color;
  final bool isPlaying;

  @override
  void paint(Canvas canvas, Size size) {
    if (!isPlaying) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < barAnimations.length; i++) {
      final angle = (i / barAnimations.length) * 2 * math.pi;
      final barHeight = 20 * barAnimations[i].value;

      final startX = center.dx + math.cos(angle) * radius;
      final startY = center.dy + math.sin(angle) * radius;
      final endX = center.dx + math.cos(angle) * (radius + barHeight);
      final endY = center.dy + math.sin(angle) * (radius + barHeight);

      paint.color = color.withValues(
        alpha: 0.3 + (barAnimations[i].value * 0.7),
      );

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(CircularVisualizerPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        isPlaying != oldDelegate.isPlaying;
  }
}

/// Queue update animation widget
class QueueUpdateAnimation extends StatefulWidget {
  const QueueUpdateAnimation({
    super.key,
    required this.child,
    required this.queueLength,
  });

  final Widget child;
  final int queueLength;

  @override
  State<QueueUpdateAnimation> createState() => _QueueUpdateAnimationState();
}

class _QueueUpdateAnimationState extends State<QueueUpdateAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  int _previousQueueLength = 0;

  @override
  void initState() {
    super.initState();
    _previousQueueLength = widget.queueLength;

    _controller = AnimationController(
      duration: AnimationManager.normalDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(QueueUpdateAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.queueLength != _previousQueueLength) {
      _controller.reset();
      _controller.forward();
      _previousQueueLength = widget.queueLength;
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
          child: Opacity(opacity: _opacityAnimation.value, child: widget.child),
        );
      },
    );
  }
}

/// Types of audio visualizations
enum AudioVisualizerType { equalizer, waveform, circular }
