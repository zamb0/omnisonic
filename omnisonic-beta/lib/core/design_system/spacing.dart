import 'package:flutter/material.dart';

/// Spacing and layout grid system for Omnisonic UI Enhancement
class OmnisonicSpacing {
  // Base spacing unit (8px)
  static const double baseUnit = 8.0;
  
  // Spacing scale based on 8px grid
  static const double xs = baseUnit * 0.5;    // 4px
  static const double sm = baseUnit * 1;      // 8px
  static const double md = baseUnit * 2;      // 16px
  static const double lg = baseUnit * 3;      // 24px
  static const double xl = baseUnit * 4;      // 32px
  static const double xxl = baseUnit * 5;     // 40px
  static const double xxxl = baseUnit * 6;    // 48px
  
  // Semantic spacing
  static const double tiny = xs;              // 4px
  static const double small = sm;             // 8px
  static const double medium = md;            // 16px
  static const double large = lg;             // 24px
  static const double extraLarge = xl;        // 32px
  static const double huge = xxl;             // 40px
  static const double massive = xxxl;         // 48px
  
  // Component-specific spacing
  static const double cardPadding = md;       // 16px
  static const double cardMargin = sm;        // 8px
  static const double listItemPadding = md;   // 16px
  static const double buttonPadding = md;     // 16px
  static const double iconPadding = sm;       // 8px
  static const double sectionSpacing = lg;    // 24px
  static const double screenPadding = md;     // 16px
  
  // Layout spacing
  static const double gridGutter = md;        // 16px
  static const double columnGap = md;         // 16px
  static const double rowGap = md;            // 16px
  
  // Music player specific spacing
  static const double playerControlSpacing = lg;     // 24px
  static const double nowPlayingPadding = md;        // 16px
  static const double albumArtMargin = md;           // 16px
  static const double trackListSpacing = sm;        // 8px
  
  // Responsive spacing multipliers
  static const double mobileMultiplier = 0.8;
  static const double tabletMultiplier = 1.0;
  static const double desktopMultiplier = 1.2;
  
  /// Get responsive spacing based on screen size
  static double responsive(BuildContext context, double baseSpacing) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      return baseSpacing * mobileMultiplier;
    } else if (screenWidth < 1200) {
      return baseSpacing * tabletMultiplier;
    } else {
      return baseSpacing * desktopMultiplier;
    }
  }
  
  /// Get screen padding based on device size
  static EdgeInsets screenPaddingFor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      return const EdgeInsets.all(md);
    } else if (screenWidth < 1200) {
      return const EdgeInsets.all(lg);
    } else {
      return const EdgeInsets.all(xl);
    }
  }
  
  /// Get content max width based on screen size
  static double contentMaxWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      return screenWidth;
    } else if (screenWidth < 1200) {
      return 800;
    } else {
      return 1200;
    }
  }
}

/// Layout grid system for consistent spacing and alignment
class OmnisonicGrid {
  // Grid columns for different screen sizes
  static const int mobileColumns = 4;
  static const int tabletColumns = 8;
  static const int desktopColumns = 12;
  
  // Grid margins
  static const double mobileMargin = 16.0;
  static const double tabletMargin = 24.0;
  static const double desktopMargin = 32.0;
  
  // Grid gutters
  static const double mobileGutter = 16.0;
  static const double tabletGutter = 20.0;
  static const double desktopGutter = 24.0;
  
  /// Get number of columns for current screen size
  static int columnsFor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      return mobileColumns;
    } else if (screenWidth < 1200) {
      return tabletColumns;
    } else {
      return desktopColumns;
    }
  }
  
  /// Get margin for current screen size
  static double marginFor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      return mobileMargin;
    } else if (screenWidth < 1200) {
      return tabletMargin;
    } else {
      return desktopMargin;
    }
  }
  
  /// Get gutter for current screen size
  static double gutterFor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      return mobileGutter;
    } else if (screenWidth < 1200) {
      return tabletGutter;
    } else {
      return desktopGutter;
    }
  }
  
  /// Calculate column width for current screen
  static double columnWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final margin = marginFor(context);
    final gutter = gutterFor(context);
    final columns = columnsFor(context);
    
    final availableWidth = screenWidth - (2 * margin);
    final totalGutterWidth = (columns - 1) * gutter;
    
    return (availableWidth - totalGutterWidth) / columns;
  }
  
  /// Calculate width for spanning multiple columns
  static double spanWidth(BuildContext context, int span) {
    final columnWidth = OmnisonicGrid.columnWidth(context);
    final gutter = gutterFor(context);
    
    return (columnWidth * span) + (gutter * (span - 1));
  }
}

/// Border radius constants for consistent rounded corners
class OmnisonicRadius {
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 9999.0;
  
  // Component-specific radius
  static const double card = md;              // 12px
  static const double button = sm;            // 8px
  static const double input = sm;             // 8px
  static const double modal = lg;             // 16px
  static const double albumArt = md;          // 12px
  static const double playerCard = lg;        // 16px
  
  // Semantic radius
  static const double small = xs;             // 4px
  static const double medium = md;            // 12px
  static const double large = lg;             // 16px
  static const double circular = full;        // 9999px
}

/// Elevation constants for consistent shadows
class OmnisonicElevation {
  static const double none = 0.0;
  static const double xs = 1.0;
  static const double sm = 2.0;
  static const double md = 4.0;
  static const double lg = 8.0;
  static const double xl = 12.0;
  static const double xxl = 16.0;
  static const double xxxl = 24.0;
  
  // Component-specific elevation
  static const double card = sm;              // 2dp
  static const double cardHover = md;         // 4dp
  static const double button = xs;            // 1dp
  static const double buttonPressed = none;   // 0dp
  static const double modal = xl;             // 12dp
  static const double drawer = xxl;           // 16dp
  static const double appBar = md;            // 4dp
  static const double fab = lg;               // 8dp
  static const double nowPlayingBar = md;     // 4dp
  static const double playerSheet = xl;       // 12dp
}

/// Touch target sizes for accessibility compliance
class OmnisonicTouchTargets {
  static const double minimum = 44.0;         // WCAG minimum
  static const double comfortable = 48.0;     // Comfortable size
  static const double large = 56.0;           // Large touch target
  
  // Component-specific touch targets
  static const double button = minimum;       // 44px
  static const double iconButton = comfortable; // 48px
  static const double fab = large;            // 56px
  static const double listItem = comfortable; // 48px minimum height
  static const double playButton = large;     // 56px
  static const double skipButton = comfortable; // 48px
}

/// Utility class for creating consistent EdgeInsets
class OmnisonicInsets {
  // Symmetric insets
  static const EdgeInsets allXs = EdgeInsets.all(OmnisonicSpacing.xs);
  static const EdgeInsets allSm = EdgeInsets.all(OmnisonicSpacing.sm);
  static const EdgeInsets allMd = EdgeInsets.all(OmnisonicSpacing.md);
  static const EdgeInsets allLg = EdgeInsets.all(OmnisonicSpacing.lg);
  static const EdgeInsets allXl = EdgeInsets.all(OmnisonicSpacing.xl);
  
  // Horizontal insets
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: OmnisonicSpacing.xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: OmnisonicSpacing.sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: OmnisonicSpacing.md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: OmnisonicSpacing.lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: OmnisonicSpacing.xl);
  
  // Vertical insets
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: OmnisonicSpacing.xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: OmnisonicSpacing.sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: OmnisonicSpacing.md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: OmnisonicSpacing.lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: OmnisonicSpacing.xl);
  
  // Component-specific insets
  static const EdgeInsets card = EdgeInsets.all(OmnisonicSpacing.cardPadding);
  static const EdgeInsets listItem = EdgeInsets.all(OmnisonicSpacing.listItemPadding);
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: OmnisonicSpacing.lg,
    vertical: OmnisonicSpacing.md,
  );
  static const EdgeInsets screen = EdgeInsets.all(OmnisonicSpacing.screenPadding);
  
  /// Create responsive insets based on screen size
  static EdgeInsets responsive(BuildContext context, EdgeInsets baseInsets) {
    final multiplier = _getMultiplier(context);
    
    return EdgeInsets.only(
      left: baseInsets.left * multiplier,
      top: baseInsets.top * multiplier,
      right: baseInsets.right * multiplier,
      bottom: baseInsets.bottom * multiplier,
    );
  }
  
  static double _getMultiplier(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      return OmnisonicSpacing.mobileMultiplier;
    } else if (screenWidth < 1200) {
      return OmnisonicSpacing.tabletMultiplier;
    } else {
      return OmnisonicSpacing.desktopMultiplier;
    }
  }
}