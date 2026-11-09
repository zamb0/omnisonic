import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import 'top_wash.dart';

/// The header of an album, artist or playlist page: artwork, an eyebrow, the
/// title, a subtitle, metadata chips and the primary actions.
///
/// - Narrow (under 720px): artwork above the text, title at
///   [OmnisonicTypography.sectionTitle]. Wide: artwork beside the text,
///   title at [OmnisonicTypography.pageTitle]. The album page had these
///   inverted (52px on phones, 28px on desktop), so long titles took five
///   lines on the smallest screens.
/// - Actions sit in a [Wrap]: Play, Shuffle and Download in a Row needed
///   ~360px and overflowed a 360dp phone.
/// - Narrow and not [forceNarrow] (a phone): a 120px cover beside the title,
///   the actions on one full-width row below. Stacked, the 160px cover and
///   the wrapped actions pushed the first track below the fold. Icon-only
///   actions ([IconButton], [OmnisonicIconButton]) keep their size; the
///   others share the row.
/// - Short windows (landscape phones) get a smaller cover when wide.
///
/// v2 (docs/design-system.md §9.5): the cover's [tint], +15 % saturation,
/// washes down from the top of the header and fades into the canvas; the
/// cover is an `artHero` with the `artGlow` shadow (a round portrait for
/// [circularArtwork]); the eyebrow is `primary`; the title is the hero
/// style, at most two lines, with the whole name in a tooltip when it was
/// cut.
///
/// The header always takes the full width it is given, so the wash spans
/// the page: inside a `crossAxisAlignment.start` column it used to shrink
/// to its text, and the tint stopped in a hard vertical edge just past the
/// title.
class DetailHeader extends StatefulWidget {
  const DetailHeader({
    super.key,
    required this.title,
    required this.artwork,
    this.eyebrow,
    this.subtitle,
    this.chips = const [],
    this.actions = const [],
    this.below,
    this.artworkSize,
    this.forceNarrow = false,
    this.tint,
    this.circularArtwork = false,
    this.bleedTop = 0,
    this.bleedEnd = 0,
  });

  final String title;

  /// The artwork; it is laid out at [artworkSize] (or the default for the
  /// width) and should fill that box.
  final Widget artwork;
  final String? eyebrow;

  /// Usually the artist. A widget, so it can be a link.
  final Widget? subtitle;
  final List<Widget> chips;

  /// Primary actions — Play first, as a filled button.
  final List<Widget> actions;

  /// Extra content under the actions, e.g. a source picker.
  final Widget? below;

  /// Overrides the artwork edge (160 narrow, 240 wide).
  final double? artworkSize;

  /// Stacks artwork and text even when wide — for a header that sits in a
  /// column of its own.
  final bool forceNarrow;

  /// The cover's dominant colour: it tints the header's backdrop and lights
  /// the cover's shadow. Null falls back to the accent.
  final Color? tint;

  /// The artwork is a circle (an artist), so its glow is round too.
  final bool circularArtwork;

  /// How far the tint wash reaches up past the header's top edge, at full
  /// strength. A detail page passes [pageBleed]: starting at the header, the
  /// wash met the bare canvas behind the transparent top bar in a hard
  /// horizontal line. Where the top bar is outside the scroll view (the
  /// desktop shell), the shell's [TopWashStrip] carries on from the
  /// scroll view's edge.
  final double bleedTop;

  /// How far past the page gutter the wash reaches on the trailing side.
  /// A header in the first of two columns (the desktop album page) passes
  /// the width of the column beside it, so the tint does not stop at the
  /// column boundary.
  final double bleedEnd;

  /// Enough to cover any top bar plus status bar; the scroll view clips the
  /// rest.
  static const double pageBleed = 240;

  /// Below this width the header stacks.
  static const double narrowBreakpoint = 720;

  /// How far the tint wash fades: it is gone by the header's bottom edge.
  static const double washAlphaDark = 0.45;
  static const double washAlphaLight = 0.35;

  /// [tint] pushed to +15 % saturation and kept in a lightness band that
  /// sits on the canvas: deep on the dark one, pale on the light one.
  static Color washColor(Color tint, {required bool isDark}) {
    final hsl = HSLColor.fromColor(tint);
    return hsl
        .withSaturation((hsl.saturation + 0.15).clamp(0.0, 1.0))
        .withLightness(
          isDark
              ? hsl.lightness.clamp(0.0, 0.45)
              : hsl.lightness.clamp(0.7, 1.0),
        )
        .toColor();
  }

  @override
  State<DetailHeader> createState() => _DetailHeaderState();
}

class _DetailHeaderState extends State<DetailHeader> implements TopWashSource {
  /// The wash's box, measured against the scroll view for [geometry].
  final GlobalKey _washKey = GlobalKey();

  TopWash? _topWash;
  ScrollableState? _scrollable;

  /// The wash at full strength, as last built.
  Color? _full;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attach();
  }

  @override
  void didUpdateWidget(DetailHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bleedTop != widget.bleedTop) _attach();
  }

  @override
  void dispose() {
    _topWash?.detach(this);
    _topWash = null;
    _scrollable?.position.removeListener(_onScroll);
    super.dispose();
  }

  /// Only a header whose wash bleeds upwards has anything to carry onto the
  /// chrome above the page.
  void _attach() {
    final wash = widget.bleedTop > 0 ? TopWash.maybeOf(context) : null;
    if (wash != _topWash) {
      _topWash?.detach(this);
      _topWash = wash?..attach(this);
    }
    final scrollable = wash == null ? null : Scrollable.maybeOf(context);
    if (scrollable != _scrollable) {
      _scrollable?.position.removeListener(_onScroll);
      _scrollable = scrollable?..position.addListener(_onScroll);
    }
  }

  void _onScroll() => _topWash?.sourceChanged();

  @override
  TopWashGeometry? geometry() {
    final full = _full;
    final box = _washKey.currentContext?.findRenderObject();
    final viewport = _scrollable?.context.findRenderObject();
    if (full == null ||
        box is! RenderBox ||
        viewport is! RenderBox ||
        !box.attached ||
        !viewport.attached ||
        !box.hasSize) {
      return null;
    }
    final height = box.size.height;
    if (height <= 0) return null;
    return TopWashGeometry(
      viewportTop: viewport.localToGlobal(Offset.zero).dy,
      washTop: box.localToGlobal(Offset.zero).dy,
      washHeight: height,
      full: full,
      // Matches the gradient built below.
      fadeStart: (widget.bleedTop / height).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wash = DetailHeader.washColor(
      widget.tint ?? Theme.of(context).colorScheme.primary,
      isDark: isDark,
    );
    final gutter = PageGutter.of(context);
    final full = wash.withValues(
      alpha: isDark ? DetailHeader.washAlphaDark : DetailHeader.washAlphaLight,
    );
    if (_topWash != null) {
      _full = full;
      // The header's size or tint may have changed without a scroll.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _topWash?.sourceChanged(),
      );
    }
    // Full width even where the parent would let it shrink to its text.
    return SizedBox(
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Full-bleed: reaches past the page gutter on both sides.
          Positioned(
            left: -gutter,
            right: -gutter - widget.bleedEnd,
            top: -widget.bleedTop,
            bottom: 0,
            child: IgnorePointer(
              key: _washKey,
              child: ExcludeSemantics(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Full strength over the bleed, then the fade across the
                    // header itself, exactly as without a bleed.
                    final height = constraints.maxHeight;
                    final start = height.isFinite && height > 0
                        ? (widget.bleedTop / height).clamp(0.0, 1.0)
                        : 0.0;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [full, full, wash.withValues(alpha: 0)],
                          stops: [0, start, 1],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          _buildLayout(context),
        ],
      ),
    );
  }

  /// The cover, lifted by its own colour.
  Widget _cover(BuildContext context, double size) {
    final glow = widget.tint ?? Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: widget.circularArtwork ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.circularArtwork
            ? null
            : BorderRadius.circular(OmnisonicRadius.artHero),
        boxShadow: OmnisonicShadows.artGlow(glow),
      ),
      child: SizedBox.square(dimension: size, child: widget.artwork),
    );
  }

  Widget _buildLayout(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow =
            widget.forceNarrow ||
            constraints.maxWidth < DetailHeader.narrowBreakpoint;
        final short = MediaQuery.sizeOf(context).height < 500;
        if (narrow && !widget.forceNarrow) {
          return _buildCompact(context, widget.artworkSize ?? 120);
        }
        final size =
            widget.artworkSize ?? (narrow ? 160.0 : (short ? 140.0 : 240.0));
        final art = _cover(context, size);
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              art,
              const SizedBox(height: OmnisonicSpacing.md),
              _buildText(context, narrow: true),
            ],
          );
        }
        // [below] goes under the cover and the text, not in the text column:
        // there it made the column taller than the cover, and the
        // bottom-aligned cover sank beside it, leaving a hole above it.
        final below = widget.below;
        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            art,
            const SizedBox(width: OmnisonicSpacing.lg),
            Expanded(
              child: _buildText(context, narrow: false, withBelow: false),
            ),
          ],
        );
        if (below == null) return row;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            row,
            const SizedBox(height: OmnisonicSpacing.lg),
            below,
          ],
        );
      },
    );
  }

  Widget _buildCompact(BuildContext context, double size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _cover(context, size),
            const SizedBox(width: OmnisonicSpacing.md),
            Expanded(
              child: _buildText(context, narrow: true, withActions: false),
            ),
          ],
        ),
        if (widget.actions.isNotEmpty) ...[
          const SizedBox(height: OmnisonicSpacing.md),
          Row(
            children: [
              for (var i = 0; i < widget.actions.length; i++) ...[
                if (i > 0) const SizedBox(width: OmnisonicSpacing.sm),
                if (widget.actions[i] is IconButton ||
                    widget.actions[i] is OmnisonicIconButton)
                  widget.actions[i]
                else
                  Expanded(child: widget.actions[i]),
              ],
            ],
          ),
        ],
        if (widget.below != null) ...[
          const SizedBox(height: OmnisonicSpacing.md),
          widget.below!,
        ],
      ],
    );
  }

  Widget _buildText(
    BuildContext context, {
    required bool narrow,
    bool withActions = true,
    bool withBelow = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    // Hero 56 wide, 40 stacked on a phone; beside a 120 px cover there is
    // room for 28 only.
    final titleStyle =
        (!narrow
                ? OmnisonicTypography.heroTitle
                : withActions
                ? OmnisonicTypography.heroTitleCompact
                : OmnisonicTypography.sectionTitle)
            .copyWith(color: scheme.onSurface);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.eyebrow != null) ...[
          Text(
            widget.eyebrow!.toUpperCase(),
            style: OmnisonicTypography.eyebrow.copyWith(color: scheme.primary),
          ),
          const SizedBox(height: OmnisonicSpacing.ms),
        ],
        _HeroTitle(title: widget.title, style: titleStyle),
        if (widget.subtitle != null) ...[
          const SizedBox(height: OmnisonicSpacing.sm),
          DefaultTextStyle.merge(
            style: OmnisonicTypography.bodyMedium.copyWith(
              color: scheme.onSurface,
              fontWeight: OmnisonicTypography.semiBold,
            ),
            child: widget.subtitle!,
          ),
        ],
        if (widget.chips.isNotEmpty) ...[
          const SizedBox(height: OmnisonicSpacing.md),
          Wrap(
            spacing: OmnisonicSpacing.sm,
            runSpacing: OmnisonicSpacing.sm,
            children: widget.chips,
          ),
        ],
        if (withActions && widget.actions.isNotEmpty) ...[
          const SizedBox(height: OmnisonicSpacing.ml),
          Wrap(
            spacing: OmnisonicSpacing.sm,
            runSpacing: OmnisonicSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: widget.actions,
          ),
        ],
        if (withActions && withBelow && widget.below != null) ...[
          const SizedBox(height: OmnisonicSpacing.md),
          widget.below!,
        ],
      ],
    );
  }
}

/// The title: two lines at most, and when it was cut the whole name is in a
/// tooltip (and in the semantics label, which is never truncated).
class _HeroTitle extends StatelessWidget {
  const _HeroTitle({required this.title, required this.style});

  final String title;
  final TextStyle style;

  static const int maxLines = 2;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: title, style: style),
          maxLines: maxLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final cut = painter.didExceedMaxLines;
        painter.dispose();

        final text = Semantics(
          header: true,
          label: title,
          excludeSemantics: true,
          child: Text(
            title,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        );
        return cut ? Tooltip(message: title, child: text) : text;
      },
    );
  }
}
