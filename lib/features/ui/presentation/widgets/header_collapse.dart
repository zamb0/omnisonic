import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/utils/animation_utils.dart';

/// Tells a detail page how far its header has scrolled, so the pinned top
/// bar can take over (docs/design-system.md §9.5):
///
/// - as soon as content slides under the bar ([scrolledUnderThreshold]) the
///   bar turns to L2 glass, so nothing is ever drawn through it;
/// - once the header has gone ([collapseThreshold]) the compact title and the
///   header's own actions (Play, Shuffle…) come into the bar.
///
/// Mix into the page's `State`, wrap its `CustomScrollView` in a
/// `NotificationListener<ScrollNotification>(onNotification: onHeaderScroll)`
/// and build the app bar with [collapsingAppBar].
mixin HeaderCollapseMixin<T extends StatefulWidget> on State<T> {
  /// Scroll after which content is under the bar: same as the desktop top
  /// bar.
  static const double scrolledUnderThreshold = 8;

  /// How far the page scrolls before the header counts as gone: roughly the
  /// header's title line leaving the screen.
  static const double collapseThreshold = 180;

  bool _scrolledUnder = false;
  bool _collapsed = false;

  /// Whether any content is under the bar.
  bool get headerScrolledUnder => _scrolledUnder;

  /// Whether the header has scrolled away.
  bool get headerCollapsed => _collapsed;

  bool onHeaderScroll(ScrollNotification notification) {
    // Only the page's own vertical scrollable, not a carousel inside it.
    if (notification.metrics.axis != Axis.vertical) return false;
    // A nested list reports its own depth; only the page's scrollable counts.
    if (notification.depth != 0) return false;
    final pixels = notification.metrics.pixels;
    final scrolledUnder = pixels > scrolledUnderThreshold;
    final collapsed = pixels > collapseThreshold;
    if (scrolledUnder != _scrolledUnder || collapsed != _collapsed) {
      setState(() {
        _scrolledUnder = scrolledUnder;
        _collapsed = collapsed;
      });
    }
    return false;
  }
}

/// A pinned app bar that is bare over the header, turns to L2 glass once
/// [scrolledUnder], and once [collapsed] shows [title] and
/// [collapsedActions].
///
/// [actions] are always visible: the ones the header does not repeat (a
/// page menu, reorder). [collapsedActions] are the header's own buttons, so
/// they only appear once the header is gone — never twice on screen.
SliverAppBar collapsingAppBar(
  BuildContext context, {
  required bool collapsed,
  required String title,
  required Widget leading,
  bool? scrolledUnder,
  List<Widget> actions = const [],
  List<Widget> collapsedActions = const [],
}) {
  final fade = AnimationUtils.adjustedDuration(
    context,
    AnimationManager.fastDuration,
  );
  final glass = scrolledUnder ?? collapsed;
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
    actions: [
      // Not just transparent: hidden buttons must not take taps or focus.
      for (final action in collapsedActions)
        AnimatedSwitcher(
          duration: fade,
          child: collapsed ? action : const SizedBox.shrink(),
        ),
      ...actions,
    ],
    flexibleSpace: IgnorePointer(
      child: AnimatedOpacity(
        opacity: glass ? 1 : 0,
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
