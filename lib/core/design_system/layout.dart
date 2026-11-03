import 'package:flutter/widgets.dart';

import 'responsive_layout.dart';
import 'spacing.dart';

/// Page geometry: where content starts, how far apart sections sit, and how
/// wide text is allowed to run. See `docs/design-system.md` §10.
class OmnisonicLayout {
  const OmnisonicLayout._();

  /// Floating chrome — sidebar, player bar, bottom nav — sits this far from
  /// the window edge and from the next pane of chrome.
  static const double chromeInset = OmnisonicSpacing.ms;

  /// Content gutter beside a sidebar, measured from the sidebar's edge.
  static const double sidebarGutter = OmnisonicSpacing.lg;

  /// Widest a column of reading content gets: settings, forms, details.
  static const double readableMaxWidth = 720;

  /// Space between two sections of a page.
  static double sectionGap(BuildContext context) =>
      MediaQuery.sizeOf(context).width < ResponsiveBreakpoints.tablet
      ? OmnisonicSpacing.xl
      : OmnisonicSpacing.xxl;

  /// Between a section's header and its content.
  static const double headerGap = OmnisonicSpacing.ms;

  /// Above the page title.
  static double pageTop(BuildContext context) =>
      MediaQuery.sizeOf(context).width < ResponsiveBreakpoints.tablet
      ? OmnisonicSpacing.sm
      : OmnisonicSpacing.md;

  /// Below the last thing on a page, so it clears the floating player.
  static const double pageBottom = OmnisonicSpacing.xxl;
}

/// The horizontal gutter of the page content below it.
///
/// The shell publishes it, because the shell knows what is beside the
/// content: next to a sidebar the gutter is measured from the glass edge, on
/// a phone from the screen edge. Title, section headers, grids, carousels
/// and the top bar all read it, so they share one left edge — they used to
/// pick 4, 16, 24 or 32 each.
class PageGutter extends InheritedWidget {
  const PageGutter({super.key, required this.value, required super.child});

  final double value;

  /// The gutter for [context]: the shell's, or one derived from the width
  /// outside a shell (dialogs, tests, routes pushed above the shell).
  static double of(BuildContext context) {
    final gutter = context.dependOnInheritedWidgetOfExactType<PageGutter>();
    return gutter?.value ?? forWidth(MediaQuery.sizeOf(context).width);
  }

  /// The phone/tablet gutter for a full-width page [width] wide.
  static double forWidth(double width) {
    if (width < ResponsiveBreakpoints.mobile) return OmnisonicSpacing.md;
    if (width < ResponsiveBreakpoints.tablet) return OmnisonicSpacing.ml;
    return OmnisonicSpacing.lg;
  }

  /// Symmetric horizontal insets at the gutter.
  static EdgeInsets horizontal(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: of(context));

  @override
  bool updateShouldNotify(PageGutter oldWidget) => oldWidget.value != value;
}

/// Centres [child] and caps it at [OmnisonicLayout.readableMaxWidth], for
/// pages of text and controls that look stretched edge to edge on desktop.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({
    super.key,
    required this.child,
    this.maxWidth = OmnisonicLayout.readableMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
