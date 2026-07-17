import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Orientation handling utilities for responsive design
class OrientationHandler {
  /// Get current orientation
  static Orientation getCurrentOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }

  /// Check if device is in portrait orientation
  static bool isPortrait(BuildContext context) {
    return getCurrentOrientation(context) == Orientation.portrait;
  }

  /// Check if device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return getCurrentOrientation(context) == Orientation.landscape;
  }

  /// Force specific orientation
  static void setOrientation(List<DeviceOrientation> orientations) {
    SystemChrome.setPreferredOrientations(orientations);
  }

  /// Allow all orientations
  static void allowAllOrientations() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// Lock to portrait only
  static void lockPortrait() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// Lock to landscape only
  static void lockLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// Get aspect ratio for current orientation
  static double getAspectRatio(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width / size.height;
  }

  /// Check if device has a wide aspect ratio (typically landscape)
  static bool isWideAspectRatio(BuildContext context) {
    return getAspectRatio(context) > 1.5;
  }
}

/// Widget that rebuilds when orientation changes
class OrientationBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Orientation orientation) builder;

  const OrientationBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait
        ? builder(context, Orientation.portrait)
        : builder(context, Orientation.landscape);
  }
}

/// Adaptive widget that changes layout based on orientation
class OrientationAdaptiveLayout extends StatelessWidget {
  final Widget portrait;
  final Widget landscape;

  const OrientationAdaptiveLayout({
    super.key,
    required this.portrait,
    required this.landscape,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return orientation == Orientation.portrait ? portrait : landscape;
      },
    );
  }
}

/// Keyboard handling utilities
class KeyboardHandler {
  /// Check if keyboard is currently visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  /// Get keyboard height
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  /// Get available screen height excluding keyboard
  static double getAvailableHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height -
        mediaQuery.viewInsets.bottom -
        mediaQuery.padding.top;
  }

  /// Hide keyboard
  static void hideKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  /// Show keyboard
  static void showKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  /// Dismiss keyboard by unfocusing
  static void dismissKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}

/// Widget that adapts to keyboard visibility
class KeyboardAdaptiveLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsets? keyboardPadding;
  final bool resizeToAvoidBottomInset;
  final bool maintainBottomViewPadding;

  const KeyboardAdaptiveLayout({
    super.key,
    required this.child,
    this.keyboardPadding,
    this.resizeToAvoidBottomInset = true,
    this.maintainBottomViewPadding = false,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    Widget content = child;

    if (isKeyboardVisible && keyboardPadding != null) {
      content = Padding(padding: keyboardPadding!, child: content);
    }

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: MediaQuery(
        data: mediaQuery.copyWith(
          viewInsets: maintainBottomViewPadding
              ? mediaQuery.viewInsets
              : mediaQuery.viewInsets.copyWith(bottom: 0),
        ),
        child: content,
      ),
    );
  }
}

/// Touch target size compliance system
class TouchTargetCompliance {
  /// Minimum touch target size according to WCAG guidelines
  static const double minimumTouchTarget = 44.0;

  /// Comfortable touch target size
  static const double comfortableTouchTarget = 48.0;

  /// Large touch target size
  static const double largeTouchTarget = 56.0;

  /// Check if a size meets minimum touch target requirements
  static bool meetsMinimumSize(Size size) {
    return size.width >= minimumTouchTarget &&
        size.height >= minimumTouchTarget;
  }

  /// Get compliant touch target size
  static Size getCompliantSize(Size originalSize) {
    return Size(
      originalSize.width < minimumTouchTarget
          ? minimumTouchTarget
          : originalSize.width,
      originalSize.height < minimumTouchTarget
          ? minimumTouchTarget
          : originalSize.height,
    );
  }

  /// Create a compliant touch target wrapper
  static Widget wrapWithCompliantTouchTarget({
    required Widget child,
    required VoidCallback? onTap,
    Size? minimumSize,
    EdgeInsets? padding,
  }) {
    final effectiveMinimumSize =
        minimumSize ?? const Size(minimumTouchTarget, minimumTouchTarget);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          minWidth: effectiveMinimumSize.width,
          minHeight: effectiveMinimumSize.height,
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Widget that ensures touch target compliance
class CompliantTouchTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Size? minimumSize;
  final EdgeInsets? padding;
  final AlignmentGeometry alignment;

  const CompliantTouchTarget({
    super.key,
    required this.child,
    this.onTap,
    this.minimumSize,
    this.padding,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMinimumSize =
        minimumSize ??
        const Size(
          TouchTargetCompliance.minimumTouchTarget,
          TouchTargetCompliance.minimumTouchTarget,
        );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          minWidth: effectiveMinimumSize.width,
          minHeight: effectiveMinimumSize.height,
        ),
        padding: padding,
        alignment: alignment,
        child: child,
      ),
    );
  }
}

/// Responsive orientation and keyboard aware scaffold
class ResponsiveScaffold extends StatelessWidget {
  final Widget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          appBar: appBar as PreferredSizeWidget?,
          body: _buildResponsiveBody(context, orientation),
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          drawer: drawer,
          endDrawer: endDrawer,
          backgroundColor: backgroundColor,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          extendBody: extendBody,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
        );
      },
    );
  }

  Widget _buildResponsiveBody(BuildContext context, Orientation orientation) {
    final isKeyboardVisible = KeyboardHandler.isKeyboardVisible(context);

    Widget content = body;

    // Add keyboard handling if needed
    if (isKeyboardVisible) {
      content = KeyboardAdaptiveLayout(
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        child: content,
      );
    }

    return content;
  }
}

/// Utility class for managing layout adaptations
class LayoutAdaptationManager {
  /// Get layout configuration based on orientation and screen size
  static LayoutAdaptationConfig getConfig(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final orientation = mediaQuery.orientation;
    final screenWidth = mediaQuery.size.width;
    final isKeyboardVisible = KeyboardHandler.isKeyboardVisible(context);

    return LayoutAdaptationConfig(
      orientation: orientation,
      screenWidth: screenWidth,
      screenHeight: mediaQuery.size.height,
      isKeyboardVisible: isKeyboardVisible,
      keyboardHeight: mediaQuery.viewInsets.bottom,
      safeAreaInsets: mediaQuery.padding,
    );
  }

  /// Get recommended column count based on orientation and screen size
  static int getRecommendedColumns(BuildContext context) {
    final config = getConfig(context);

    if (config.screenWidth < 480) {
      return config.orientation == Orientation.portrait ? 2 : 3;
    } else if (config.screenWidth < 768) {
      return config.orientation == Orientation.portrait ? 3 : 4;
    } else if (config.screenWidth < 1024) {
      return config.orientation == Orientation.portrait ? 4 : 6;
    } else {
      return config.orientation == Orientation.portrait ? 6 : 8;
    }
  }

  /// Get recommended spacing based on screen size and orientation
  static double getRecommendedSpacing(BuildContext context) {
    final config = getConfig(context);

    if (config.screenWidth < 480) {
      return 8.0;
    } else if (config.screenWidth < 768) {
      return 12.0;
    } else if (config.screenWidth < 1024) {
      return 16.0;
    } else {
      return 24.0;
    }
  }
}

/// Configuration class for layout adaptations
class LayoutAdaptationConfig {
  final Orientation orientation;
  final double screenWidth;
  final double screenHeight;
  final bool isKeyboardVisible;
  final double keyboardHeight;
  final EdgeInsets safeAreaInsets;

  const LayoutAdaptationConfig({
    required this.orientation,
    required this.screenWidth,
    required this.screenHeight,
    required this.isKeyboardVisible,
    required this.keyboardHeight,
    required this.safeAreaInsets,
  });

  /// Check if device is in portrait orientation
  bool get isPortrait => orientation == Orientation.portrait;

  /// Check if device is in landscape orientation
  bool get isLandscape => orientation == Orientation.landscape;

  /// Get available height excluding keyboard and safe areas
  double get availableHeight =>
      screenHeight -
      keyboardHeight -
      safeAreaInsets.top -
      safeAreaInsets.bottom;

  /// Get available width excluding safe areas
  double get availableWidth =>
      screenWidth - safeAreaInsets.left - safeAreaInsets.right;
}
