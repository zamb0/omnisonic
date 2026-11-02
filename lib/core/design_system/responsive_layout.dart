import 'package:flutter/material.dart';

/// The widths at which the app changes shape.
///
/// [MainShell] switches its chrome at [tablet] and [desktop]; pages that
/// reflow internally use the same numbers so a layout change never lands
/// halfway between two thresholds.
///
/// Pages inside the shell should ask `ShellLayout` rather than measuring the
/// screen: the content column is narrower than the window by the width of
/// the sidebar, so the two disagree on exactly the widths that matter.
class ResponsiveBreakpoints {
  const ResponsiveBreakpoints._();

  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double largeDesktop = 1440;
}

/// Picks one of up to four subtrees from the width it is given.
///
/// Measures its own constraints rather than the screen, so it composes
/// inside a column that is narrower than the window.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= ResponsiveBreakpoints.largeDesktop) {
          return largeDesktop ?? desktop ?? tablet ?? mobile;
        } else if (width >= ResponsiveBreakpoints.desktop) {
          return desktop ?? tablet ?? mobile;
        } else if (width >= ResponsiveBreakpoints.mobile) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
