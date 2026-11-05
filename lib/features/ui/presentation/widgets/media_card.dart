import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/utils/animation_utils.dart';
import 'art_tint.dart';
import 'cover_art.dart';

/// The one card for albums, artists and playlists.
///
/// Replaces `FeishinCard` and the Home page's own hover card, which had
/// drifted apart: one ignored taps on its hidden overlay and offered its
/// actions on long press, the other did neither; one had press feedback and
/// a pointer cursor, the other was a bare `GestureDetector` with no focus or
/// semantics.
///
/// - **Pointer**: hover reveals the overlay (shuffle, play, star).
/// - **Touch**: tap opens; long press calls [onShowActions], which should
///   offer the same actions in a sheet.
/// - **Keyboard**: the card is focusable; focus reveals the overlay and Tab
///   moves into its buttons. Right-click and the context-menu key also call
///   [onShowActions].
/// - **Screen readers**: one button with [title] and [subtitle], plus the
///   overlay's labelled buttons.
///
/// Sizing: with [width] the card is a fixed-width carousel item; without it,
/// it fills its cell. In a bounded-height cell the art takes what the text
/// leaves; with unbounded height (a `Wrap`, a column) the art is square.
/// Use [MediaCard.extentFor] to size grid cells so the art is always square.
class MediaCard extends StatefulWidget {
  const MediaCard({
    super.key,
    required this.title,
    this.subtitle,
    this.meta,
    this.imageUrl,
    this.shape = CoverArtShape.rounded,
    this.fallbackIcon = OmnisonicIcons.album,
    this.width,
    this.titleMaxLines = 1,
    this.onTap,
    this.onPlay,
    this.onShuffle,
    this.onStar,
    this.isStarred = false,
    this.onShowActions,
    this.badge,
    this.semanticLabel,
    this.seed,
  });

  final String title;
  final String? subtitle;
  final String? meta;
  final String? imageUrl;
  final CoverArtShape shape;
  final IconData fallbackIcon;

  /// Fixed card width, for carousels. Null fills the cell.
  final double? width;
  final int titleMaxLines;

  /// Opens the item.
  final VoidCallback? onTap;

  /// Overlay actions, shown on hover or focus. Each is omitted when null.
  final VoidCallback? onPlay;
  final VoidCallback? onShuffle;
  final VoidCallback? onStar;
  final bool isStarred;

  /// Long press, right-click and the context-menu key: show the actions
  /// sheet. This is how touch users reach the overlay's actions.
  final VoidCallback? onShowActions;

  /// Small widget pinned to the art's bottom-left corner on a glass chip,
  /// typically a [ServerDot] or [ServerDotStack].
  final Widget? badge;

  /// Overrides the label a screen reader announces.
  final String? semanticLabel;

  /// What the placeholder cover's hue follows. Defaults to [title].
  final String? seed;

  /// Height of the text block under the art for the given lines, at the
  /// current text scale. Grid cells are `width + textBlockHeight`.
  static double textBlockHeight(
    BuildContext context, {
    int titleLines = 1,
    bool subtitle = true,
    bool meta = false,
  }) {
    // Line heights of cardTitle (13 × 1.3), cardSubtitle (12 × 1.3) and
    // cardMeta (11 × 1.3), plus the 8px gap above and 2px above meta.
    var text = 13 * 1.3 * titleLines;
    if (subtitle) text += 12 * 1.3;
    if (meta) text += 2 + 11 * 1.3;
    return 8 + MediaQuery.textScalerOf(context).scale(text) + 2;
  }

  /// The main-axis extent of a grid cell [width] wide, so the art stays
  /// square at any column width and text size.
  static double extentFor(
    BuildContext context,
    double width, {
    int titleLines = 1,
    bool subtitle = true,
    bool meta = false,
  }) =>
      width +
      textBlockHeight(
        context,
        titleLines: titleLines,
        subtitle: subtitle,
        meta: meta,
      );

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> with ArtTintMixin {
  bool _hovering = false;
  bool _focusWithin = false;
  bool _pressed = false;

  /// Distance between the portrait's edge and the hover ring.
  static const double _ringGap = 4;

  bool get _overlayVisible => _hovering || _focusWithin;

  bool get _hasOverlay =>
      widget.onPlay != null ||
      widget.onShuffle != null ||
      widget.onStar != null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCircle = widget.shape == CoverArtShape.circle;
    final radius = BorderRadius.circular(
      isCircle ? OmnisonicRadius.full : OmnisonicRadius.art,
    );
    final fast = AnimationUtils.adjustedDuration(
      context,
      AnimationManager.fastDuration,
    );

    // The cover's own colour lights the shadow under it while the card is
    // active. Extraction (cached per URL) only starts on the first hover,
    // not for every card in a long grid.
    if (_overlayVisible) updateArtTint(widget.imageUrl);
    final glow = artTint ?? scheme.primary;
    final shadow = _hovering
        ? OmnisonicShadows.artGlow(glow, alpha: 0.5)
        : OmnisonicShadows.art;

    final art = AspectRatio(
      aspectRatio: 1,
      child: AnimatedScale(
        scale: _hovering ? 1.03 : 1.0,
        duration: fast,
        curve: AnimationManager.standardCurve,
        child: AnimatedContainer(
          duration: fast,
          decoration: BoxDecoration(borderRadius: radius, boxShadow: shadow),
          child: Stack(
            fit: StackFit.expand,
            // The artist ring sits outside the portrait.
            clipBehavior: Clip.none,
            children: [
              CoverArt(
                url: widget.imageUrl,
                shape: widget.shape,
                fallbackIcon: widget.fallbackIcon,
                seed: widget.seed ?? widget.title,
              ),
              if (isCircle)
                // An artist: no Play disc, so the hover answer is a soft
                // Aurora ring 2 px outside the portrait.
                Positioned(
                  left: -_ringGap,
                  top: -_ringGap,
                  right: -_ringGap,
                  bottom: -_ringGap,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _hovering ? 1 : 0,
                      duration: fast,
                      child: CustomPaint(
                        painter: _AuroraRingPainter(
                          OmnisonicBrand.of(context).auroraSoft,
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.badge != null)
                // Top-left: the bottom-right belongs to the Play disc.
                Positioned(
                  left: OmnisonicSpacing.sm,
                  top: OmnisonicSpacing.sm,
                  child: GlassSurface(
                    borderRadius: BorderRadius.circular(OmnisonicRadius.full),
                    padding: const EdgeInsets.symmetric(
                      horizontal: OmnisonicSpacing.xs + OmnisonicSpacing.xxs,
                      vertical: OmnisonicSpacing.xs,
                    ),
                    child: widget.badge!,
                  ),
                ),
              if (_hasOverlay)
                // A transparent overlay still takes taps, so it is only hit
                // testable while it is showing.
                IgnorePointer(
                  ignoring: !_overlayVisible,
                  child: AnimatedOpacity(
                    opacity: _overlayVisible ? 1 : 0,
                    duration: fast,
                    child: ClipRRect(
                      borderRadius: radius,
                      child: ColoredBox(
                        color: OmnisonicColors.scrimHover,
                        child: _buildOverlayActions(fast),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    final text = Padding(
      padding: const EdgeInsets.only(top: OmnisonicSpacing.sm),
      child: Column(
        crossAxisAlignment: isCircle
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: OmnisonicTypography.cardTitle.copyWith(
              color: scheme.onSurface,
            ),
            maxLines: widget.titleMaxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: isCircle ? TextAlign.center : TextAlign.start,
          ),
          if (widget.subtitle != null)
            Text(
              widget.subtitle!,
              style: OmnisonicTypography.cardSubtitle.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (widget.meta != null) ...[
            const SizedBox(height: OmnisonicSpacing.xxs),
            Text(
              widget.meta!,
              style: OmnisonicTypography.cardMeta.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    final body = LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedHeight;
        return Column(
          mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (bounded)
              Flexible(
                child: Align(alignment: Alignment.topCenter, child: art),
              )
            else
              art,
            text,
          ],
        );
      },
    );

    final label =
        widget.semanticLabel ??
        [widget.title, widget.subtitle].whereType<String>().join(', ');

    Widget card = Focus(
      // Tracks focus anywhere inside the card — on the card itself or on one
      // of the overlay's buttons — without taking focus itself.
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) => setState(() => _focusWithin = focused),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Semantics(
          button: true,
          label: label,
          onLongPressHint: widget.onShowActions != null ? 'Show actions' : null,
          excludeSemantics: !_hasOverlay,
          child: CallbackShortcuts(
            bindings: {
              if (widget.onShowActions != null) ...{
                const SingleActivator(LogicalKeyboardKey.contextMenu):
                    widget.onShowActions!,
                const SingleActivator(LogicalKeyboardKey.f10, shift: true):
                    widget.onShowActions!,
              },
            },
            // Its own transparent Material, so press, hover and focus ink
            // draws on the card and not on whatever glass pane is below.
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                // Ink on the card is a soft glow, not a grey slab: the art
                // already answers the hover with its lift and overlay.
                borderRadius: BorderRadius.circular(OmnisonicRadius.art),
                hoverColor: Colors.transparent,
                onTap: widget.onTap,
                onLongPress: widget.onShowActions,
                onSecondaryTap: widget.onShowActions,
                // Highlight is only the card itself being pressed, not one of
                // the overlay's buttons winning the tap.
                onHighlightChanged: (value) => setState(() => _pressed = value),
                child: AnimatedScale(
                  scale: _pressed ? PressScale.pressedScale : 1,
                  duration: AnimationUtils.adjustedDuration(
                    context,
                    _pressed
                        ? AnimationManager.instantDuration
                        : AnimationManager.quickDuration,
                  ),
                  curve: _pressed
                      ? AnimationManager.enterCurve
                      : AnimationManager.springCurve,
                  child: body,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final width = widget.width;
    if (width != null) card = SizedBox(width: width, child: card);
    return card;
  }

  /// Over the cover: the Aurora Play disc rises 8 px into the bottom-right
  /// corner; star and shuffle are translucent scrim buttons in the top-right.
  Widget _buildOverlayActions(Duration fast) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.onStar != null || widget.onShuffle != null)
          Positioned(
            top: OmnisonicSpacing.sm,
            right: OmnisonicSpacing.sm,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onStar != null)
                  _OverlayButton(
                    icon: widget.isStarred
                        ? OmnisonicIcons.star
                        : OmnisonicIcons.starOutline,
                    tooltip: widget.isStarred
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                    toggled: widget.isStarred,
                    onPressed: widget.onStar!,
                  ),
                if (widget.onShuffle != null) ...[
                  const SizedBox(width: OmnisonicSpacing.xs),
                  _OverlayButton(
                    icon: OmnisonicIcons.shuffle,
                    tooltip: 'Shuffle ${widget.title}',
                    onPressed: widget.onShuffle!,
                  ),
                ],
              ],
            ),
          ),
        if (widget.onPlay != null)
          Positioned(
            right: OmnisonicSpacing.sm,
            bottom: OmnisonicSpacing.sm,
            child: AnimatedSlide(
              // 8 px of rise, as a fraction of the 48 px disc.
              offset: _overlayVisible ? Offset.zero : const Offset(0, 8 / 48),
              duration: fast,
              curve: AnimationManager.enterCurve,
              child: PlayDisc(
                onPressed: widget.onPlay,
                tooltip: 'Play ${widget.title}',
              ),
            ),
          ),
      ],
    );
  }
}

/// A small scrim control on the card's hover overlay.
class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.toggled,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    final button = OmnisonicIconButton(
      variant: OmnisonicIconButtonVariant.onScrim,
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
      dimension: 36,
    );
    if (toggled == null) return button;
    return Semantics(toggled: toggled, child: button);
  }
}

/// A 2 px stroke in the `auroraSoft` gradient, around a circular portrait.
class _AuroraRingPainter extends CustomPainter {
  const _AuroraRingPainter(this.gradient);

  final LinearGradient gradient;

  static const double width = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawOval(
      rect.deflate(width / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = gradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_AuroraRingPainter old) => old.gradient != gradient;
}
