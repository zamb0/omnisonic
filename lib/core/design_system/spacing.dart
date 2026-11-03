import 'package:flutter/material.dart';

/// Spacing and layout grid system for Omnisonic UI Enhancement
class OmnisonicSpacing {
  // Base spacing unit (8px)
  static const double baseUnit = 8.0;

  // Spacing scale based on 8px grid
  static const double xs = baseUnit * 0.5; // 4px
  static const double sm = baseUnit * 1; // 8px
  static const double md = baseUnit * 2; // 16px
  static const double lg = baseUnit * 3; // 24px
  static const double xl = baseUnit * 4; // 32px
  static const double xxl = baseUnit * 5; // 40px
  static const double xxxl = baseUnit * 6; // 48px

  // Semantic spacing
  static const double tiny = xs; // 4px
  static const double small = sm; // 8px
  static const double medium = md; // 16px
  static const double large = lg; // 24px
  static const double extraLarge = xl; // 32px
  static const double huge = xxl; // 40px
  static const double massive = xxxl; // 48px

  // Component-specific spacing
  static const double cardPadding = md; // 16px
  static const double cardMargin = sm; // 8px
  static const double listItemPadding = md; // 16px
  static const double buttonPadding = md; // 16px
  static const double iconPadding = sm; // 8px
  static const double sectionSpacing = lg; // 24px
  static const double screenPadding = md; // 16px

  // Layout spacing
  static const double gridGutter = md; // 16px
  static const double columnGap = md; // 16px
  static const double rowGap = md; // 16px

  // Music player specific spacing
  static const double playerControlSpacing = lg; // 24px
  static const double nowPlayingPadding = md; // 16px
  static const double albumArtMargin = md; // 16px
  static const double trackListSpacing = sm; // 8px

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

  /// The page's horizontal gutter: 16 on phones, 24 on tablets, 32 wider.
  ///
  /// Pages used 4, 16 or 24 as each saw fit, so content edges jumped as the
  /// user moved between tabs. One gutter, adapting to the width.
  static double gutter(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return md;
    if (width < 1200) return lg;
    return xl;
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
  /// Cover art corner used across cards, the now-playing bar and detail
  /// headers. Deliberately off the 4px scale — it is the redesign's art
  /// radius, and rounding it to 12 or 16 visibly changes the artwork.
  static const double art = 14.0;

  /// Nav pill / glass button corner in the sidebar chrome.
  static const double pill = 13.0;

  // Not tokenized on purpose: the 1-2px rounding on drag handles, seek
  // handles, visualizer bars and status dots is half the element's own
  // thickness, not a scale step. A shared token there would be a number
  // that happens to coincide, and changing it would square off or fully
  // round the shape rather than restyle it.

  static const double card = md; // 12px
  static const double button = sm; // 8px
  static const double input = sm; // 8px
  static const double modal = lg; // 16px
  static const double albumArt = md; // 12px
  static const double playerCard = lg; // 16px

  // Semantic radius
  static const double small = xs; // 4px
  static const double medium = md; // 12px
  static const double large = lg; // 16px
  static const double circular = full; // 9999px
}

/// Elevation constants for consistent shadows
/// Drop shadows for cover art.
///
/// The redesign lifts artwork off the background with a wide, offset shadow
/// rather than a Material elevation; these were hand-copied at each call site.
class OmnisonicShadows {
  /// Lift for a full-size cover: grid cards, detail headers.
  static const List<BoxShadow> art = [
    BoxShadow(
      color: Color(0x80000000),
      blurRadius: 24,
      spreadRadius: -14,
      offset: Offset(0, 12),
    ),
  ];

  /// Softer lift for a small cover in a row.
  static const List<BoxShadow> artCompact = [
    BoxShadow(
      color: Color(0x80000000),
      blurRadius: 20,
      spreadRadius: -6,
      offset: Offset(0, 8),
    ),
  ];
}

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
  static const double card = sm; // 2dp
  static const double cardHover = md; // 4dp
  static const double button = xs; // 1dp
  static const double buttonPressed = none; // 0dp
  static const double modal = xl; // 12dp
  static const double drawer = xxl; // 16dp
  static const double appBar = md; // 4dp
  static const double fab = lg; // 8dp
  static const double nowPlayingBar = md; // 4dp
  static const double playerSheet = xl; // 12dp
}

/// Touch target sizes for accessibility compliance
class OmnisonicTouchTargets {
  static const double minimum = 44.0; // WCAG minimum
  static const double comfortable = 48.0; // Comfortable size
  static const double large = 56.0; // Large touch target

  // Component-specific touch targets
  static const double button = minimum; // 44px
  static const double iconButton = comfortable; // 48px
  static const double fab = large; // 56px
  static const double listItem = comfortable; // 48px minimum height
  static const double playButton = large; // 56px
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
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(
    horizontal: OmnisonicSpacing.xs,
  );
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(
    horizontal: OmnisonicSpacing.sm,
  );
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(
    horizontal: OmnisonicSpacing.md,
  );
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(
    horizontal: OmnisonicSpacing.lg,
  );
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(
    horizontal: OmnisonicSpacing.xl,
  );

  // Vertical insets
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(
    vertical: OmnisonicSpacing.xs,
  );
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(
    vertical: OmnisonicSpacing.sm,
  );
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(
    vertical: OmnisonicSpacing.md,
  );
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(
    vertical: OmnisonicSpacing.lg,
  );
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(
    vertical: OmnisonicSpacing.xl,
  );

  // Component-specific insets
  /// Minimum gap between a menu and the screen edge, so its shadow is
  /// not clipped.
  static const EdgeInsets menuScreen = EdgeInsets.all(12);

  static const EdgeInsets card = EdgeInsets.all(OmnisonicSpacing.cardPadding);
  static const EdgeInsets listItem = EdgeInsets.all(
    OmnisonicSpacing.listItemPadding,
  );
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: OmnisonicSpacing.lg,
    vertical: OmnisonicSpacing.md,
  );
  static const EdgeInsets screen = EdgeInsets.all(
    OmnisonicSpacing.screenPadding,
  );

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
