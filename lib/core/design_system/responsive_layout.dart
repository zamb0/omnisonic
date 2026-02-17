import 'package:flutter/material.dart';

/// Responsive breakpoints for different screen sizes
class ResponsiveBreakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double largeDesktop = 1440;
  
  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }
  
  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }
  
  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= desktop && width < largeDesktop;
  }
  
  /// Check if current screen is large desktop
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktop;
  }
  
  /// Get current screen type
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < mobile) {
      return ScreenType.mobile;
    } else if (width < desktop) {
      return ScreenType.tablet;
    } else if (width < largeDesktop) {
      return ScreenType.desktop;
    } else {
      return ScreenType.largeDesktop;
    }
  }
}

/// Screen type enumeration
enum ScreenType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Responsive layout widget that adapts to different screen sizes
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

/// Layout configuration for different screen sizes
class LayoutConfiguration {
  final double gridSpacing;
  final int columnsPortrait;
  final int columnsLandscape;
  final EdgeInsets contentPadding;
  final double cardAspectRatio;
  final bool enableHoverEffects;
  final double maxContentWidth;
  
  const LayoutConfiguration({
    required this.gridSpacing,
    required this.columnsPortrait,
    required this.columnsLandscape,
    required this.contentPadding,
    required this.cardAspectRatio,
    this.enableHoverEffects = true,
    required this.maxContentWidth,
  });
  
  /// Create layout configuration for specific screen size
  factory LayoutConfiguration.forScreenSize(double width) {
    if (width >= ResponsiveBreakpoints.largeDesktop) {
      return const LayoutConfiguration(
        gridSpacing: 32,
        columnsPortrait: 8,
        columnsLandscape: 10,
        contentPadding: EdgeInsets.all(40),
        cardAspectRatio: 1.0,
        maxContentWidth: 1400,
      );
    } else if (width >= ResponsiveBreakpoints.desktop) {
      return const LayoutConfiguration(
        gridSpacing: 24,
        columnsPortrait: 6,
        columnsLandscape: 8,
        contentPadding: EdgeInsets.all(32),
        cardAspectRatio: 1.0,
        maxContentWidth: 1200,
      );
    } else if (width >= ResponsiveBreakpoints.mobile) {
      return const LayoutConfiguration(
        gridSpacing: 16,
        columnsPortrait: 4,
        columnsLandscape: 6,
        contentPadding: EdgeInsets.all(24),
        cardAspectRatio: 1.0,
        maxContentWidth: 800,
      );
    } else {
      return const LayoutConfiguration(
        gridSpacing: 12,
        columnsPortrait: 2,
        columnsLandscape: 3,
        contentPadding: EdgeInsets.all(16),
        cardAspectRatio: 1.0,
        enableHoverEffects: false,
        maxContentWidth: double.infinity,
      );
    }
  }
  
  /// Create layout configuration for current context
  factory LayoutConfiguration.forContext(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return LayoutConfiguration.forScreenSize(width);
  }
}

/// Responsive grid widget that adapts column count based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double? spacing;
  final double? runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final int? largeDesktopColumns;
  final double? childAspectRatio;
  final EdgeInsets? padding;
  
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing,
    this.runSpacing,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.largeDesktopColumns,
    this.childAspectRatio,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    final config = LayoutConfiguration.forContext(context);
    final screenType = ResponsiveBreakpoints.getScreenType(context);
    
    int columns;
    switch (screenType) {
      case ScreenType.mobile:
        columns = mobileColumns ?? config.columnsPortrait;
        break;
      case ScreenType.tablet:
        columns = tabletColumns ?? config.columnsPortrait;
        break;
      case ScreenType.desktop:
        columns = desktopColumns ?? config.columnsPortrait;
        break;
      case ScreenType.largeDesktop:
        columns = largeDesktopColumns ?? config.columnsPortrait;
        break;
    }
    
    return Padding(
      padding: padding ?? config.contentPadding,
      child: GridView.count(
        crossAxisCount: columns,
        crossAxisSpacing: spacing ?? config.gridSpacing,
        mainAxisSpacing: runSpacing ?? config.gridSpacing,
        childAspectRatio: childAspectRatio ?? config.cardAspectRatio,
        children: children,
      ),
    );
  }
}

/// Responsive container that constrains content width based on screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final bool centerContent;
  
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.centerContent = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final config = LayoutConfiguration.forContext(context);
    final effectiveMaxWidth = maxWidth ?? config.maxContentWidth;
    final effectivePadding = padding ?? config.contentPadding;
    
    Widget content = Container(
      constraints: BoxConstraints(
        maxWidth: effectiveMaxWidth,
      ),
      padding: effectivePadding,
      child: child,
    );
    
    if (centerContent && effectiveMaxWidth != double.infinity) {
      content = Center(child: content);
    }
    
    return content;
  }
}

/// Responsive value that returns different values based on screen size
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;
  final T? largeDesktop;
  
  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });
  
  /// Get value for current screen size
  T getValue(BuildContext context) {
    final screenType = ResponsiveBreakpoints.getScreenType(context);
    
    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }
}

/// Screen size detection utilities
class ScreenSizeDetector {
  /// Get current screen dimensions
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }
  
  /// Get current screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  /// Get current screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  /// Get device pixel ratio
  static double getPixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }
  
  /// Check if screen is in landscape orientation
  static bool isLandscape(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > size.height;
  }
  
  /// Check if screen is in portrait orientation
  static bool isPortrait(BuildContext context) {
    return !isLandscape(context);
  }
  
  /// Get safe area insets
  static EdgeInsets getSafeAreaInsets(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
  
  /// Get view insets (keyboard, etc.)
  static EdgeInsets getViewInsets(BuildContext context) {
    return MediaQuery.of(context).viewInsets;
  }
  
  /// Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }
}

/// Adaptive layout that changes based on screen size and orientation
class AdaptiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenType screenType, bool isLandscape) builder;
  
  const AdaptiveLayout({
    super.key,
    required this.builder,
  });
  
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final screenType = ResponsiveBreakpoints.getScreenType(context);
        final isLandscape = orientation == Orientation.landscape;
        
        return builder(context, screenType, isLandscape);
      },
    );
  }
}