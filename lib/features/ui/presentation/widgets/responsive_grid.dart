import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import 'media_card.dart';

/// The one geometry for every card grid — library, favorites, offline — and
/// for the skeletons that stand in for them, so content never jumps when it
/// replaces its placeholder.
///
/// There were four (80/12/0.72, 150/20/0.72, 180/16/0.78, 180/20/0.72), and a
/// fixed aspect ratio that shrank the art to ~77px on a 360dp phone while
/// leaving empty space in wide cells.
class MediaGridPreset {
  const MediaGridPreset._();

  /// Narrowest a card gets before the grid drops a column.
  static const double minItemWidth = 140;

  /// Widest a card gets before the grid adds a column — keeps an ultrawide
  /// window from rendering posters.
  static const double maxItemWidth = 200;

  static const double spacing = 16;

  /// Columns for [width] of available space.
  static int columnsFor(
    double width, {
    double minItemWidth = MediaGridPreset.minItemWidth,
    double maxItemWidth = MediaGridPreset.maxItemWidth,
    double spacing = MediaGridPreset.spacing,
  }) {
    final byMin = ((width + spacing) / (minItemWidth + spacing)).floor();
    final byMax = ((width + spacing) / (maxItemWidth + spacing)).ceil();
    return (byMin > byMax ? byMin : byMax).clamp(1, 1 << 16);
  }

  /// Width of one cell given [columns] across [width].
  static double cellWidth(double width, int columns, {double spacing = 16}) =>
      (width - spacing * (columns - 1)) / columns;
}

/// A grid that fits as many columns as the available width allows, and
/// builds its children lazily.
///
/// Column count is derived from the constraints rather than from a
/// breakpoint, so the same grid works in the full window, in the narrower
/// content column beside the sidebar, and inside a tab. Cells are kept
/// between [minItemWidth] and [maxItemWidth] wide.
///
/// Height: with [itemExtent] each cell is exactly that tall for its width
/// (use [MediaCard.extentFor] so the art stays square and the text scales);
/// otherwise [childAspectRatio] applies.
class ResponsiveGridView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double minItemWidth;
  final double maxItemWidth;
  final double spacing;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final double? childAspectRatio;
  final double Function(BuildContext context, double cellWidth)? itemExtent;

  /// Fades the first cards in, one after the other, when the grid first
  /// appears. For content; not for skeletons standing in for it.
  final bool staggered;

  const ResponsiveGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.minItemWidth = MediaGridPreset.minItemWidth,
    this.maxItemWidth = MediaGridPreset.maxItemWidth,
    this.spacing = MediaGridPreset.spacing,
    this.padding,
    this.controller,
    this.physics,
    this.childAspectRatio,
    this.itemExtent,
    this.staggered = false,
  });

  /// A grid of [MediaCard]s whose cells fit a square cover plus the given
  /// lines of text at the current text scale.
  factory ResponsiveGridView.media({
    Key? key,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    EdgeInsets? padding,
    ScrollController? controller,
    ScrollPhysics? physics,
    bool subtitle = true,
    bool meta = false,
    bool staggered = false,
  }) => ResponsiveGridView(
    key: key,
    itemCount: itemCount,
    itemBuilder: itemBuilder,
    padding: padding,
    controller: controller,
    physics: physics,
    staggered: staggered,
    itemExtent: (context, width) =>
        MediaCard.extentFor(context, width, subtitle: subtitle, meta: meta),
  );

  @override
  Widget build(BuildContext context) {
    final grid = _buildGrid(context);
    return staggered ? EntranceScope(child: grid) : grid;
  }

  Widget _buildGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth - (padding?.horizontal ?? 0);
        final crossAxisCount = MediaGridPreset.columnsFor(
          availableWidth,
          minItemWidth: minItemWidth,
          maxItemWidth: maxItemWidth,
          spacing: spacing,
        );
        final cellWidth = MediaGridPreset.cellWidth(
          availableWidth,
          crossAxisCount,
          spacing: spacing,
        );

        return GridView.builder(
          controller: controller,
          physics: physics,
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: itemExtent?.call(context, cellWidth),
            childAspectRatio:
                childAspectRatio ?? minItemWidth / (minItemWidth + 64),
          ),
          itemCount: itemCount,
          itemBuilder: staggered
              ? (context, index) =>
                    Staggered(index: index, child: itemBuilder(context, index))
              : itemBuilder,
        );
      },
    );
  }
}

/// Lets a horizontal carousel be dragged with a mouse or trackpad.
///
/// Flutter only drag-scrolls with touch and stylus by default, so on desktop
/// the Home and Search carousels could only be moved with a horizontal
/// scroll wheel — which most mice do not have.
class CarouselScrollBehavior extends MaterialScrollBehavior {
  const CarouselScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
