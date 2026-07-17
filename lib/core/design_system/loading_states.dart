import 'dart:math' show pi, sin;
import 'package:flutter/material.dart';
import 'spacing.dart';

/// Enum for different loading contexts
enum LoadingContext {
  music,
  search,
  sync,
  download,
  library,
  playlist,
  artist,
  album,
}

/// Elegant loading states with skeleton screens and progress indicators
/// for the Omnisonic design system.
class OmnisonicLoadingStates {
  OmnisonicLoadingStates._();

  /// Creates a skeleton loading widget that mimics the shape of content
  static Widget skeleton({
    required double width,
    required double height,
    BorderRadius? borderRadius,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return _SkeletonWidget(
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(4),
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }

  /// Creates a skeleton for album artwork
  static Widget albumArtworkSkeleton({
    double size = 120,
    BorderRadius? borderRadius,
  }) {
    return skeleton(
      width: size,
      height: size,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
    );
  }

  /// Creates a skeleton for track list items
  static Widget trackListItemSkeleton() {
    return Padding(
      padding: OmnisonicInsets.allMd,
      child: Row(
        children: [
          skeleton(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(4),
          ),
          SizedBox(width: OmnisonicSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                skeleton(width: double.infinity, height: 16),
                SizedBox(height: OmnisonicSpacing.xs),
                skeleton(width: 120, height: 14),
              ],
            ),
          ),
          SizedBox(width: OmnisonicSpacing.md),
          skeleton(width: 40, height: 14),
        ],
      ),
    );
  }

  /// Creates a skeleton for album cards
  static Widget albumCardSkeleton({double width = 160, double height = 200}) {
    return Container(
      width: width,
      height: height,
      padding: OmnisonicInsets.allSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          skeleton(
            width: width - 16,
            height: width - 16,
            borderRadius: BorderRadius.circular(8),
          ),
          SizedBox(height: OmnisonicSpacing.sm),
          skeleton(width: width - 16, height: 16),
          SizedBox(height: OmnisonicSpacing.xs),
          skeleton(width: (width - 16) * 0.7, height: 14),
        ],
      ),
    );
  }

  /// Creates a skeleton for artist cards
  static Widget artistCardSkeleton({double size = 120}) {
    return Container(
      width: size,
      padding: OmnisonicInsets.allSm,
      child: Column(
        children: [
          skeleton(
            width: size - 16,
            height: size - 16,
            borderRadius: BorderRadius.circular((size - 16) / 2),
          ),
          SizedBox(height: OmnisonicSpacing.sm),
          skeleton(width: size - 16, height: 16),
        ],
      ),
    );
  }

  /// Creates an animated progress indicator
  static Widget progressIndicator({
    Color? color,
    double strokeWidth = 3.0,
    double size = 24.0,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: color != null ? AlwaysStoppedAnimation<Color>(color) : null,
      ),
    );
  }

  /// Creates a linear progress indicator with animation
  static Widget linearProgress({
    double? value,
    Color? backgroundColor,
    Color? valueColor,
    double height = 4.0,
    BorderRadius? borderRadius,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
        child: LinearProgressIndicator(
          value: value,
          backgroundColor: backgroundColor,
          valueColor: valueColor != null
              ? AlwaysStoppedAnimation<Color>(valueColor)
              : null,
        ),
      ),
    );
  }

  /// Creates a pulsing dot indicator
  static Widget pulsingDots({
    int count = 3,
    Color? color,
    double size = 8.0,
    Duration duration = const Duration(milliseconds: 1200),
  }) {
    return _PulsingDotsWidget(
      count: count,
      color: color,
      size: size,
      duration: duration,
    );
  }

  /// Creates a wave loading animation
  static Widget waveIndicator({
    Color? color,
    double size = 40.0,
    int barCount = 5,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    return _WaveIndicatorWidget(
      color: color,
      size: size,
      barCount: barCount,
      duration: duration,
    );
  }

  /// Creates a loading overlay for the entire screen
  static Widget screenOverlay({
    required Widget child,
    bool isLoading = false,
    String? message,
    Color? backgroundColor,
  }) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  progressIndicator(size: 48),
                  if (message != null) ...[
                    SizedBox(height: OmnisonicSpacing.lg),
                    Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Creates contextual loading animations based on content type
  static Widget contextualLoading({
    required LoadingContext context,
    String? message,
    Color? color,
  }) {
    return _ContextualLoadingWidget(
      context: context,
      message: message,
      color: color,
    );
  }

  /// Creates a music-specific loading animation
  static Widget musicLoading({String? message, Color? color}) {
    return contextualLoading(
      context: LoadingContext.music,
      message: message,
      color: color,
    );
  }

  /// Creates a search-specific loading animation
  static Widget searchLoading({String? message, Color? color}) {
    return contextualLoading(
      context: LoadingContext.search,
      message: message,
      color: color,
    );
  }

  /// Creates a sync-specific loading animation
  static Widget syncLoading({String? message, Color? color}) {
    return contextualLoading(
      context: LoadingContext.sync,
      message: message,
      color: color,
    );
  }

  /// Creates a download-specific loading animation
  static Widget downloadLoading({
    String? message,
    double? progress,
    Color? color,
  }) {
    return _DownloadLoadingWidget(
      message: message,
      progress: progress,
      color: color,
    );
  }

  /// Creates an adaptive loading indicator that changes based on content
  static Widget adaptiveLoading({
    required String contentType,
    String? message,
    Color? color,
    Duration? estimatedDuration,
  }) {
    return _AdaptiveLoadingWidget(
      contentType: contentType,
      message: message,
      color: color,
      estimatedDuration: estimatedDuration,
    );
  }
}

/// Internal skeleton widget with shimmer animation
class _SkeletonWidget extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const _SkeletonWidget({
    required this.width,
    required this.height,
    required this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<_SkeletonWidget> createState() => _SkeletonWidgetState();
}

class _SkeletonWidgetState extends State<_SkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor =
        widget.baseColor ?? (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final highlightColor =
        widget.highlightColor ??
        (isDark ? Colors.grey[700]! : Colors.grey[100]!);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Internal pulsing dots widget
class _PulsingDotsWidget extends StatefulWidget {
  final int count;
  final Color? color;
  final double size;
  final Duration duration;

  const _PulsingDotsWidget({
    required this.count,
    this.color,
    required this.size,
    required this.duration,
  });

  @override
  State<_PulsingDotsWidget> createState() => _PulsingDotsWidgetState();
}

class _PulsingDotsWidgetState extends State<_PulsingDotsWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.count,
      (index) => AnimationController(duration: widget.duration, vsync: this),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    // Start animations with staggered delays
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(
        Duration(milliseconds: i * 200),
        () => _controllers[i].repeat(reverse: true),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.count, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.2),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(
                  alpha: 0.3 + (_animations[index].value * 0.7),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Internal wave indicator widget
class _WaveIndicatorWidget extends StatefulWidget {
  final Color? color;
  final double size;
  final int barCount;
  final Duration duration;

  const _WaveIndicatorWidget({
    this.color,
    required this.size,
    required this.barCount,
    required this.duration,
  });

  @override
  State<_WaveIndicatorWidget> createState() => _WaveIndicatorWidgetState();
}

class _WaveIndicatorWidgetState extends State<_WaveIndicatorWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.barCount,
      (index) => AnimationController(duration: widget.duration, vsync: this),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.2,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    // Start animations with staggered delays
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(
        Duration(milliseconds: i * 100),
        () => _controllers[i].repeat(reverse: true),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final barWidth = widget.size / (widget.barCount * 2);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                width: barWidth,
                height: widget.size * _animations[index].value,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(barWidth / 2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// Contextual loading widget that adapts to different content types
class _ContextualLoadingWidget extends StatefulWidget {
  final LoadingContext context;
  final String? message;
  final Color? color;

  const _ContextualLoadingWidget({
    required this.context,
    this.message,
    this.color,
  });

  @override
  State<_ContextualLoadingWidget> createState() =>
      _ContextualLoadingWidgetState();
}

class _ContextualLoadingWidgetState extends State<_ContextualLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _getDurationForContext(widget.context),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Duration _getDurationForContext(LoadingContext context) {
    switch (context) {
      case LoadingContext.music:
        return const Duration(milliseconds: 2000);
      case LoadingContext.search:
        return const Duration(milliseconds: 1500);
      case LoadingContext.sync:
        return const Duration(milliseconds: 3000);
      case LoadingContext.download:
        return const Duration(milliseconds: 1000);
      default:
        return const Duration(milliseconds: 2000);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildContextualIndicator(color),
        if (widget.message != null) ...[
          SizedBox(height: OmnisonicSpacing.md),
          Text(
            widget.message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildContextualIndicator(Color color) {
    switch (widget.context) {
      case LoadingContext.music:
        return _buildMusicIndicator(color);
      case LoadingContext.search:
        return _buildSearchIndicator(color);
      case LoadingContext.sync:
        return _buildSyncIndicator(color);
      case LoadingContext.download:
        return _buildDownloadIndicator(color);
      default:
        return OmnisonicLoadingStates.progressIndicator(color: color);
    }
  }

  Widget _buildMusicIndicator(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final delay = index * 0.2;
            final animValue = (_animation.value + delay) % 1.0;
            final height = 20 + (sin(animValue * 2 * pi) * 15);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3 + (animValue * 0.7)),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildSearchIndicator(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
            Transform.rotate(
              angle: _animation.value * 2 * pi,
              child: Icon(Icons.search, color: color, size: 20),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSyncIndicator(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value * 2 * pi,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.sync, color: color, size: 32),
              Positioned(
                top: 0,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDownloadIndicator(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_download, color: color, size: 32),
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _animation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Download-specific loading widget with progress
class _DownloadLoadingWidget extends StatelessWidget {
  final String? message;
  final double? progress;
  final Color? color;

  const _DownloadLoadingWidget({this.message, this.progress, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = this.color ?? theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_download, color: color, size: 48),
        SizedBox(height: OmnisonicSpacing.md),
        Container(
          width: 200,
          height: 6,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress ?? 0.0,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        if (message != null) ...[
          SizedBox(height: OmnisonicSpacing.sm),
          Text(
            message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (progress != null) ...[
          SizedBox(height: OmnisonicSpacing.xs),
          Text(
            '${(progress! * 100).toInt()}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }
}

/// Adaptive loading widget that changes based on content type
class _AdaptiveLoadingWidget extends StatefulWidget {
  final String contentType;
  final String? message;
  final Color? color;
  final Duration? estimatedDuration;

  const _AdaptiveLoadingWidget({
    required this.contentType,
    this.message,
    this.color,
    this.estimatedDuration,
  });

  @override
  State<_AdaptiveLoadingWidget> createState() => _AdaptiveLoadingWidgetState();
}

class _AdaptiveLoadingWidgetState extends State<_AdaptiveLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.estimatedDuration ?? const Duration(seconds: 3),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAdaptiveIndicator(color),
            if (widget.message != null) ...[
              SizedBox(height: OmnisonicSpacing.md),
              Text(
                widget.message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (widget.estimatedDuration != null) ...[
              SizedBox(height: OmnisonicSpacing.sm),
              Container(
                width: 150,
                height: 4,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAdaptiveIndicator(Color color) {
    switch (widget.contentType.toLowerCase()) {
      case 'music':
      case 'audio':
        return Icon(Icons.music_note, color: color, size: 32);
      case 'playlist':
        return Icon(Icons.playlist_play, color: color, size: 32);
      case 'album':
        return Icon(Icons.album, color: color, size: 32);
      case 'artist':
        return Icon(Icons.person, color: color, size: 32);
      case 'library':
        return Icon(Icons.library_music, color: color, size: 32);
      default:
        return OmnisonicLoadingStates.progressIndicator(color: color);
    }
  }
}
