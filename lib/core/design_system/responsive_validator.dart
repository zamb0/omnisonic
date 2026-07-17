import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'platform_optimizations.dart';
import 'responsive_layout.dart';
import '../utils/app_log.dart';

/// Responsive behavior validator to ensure consistent behavior across screen sizes
/// Implements Requirements: 2.1, 2.2
class ResponsiveBehaviorValidator {
  static const ResponsiveBehaviorValidator _instance =
      ResponsiveBehaviorValidator._internal();
  factory ResponsiveBehaviorValidator() => _instance;
  const ResponsiveBehaviorValidator._internal();

  /// Validate responsive behavior for current screen configuration
  ResponsiveValidationReport validateResponsiveBehavior(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final orientation = mediaQuery.orientation;
    final devicePixelRatio = mediaQuery.devicePixelRatio;
    final textScaleFactor = mediaQuery.textScaler.scale(1.0);

    final issues = <ResponsiveIssue>[];
    final recommendations = <ResponsiveRecommendation>[];

    // Validate screen size handling
    _validateScreenSize(screenSize, issues, recommendations);

    // Validate orientation handling
    _validateOrientation(screenSize, orientation, issues, recommendations);

    // Validate text scaling
    _validateTextScaling(textScaleFactor, issues, recommendations);

    // Validate touch targets
    _validateTouchTargets(context, issues, recommendations);

    // Validate layout density
    _validateLayoutDensity(
      screenSize,
      devicePixelRatio,
      issues,
      recommendations,
    );

    return ResponsiveValidationReport(
      screenSize: screenSize,
      orientation: orientation,
      devicePixelRatio: devicePixelRatio,
      textScaleFactor: textScaleFactor,
      platform: PlatformOptimizations().currentPlatform,
      issues: issues,
      recommendations: recommendations,
      timestamp: DateTime.now(),
    );
  }

  void _validateScreenSize(
    Size screenSize,
    List<ResponsiveIssue> issues,
    List<ResponsiveRecommendation> recommendations,
  ) {
    // Check for very small screens
    if (screenSize.width < 320) {
      issues.add(
        ResponsiveIssue(
          type: ResponsiveIssueType.screenSize,
          description:
              'Screen width (${screenSize.width.toInt()}px) is below minimum recommended width (320px)',
          severity: ResponsiveIssueSeverity.high,
        ),
      );
    }

    if (screenSize.height < 480) {
      issues.add(
        ResponsiveIssue(
          type: ResponsiveIssueType.screenSize,
          description:
              'Screen height (${screenSize.height.toInt()}px) is below minimum recommended height (480px)',
          severity: ResponsiveIssueSeverity.medium,
        ),
      );
    }

    // Check for very large screens
    if (screenSize.width > 1920) {
      recommendations.add(
        ResponsiveRecommendation(
          type: ResponsiveRecommendationType.layout,
          description:
              'Consider implementing max-width constraints for very large screens (${screenSize.width.toInt()}px)',
        ),
      );
    }

    // Check aspect ratio
    final aspectRatio = screenSize.width / screenSize.height;
    if (aspectRatio > 2.5) {
      recommendations.add(
        ResponsiveRecommendation(
          type: ResponsiveRecommendationType.layout,
          description:
              'Very wide aspect ratio (${aspectRatio.toStringAsFixed(2)}:1) may require special layout considerations',
        ),
      );
    }
  }

  void _validateOrientation(
    Size screenSize,
    Orientation orientation,
    List<ResponsiveIssue> issues,
    List<ResponsiveRecommendation> recommendations,
  ) {
    if (orientation == Orientation.landscape) {
      // Check if landscape layout has sufficient height
      if (screenSize.height < 400) {
        issues.add(
          ResponsiveIssue(
            type: ResponsiveIssueType.orientation,
            description:
                'Landscape orientation height (${screenSize.height.toInt()}px) may cause UI cramping',
            severity: ResponsiveIssueSeverity.medium,
          ),
        );
      }

      // Recommend landscape-specific optimizations
      recommendations.add(
        ResponsiveRecommendation(
          type: ResponsiveRecommendationType.orientation,
          description:
              'Consider horizontal layout optimizations for landscape mode',
        ),
      );
    } else {
      // Portrait mode validations
      if (screenSize.width < 360) {
        recommendations.add(
          ResponsiveRecommendation(
            type: ResponsiveRecommendationType.layout,
            description:
                'Narrow portrait width (${screenSize.width.toInt()}px) may benefit from single-column layouts',
          ),
        );
      }
    }
  }

  void _validateTextScaling(
    double textScaleFactor,
    List<ResponsiveIssue> issues,
    List<ResponsiveRecommendation> recommendations,
  ) {
    if (textScaleFactor > 1.5) {
      recommendations.add(
        ResponsiveRecommendation(
          type: ResponsiveRecommendationType.accessibility,
          description:
              'Large text scale factor (${textScaleFactor.toStringAsFixed(2)}) requires careful layout testing',
        ),
      );
    }

    if (textScaleFactor > 2.0) {
      issues.add(
        ResponsiveIssue(
          type: ResponsiveIssueType.textScaling,
          description:
              'Very large text scale factor (${textScaleFactor.toStringAsFixed(2)}) may cause layout overflow',
          severity: ResponsiveIssueSeverity.medium,
        ),
      );
    }
  }

  void _validateTouchTargets(
    BuildContext context,
    List<ResponsiveIssue> issues,
    List<ResponsiveRecommendation> recommendations,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final minTouchTarget = PlatformOptimizations().touchTargetSize;

    // Check if touch targets will be appropriate for the screen density
    final effectiveTouchTarget = minTouchTarget * mediaQuery.devicePixelRatio;

    if (effectiveTouchTarget < 44) {
      issues.add(
        ResponsiveIssue(
          type: ResponsiveIssueType.touchTarget,
          description:
              'Effective touch target size (${effectiveTouchTarget.toInt()}px) may be too small',
          severity: ResponsiveIssueSeverity.high,
        ),
      );
    }

    // Recommend touch target adjustments for different screen sizes
    if (mediaQuery.size.shortestSide > 600) {
      recommendations.add(
        ResponsiveRecommendation(
          type: ResponsiveRecommendationType.touchTarget,
          description: 'Consider larger touch targets for tablet-sized screens',
        ),
      );
    }
  }

  void _validateLayoutDensity(
    Size screenSize,
    double devicePixelRatio,
    List<ResponsiveIssue> issues,
    List<ResponsiveRecommendation> recommendations,
  ) {
    final logicalPixels = screenSize.width * screenSize.height;
    final physicalPixels =
        logicalPixels * (devicePixelRatio * devicePixelRatio);

    // Check for high-density screens
    if (devicePixelRatio > 3.0) {
      recommendations.add(
        ResponsiveRecommendation(
          type: ResponsiveRecommendationType.performance,
          description:
              'High pixel density (${devicePixelRatio.toStringAsFixed(1)}x) may benefit from optimized assets',
        ),
      );
    }

    // Check for low-density screens
    if (devicePixelRatio < 1.5) {
      recommendations.add(
        ResponsiveRecommendation(
          type: ResponsiveRecommendationType.visual,
          description:
              'Low pixel density (${devicePixelRatio.toStringAsFixed(1)}x) may require adjusted visual elements',
        ),
      );
    }

    // Check for very high resolution
    if (physicalPixels > 8000000) {
      // ~8MP
      recommendations.add(
        ResponsiveRecommendation(
          type: ResponsiveRecommendationType.performance,
          description:
              'Very high resolution screen may benefit from performance optimizations',
        ),
      );
    }
  }
}

/// Widget that validates responsive behavior and reports issues
class ResponsiveBehaviorValidatorWidget extends StatefulWidget {
  final Widget child;
  final bool enableValidation;
  final Function(ResponsiveValidationReport)? onValidationComplete;

  const ResponsiveBehaviorValidatorWidget({
    super.key,
    required this.child,
    this.enableValidation = kDebugMode,
    this.onValidationComplete,
  });

  @override
  State<ResponsiveBehaviorValidatorWidget> createState() =>
      _ResponsiveBehaviorValidatorWidgetState();
}

class _ResponsiveBehaviorValidatorWidgetState
    extends State<ResponsiveBehaviorValidatorWidget> {
  ResponsiveValidationReport? _lastReport;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.enableValidation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _validateResponsiveBehavior();
      });
    }
  }

  void _validateResponsiveBehavior() {
    final report = ResponsiveBehaviorValidator().validateResponsiveBehavior(
      context,
    );
    setState(() {
      _lastReport = report;
    });

    widget.onValidationComplete?.call(report);

    // Log issues in debug mode
    if (kDebugMode) {
      _logReport(report);
    }
  }

  void _logReport(ResponsiveValidationReport report) {
    if (report.issues.isNotEmpty) {
      AppLog.debug('Responsive behavior issues (${report.platform.name}):');
      for (final issue in report.issues) {
        AppLog.debug(
          '${issue.severity.name.toUpperCase()}: ${issue.description}',
        );
      }
    }

    if (report.recommendations.isNotEmpty) {
      AppLog.debug(
        'Responsive behavior recommendations (${report.platform.name}):',
      );
      for (final recommendation in report.recommendations) {
        AppLog.debug('RECOMMENDATION: ${recommendation.description}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Responsive validation report
class ResponsiveValidationReport {
  final Size screenSize;
  final Orientation orientation;
  final double devicePixelRatio;
  final double textScaleFactor;
  final PlatformType platform;
  final List<ResponsiveIssue> issues;
  final List<ResponsiveRecommendation> recommendations;
  final DateTime timestamp;

  const ResponsiveValidationReport({
    required this.screenSize,
    required this.orientation,
    required this.devicePixelRatio,
    required this.textScaleFactor,
    required this.platform,
    required this.issues,
    required this.recommendations,
    required this.timestamp,
  });

  bool get hasIssues => issues.isNotEmpty;
  bool get hasRecommendations => recommendations.isNotEmpty;
  bool get isOptimal => !hasIssues && !hasRecommendations;

  ResponsiveScreenCategory get screenCategory {
    final shortestSide = screenSize.shortestSide;
    if (shortestSide < 600) {
      return ResponsiveScreenCategory.phone;
    } else if (shortestSide < 840) {
      return ResponsiveScreenCategory.tablet;
    } else {
      return ResponsiveScreenCategory.desktop;
    }
  }

  String get screenSizeDescription {
    return '${screenSize.width.toInt()}x${screenSize.height.toInt()} (${devicePixelRatio.toStringAsFixed(1)}x)';
  }
}

/// Responsive issue
class ResponsiveIssue {
  final ResponsiveIssueType type;
  final String description;
  final ResponsiveIssueSeverity severity;

  const ResponsiveIssue({
    required this.type,
    required this.description,
    required this.severity,
  });
}

/// Responsive recommendation
class ResponsiveRecommendation {
  final ResponsiveRecommendationType type;
  final String description;

  const ResponsiveRecommendation({
    required this.type,
    required this.description,
  });
}

/// Types of responsive issues
enum ResponsiveIssueType {
  screenSize,
  orientation,
  textScaling,
  touchTarget,
  layout,
  performance,
}

/// Types of responsive recommendations
enum ResponsiveRecommendationType {
  layout,
  orientation,
  accessibility,
  touchTarget,
  performance,
  visual,
}

/// Responsive issue severity
enum ResponsiveIssueSeverity { low, medium, high }

/// Screen categories for responsive design
enum ResponsiveScreenCategory { phone, tablet, desktop }
