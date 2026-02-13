import 'package:flutter/material.dart';

/// A responsive grid widget that adapts to screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final EdgeInsets? padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 160.0,
    this.spacing = 16.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - (padding?.horizontal ?? 0);
        final crossAxisCount = (availableWidth / (minItemWidth + spacing)).floor().clamp(1, 6);
        final itemWidth = (availableWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        return Padding(
          padding: padding ?? EdgeInsets.zero,
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: children.map((child) {
              return SizedBox(
                width: itemWidth,
                child: child,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// A responsive grid view for scrollable content
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final EdgeInsets? padding;
  final ScrollController? controller;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.minItemWidth = 160.0,
    this.spacing = 16.0,
    this.padding,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - (padding?.horizontal ?? 0);
        final crossAxisCount = (availableWidth / (minItemWidth + spacing)).floor().clamp(1, 6);

        return GridView.builder(
          controller: controller,
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: _calculateAspectRatio(minItemWidth),
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }

  double _calculateAspectRatio(double width) {
    // Adjust aspect ratio based on content type
    // This is a reasonable default for music cards
    return width / (width + 80); // Account for text below image
  }
}