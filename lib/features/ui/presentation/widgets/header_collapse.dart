import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/utils/animation_utils.dart';

/// Tells a detail page when its header has scrolled away, so the pinned top
/// bar can take over: the compact title fades in and the bar turns to L2
/// glass (docs/design-system.md §9.5).
///
/// Mix into the page's `State`, wrap its `CustomScrollView` in a
/// `NotificationListener<ScrollNotification>(onNotification: onHeaderScroll)`
/// and build the app bar with [collapsingAppBar].
mixin HeaderCollapseMixin<T extends StatefulWidget> on State<T> {
  /// How far the page scrolls before the header counts as gone: roughly the
  /// header's title line leaving the screen.
  static const double collapseThreshold = 180;

  bool _collapsed = false;

  /// Whether the header has scrolled away.
  bool get headerCollapsed => _collapsed;

  bool onHeaderScroll(ScrollNotification notification) {
    // Only the page's own vertical scrollable, not a carousel inside it.
    if (notification.metrics.axis != Axis.vertical) return false;
    final collapsed = notification.metrics.pixels > collapseThreshold;
    if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
    return false;
  }
}

/// A pinned app bar that is bare over the header and, once [collapsed],
/// shows [title] and sits on L2 glass. [actions] stay visible throughout.
SliverAppBar collapsingAppBar(
  BuildContext context, {
  required bool collapsed,
  required String title,
  required Widget leading,
  List<Widget> actions = const [],
}) {
  final fade = AnimationUtils.adjustedDuration(
    context,
    AnimationManager.fastDuration,
  );
  return SliverAppBar(
    pinned: true,
    // Left-aligned always: centred, a long title flipped it to the left.
    centerTitle: false,
    leading: leading,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    title: AnimatedOpacity(
      opacity: collapsed ? 1 : 0,
      duration: fade,
      child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    actions: actions,
    flexibleSpace: IgnorePointer(
      child: AnimatedOpacity(
        opacity: collapsed ? 1 : 0,
        duration: fade,
        child: GlassSurface(
          intensity: GlassIntensity.pill,
          borderRadius: BorderRadius.zero,
          highlight: false,
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}
