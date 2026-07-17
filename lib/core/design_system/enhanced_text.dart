import 'package:flutter/material.dart';
import 'typography.dart';
import 'animation_manager.dart';

/// Enhanced text widget with truncation, tooltips, and music metadata differentiation
class EnhancedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool showTooltip;
  final String? tooltipMessage;
  final TextAlign? textAlign;
  final bool selectable;
  final VoidCallback? onTap;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;

  const EnhancedText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.showTooltip = true,
    this.tooltipMessage,
    this.textAlign,
    this.selectable = false,
    this.onTap,
    this.color,
    this.fontSize,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = _buildEffectiveStyle(context);
    final widget = _buildTextWidget(effectiveStyle);

    // Show tooltip if text is truncated and showTooltip is true
    if (showTooltip && _shouldShowTooltip()) {
      return Tooltip(
        message: tooltipMessage ?? text,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 500),
        child: widget,
      );
    }

    return widget;
  }

  TextStyle _buildEffectiveStyle(BuildContext context) {
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium!;

    return baseStyle.copyWith(
      color: color ?? baseStyle.color,
      fontSize: fontSize ?? baseStyle.fontSize,
      fontWeight: fontWeight ?? baseStyle.fontWeight,
    );
  }

  Widget _buildTextWidget(TextStyle effectiveStyle) {
    if (selectable) {
      return SelectableText(
        text,
        style: effectiveStyle,
        maxLines: maxLines,
        textAlign: textAlign,
        onTap: onTap,
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: Text(
          text,
          style: effectiveStyle,
          maxLines: maxLines,
          overflow: overflow ?? TextOverflow.ellipsis,
          textAlign: textAlign,
        ),
      );
    }

    return Text(
      text,
      style: effectiveStyle,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
      textAlign: textAlign,
    );
  }

  bool _shouldShowTooltip() {
    return maxLines != null || overflow == TextOverflow.ellipsis;
  }
}

/// Enhanced text widget specifically for music track titles
class TrackTitleText extends StatelessWidget {
  final String title;
  final bool isPlaying;
  final bool isSelected;
  final VoidCallback? onTap;
  final int maxLines;
  final bool showTooltip;

  const TrackTitleText(
    this.title, {
    super.key,
    this.isPlaying = false,
    this.isSelected = false,
    this.onTap,
    this.maxLines = 1,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color textColor = colorScheme.onSurface;
    if (isPlaying) {
      textColor = colorScheme.primary;
    } else if (isSelected) {
      textColor = colorScheme.primary.withValues(alpha: 0.8);
    }

    return EnhancedText(
      title,
      style: OmnisonicTypography.trackTitle.copyWith(
        color: textColor,
        fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
      ),
      maxLines: maxLines,
      showTooltip: showTooltip,
      onTap: onTap,
    );
  }
}

/// Enhanced text widget specifically for artist names
class ArtistNameText extends StatelessWidget {
  final String artistName;
  final VoidCallback? onTap;
  final int maxLines;
  final bool showTooltip;
  final bool isSecondary;

  const ArtistNameText(
    this.artistName, {
    super.key,
    this.onTap,
    this.maxLines = 1,
    this.showTooltip = true,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return EnhancedText(
      artistName,
      style: OmnisonicTypography.artistName.copyWith(
        color: isSecondary
            ? colorScheme.onSurface.withValues(alpha: 0.7)
            : colorScheme.onSurface.withValues(alpha: 0.8),
      ),
      maxLines: maxLines,
      showTooltip: showTooltip,
      onTap: onTap,
    );
  }
}

/// Enhanced text widget specifically for album titles
class AlbumTitleText extends StatelessWidget {
  final String albumTitle;
  final VoidCallback? onTap;
  final int maxLines;
  final bool showTooltip;
  final bool isSecondary;

  const AlbumTitleText(
    this.albumTitle, {
    super.key,
    this.onTap,
    this.maxLines = 1,
    this.showTooltip = true,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return EnhancedText(
      albumTitle,
      style: OmnisonicTypography.albumTitle.copyWith(
        color: isSecondary
            ? colorScheme.onSurface.withValues(alpha: 0.6)
            : colorScheme.onSurface.withValues(alpha: 0.8),
      ),
      maxLines: maxLines,
      showTooltip: showTooltip,
      onTap: onTap,
    );
  }
}

/// Enhanced text widget for playlist titles
class PlaylistTitleText extends StatelessWidget {
  final String playlistTitle;
  final VoidCallback? onTap;
  final int maxLines;
  final bool showTooltip;
  final bool isLarge;

  const PlaylistTitleText(
    this.playlistTitle, {
    super.key,
    this.onTap,
    this.maxLines = 2,
    this.showTooltip = true,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return EnhancedText(
      playlistTitle,
      style:
          (isLarge
                  ? OmnisonicTypography.headlineSmall
                  : OmnisonicTypography.playlistTitle)
              .copyWith(color: colorScheme.onSurface),
      maxLines: maxLines,
      showTooltip: showTooltip,
      onTap: onTap,
    );
  }
}

/// Enhanced text widget for now playing display
class NowPlayingText extends StatelessWidget {
  final String title;
  final String artist;
  final VoidCallback? onTitleTap;
  final VoidCallback? onArtistTap;
  final bool isLarge;
  final bool showTooltips;

  const NowPlayingText({
    super.key,
    required this.title,
    required this.artist,
    this.onTitleTap,
    this.onArtistTap,
    this.isLarge = false,
    this.showTooltips = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        EnhancedText(
          title,
          style:
              (isLarge
                      ? OmnisonicTypography.titleLarge
                      : OmnisonicTypography.nowPlayingTitle)
                  .copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
          maxLines: isLarge ? 2 : 1,
          showTooltip: showTooltips,
          onTap: onTitleTap,
        ),
        const SizedBox(height: 2),
        EnhancedText(
          artist,
          style:
              (isLarge
                      ? OmnisonicTypography.titleMedium
                      : OmnisonicTypography.nowPlayingArtist)
                  .copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
          maxLines: 1,
          showTooltip: showTooltips,
          onTap: onArtistTap,
        ),
      ],
    );
  }
}

/// Enhanced text widget for duration display
class DurationText extends StatelessWidget {
  final Duration duration;
  final bool showHours;
  final TextStyle? style;

  const DurationText(
    this.duration, {
    super.key,
    this.showHours = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return EnhancedText(
      _formatDuration(duration),
      style: (style ?? OmnisonicTypography.duration).copyWith(
        color: colorScheme.onSurface.withValues(alpha: 0.7),
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      showTooltip: false,
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (showHours && hours > 0) {
      return '${hours.toString().padLeft(1, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(1, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }
}

/// Enhanced text widget for metadata display
class MetadataText extends StatelessWidget {
  final String label;
  final String value;
  final bool isVertical;
  final VoidCallback? onTap;

  const MetadataText({
    super.key,
    required this.label,
    required this.value,
    this.isVertical = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isVertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          EnhancedText(
            label,
            style: OmnisonicTypography.labelSmall.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
            showTooltip: false,
          ),
          const SizedBox(height: 2),
          EnhancedText(
            value,
            style: OmnisonicTypography.metadata.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            onTap: onTap,
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        EnhancedText(
          '$label: ',
          style: OmnisonicTypography.metadata.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
          showTooltip: false,
        ),
        Flexible(
          child: EnhancedText(
            value,
            style: OmnisonicTypography.metadata.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            onTap: onTap,
          ),
        ),
      ],
    );
  }
}

/// Enhanced text widget with expandable functionality
class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final String expandText;
  final String collapseText;
  final Color? linkColor;

  const ExpandableText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 3,
    this.expandText = 'Show more',
    this.collapseText = 'Show less',
    this.linkColor,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AnimationManager.normalDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AnimationManager.standardCurve,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveStyle = widget.style ?? theme.textTheme.bodyMedium!;
    final linkColor = widget.linkColor ?? colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(text: widget.text, style: effectiveStyle);

        final painter = TextPainter(
          text: span,
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        );

        painter.layout(maxWidth: constraints.maxWidth);

        final isTextOverflowing = painter.didExceedMaxLines;

        if (!isTextOverflowing) {
          return Text(widget.text, style: effectiveStyle);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedCrossFade(
              firstChild: Text(
                widget.text,
                style: effectiveStyle,
                maxLines: widget.maxLines,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: FadeTransition(
                opacity: _fadeAnimation,
                child: Text(widget.text, style: effectiveStyle),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: AnimationManager.normalDuration,
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _toggleExpanded,
              child: Text(
                _isExpanded ? widget.collapseText : widget.expandText,
                style: effectiveStyle.copyWith(
                  color: linkColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
}
