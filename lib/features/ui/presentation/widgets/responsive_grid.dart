import 'package:flutter/material.dart';

/// A grid that fits as many [minItemWidth]-wide columns as the available
/// width allows, and builds its children lazily.
///
/// Column count is derived from the constraints rather than from a
/// breakpoint, so the same grid works in the full window, in the narrower
/// content column beside the sidebar, and inside a tab.
class ResponsiveGridView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double minItemWidth;
  final double spacing;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final double? childAspectRatio;

  const ResponsiveGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.minItemWidth = 160.0,
    this.spacing = 16.0,
    this.padding,
    this.controller,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth - (padding?.horizontal ?? 0);
        final crossAxisCount = (availableWidth / (minItemWidth + spacing))
            .floor()
            .clamp(1, 6);

        return GridView.builder(
          controller: controller,
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio:
                childAspectRatio ?? _calculateAspectRatio(minItemWidth),
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      },
    );
  }

  double _calculateAspectRatio(double width) {
    // Adjust aspect ratio based on content type
    // This is a reasonable default for music cards
    return width / (width + 64); // Feishin-like tighter card metadata
  }
}
