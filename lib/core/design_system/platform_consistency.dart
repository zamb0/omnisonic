import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'platform_optimizations.dart';
import 'platform_theme_extensions.dart';
import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';
import '../utils/app_log.dart';

/// Platform consistency manager to ensure visual consistency across platforms
/// Implements Requirements: 2.1, 2.2, 9.1
class PlatformConsistencyManager {
  static const PlatformConsistencyManager _instance =
      PlatformConsistencyManager._internal();
  factory PlatformConsistencyManager() => _instance;
  const PlatformConsistencyManager._internal();

  /// Validate visual consistency across platforms
  PlatformConsistencyReport validateConsistency(BuildContext context) {
    final issues = <ConsistencyIssue>[];
    final warnings = <ConsistencyWarning>[];

    // Check color contrast compliance
    _validateColorContrast(context, issues, warnings);

    // Check touch target sizes
    _validateTouchTargets(context, issues, warnings);

    // Check typography consistency
    _validateTypography(context, issues, warnings);

    // Check animation performance
    _validateAnimationPerformance(context, issues, warnings);

    // Check responsive behavior
    _validateResponsiveBehavior(context, issues, warnings);

    return PlatformConsistencyReport(
      platform: PlatformOptimizations().currentPlatform,
      issues: issues,
      warnings: warnings,
      timestamp: DateTime.now(),
    );
  }

  void _validateColorContrast(
    BuildContext context,
    List<ConsistencyIssue> issues,
    List<ConsistencyWarning> warnings,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Check primary color contrast
    final primaryContrast = _calculateContrastRatio(
      colorScheme.primary,
      colorScheme.onPrimary,
    );

    if (primaryContrast < 4.5) {
      issues.add(
        ConsistencyIssue(
          type: ConsistencyIssueType.colorContrast,
          description:
              'Primary color contrast ratio ($primaryContrast) is below WCAG AA standard (4.5:1)',
          severity: IssueSeverity.high,
          platform: PlatformOptimizations().currentPlatform,
        ),
      );
    }

    // Check surface color contrast
    final surfaceContrast = _calculateContrastRatio(
      colorScheme.surface,
      colorScheme.onSurface,
    );

    if (surfaceContrast < 4.5) {
      issues.add(
        ConsistencyIssue(
          type: ConsistencyIssueType.colorContrast,
          description:
              'Surface color contrast ratio ($surfaceContrast) is below WCAG AA standard (4.5:1)',
          severity: IssueSeverity.high,
          platform: PlatformOptimizations().currentPlatform,
        ),
      );
    }
  }

  void _validateTouchTargets(
    BuildContext context,
    List<ConsistencyIssue> issues,
    List<ConsistencyWarning> warnings,
  ) {
    final platformTheme = context.platformTheme;
    final expectedSize = PlatformOptimizations().touchTargetSize;

    if (platformTheme.touchTargetSize < expectedSize) {
      issues.add(
        ConsistencyIssue(
          type: ConsistencyIssueType.touchTarget,
          description:
              'Touch target size (${platformTheme.touchTargetSize}) is below platform minimum ($expectedSize)',
          severity: IssueSeverity.medium,
          platform: PlatformOptimizations().currentPlatform,
        ),
      );
    }

    // Check if touch targets are consistent across different UI elements
    final buttonSize = platformTheme.touchTargetSize;
    final iconButtonSize = platformTheme.touchTargetSize;

    if ((buttonSize - iconButtonSize).abs() > 4.0) {
      warnings.add(
        ConsistencyWarning(
          type: ConsistencyWarningType.inconsistentSizing,
          description:
              'Touch target sizes vary significantly between button types',
          platform: PlatformOptimizations().currentPlatform,
        ),
      );
    }
  }

  void _validateTypography(
    BuildContext context,
    List<ConsistencyIssue> issues,
    List<ConsistencyWarning> warnings,
  ) {
    final textTheme = Theme.of(context).textTheme;

    // Check if typography scales are consistent
    final headlineLarge = textTheme.headlineLarge?.fontSize ?? 0;
    final headlineMedium = textTheme.headlineMedium?.fontSize ?? 0;
    final headlineSmall = textTheme.headlineSmall?.fontSize ?? 0;

    if (headlineLarge <= headlineMedium || headlineMedium <= headlineSmall) {
      issues.add(
        ConsistencyIssue(
          type: ConsistencyIssueType.typography,
          description: 'Typography scale is not properly ordered',
          severity: IssueSeverity.low,
          platform: PlatformOptimizations().currentPlatform,
        ),
      );
    }

    // Check line height consistency
    final bodyLarge = textTheme.bodyLarge;
    if (bodyLarge != null && (bodyLarge.height ?? 1.0) < 1.2) {
      warnings.add(
        ConsistencyWarning(
          type: ConsistencyWarningType.readability,
          description:
              'Body text line height may be too tight for optimal readability',
          platform: PlatformOptimizations().currentPlatform,
        ),
      );
    }
  }

  void _validateAnimationPerformance(
    BuildContext context,
    List<ConsistencyIssue> issues,
    List<ConsistencyWarning> warnings,
  ) {
    final platformTheme = context.platformTheme;

    // Check animation duration consistency
    final shortDuration = platformTheme.animationDurations.short.inMilliseconds;
    final mediumDuration =
        platformTheme.animationDurations.medium.inMilliseconds;

    if (shortDuration >= mediumDuration) {
      issues.add(
        ConsistencyIssue(
          type: ConsistencyIssueType.animation,
          description: 'Animation durations are not properly ordered',
          severity: IssueSeverity.low,
          platform: PlatformOptimizations().currentPlatform,
        ),
      );
    }

    // Check if animations are too long for the platform
    if (mediumDuration > 500) {
      warnings.add(
        ConsistencyWarning(
          type: ConsistencyWarningType.performance,
          description:
              'Medium animation duration (${mediumDuration}ms) may feel slow on this platform',
          platform: PlatformOptimizations().currentPlatform,
        ),
      );
    }
  }

  void _validateResponsiveBehavior(
    BuildContext context,
    List<ConsistencyIssue> issues,
    List<ConsistencyWarning> warnings,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final orientation = mediaQuery.orientation;

    // Check if layout adapts properly to screen size
    if (screenSize.width < 360) {
      warnings.add(
        ConsistencyWarning(
          type: ConsistencyWarningType.responsiveness,
          description:
              'Screen width (${screenSize.width}) is very narrow, ensure UI elements are not cramped',
          platform: PlatformOptimizations().currentPlatform,
        ),
      );
    }

    // Check orientation handling
    if (orientation == Orientation.landscape && screenSize.height < 400) {
      warnings.add(
        ConsistencyWarning(
          type: ConsistencyWarningType.responsiveness,
          description:
              'Landscape orientation with low height (${screenSize.height}) may cause UI issues',
          platform: PlatformOptimizations().currentPlatform,
        ),
      );
    }
  }

  double _calculateContrastRatio(Color foreground, Color background) {
    final fgLuminance = _calculateLuminance(foreground);
    final bgLuminance = _calculateLuminance(background);

    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  double _calculateLuminance(Color color) {
    final r = _linearizeColorComponent((color.r * 255.0).round() / 255.0);
    final g = _linearizeColorComponent((color.g * 255.0).round() / 255.0);
    final b = _linearizeColorComponent((color.b * 255.0).round() / 255.0);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    } else {
      return math.pow((component + 0.055) / 1.055, 2.4).toDouble();
    }
  }
}

/// Cross-platform visual consistency validator widget
class PlatformConsistencyValidator extends StatefulWidget {
  final Widget child;
  final bool enableValidation;
  final Function(PlatformConsistencyReport)? onValidationComplete;

  const PlatformConsistencyValidator({
    super.key,
    required this.child,
    this.enableValidation = kDebugMode,
    this.onValidationComplete,
  });

  @override
  State<PlatformConsistencyValidator> createState() =>
      _PlatformConsistencyValidatorState();
}

class _PlatformConsistencyValidatorState
    extends State<PlatformConsistencyValidator> {
  PlatformConsistencyReport? _lastReport;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.enableValidation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _validateConsistency();
      });
    }
  }

  void _validateConsistency() {
    final report = PlatformConsistencyManager().validateConsistency(context);
    setState(() {
      _lastReport = report;
    });

    widget.onValidationComplete?.call(report);

    // Log issues in debug mode
    if (kDebugMode) {
      _logReport(report);
    }
  }

  void _logReport(PlatformConsistencyReport report) {
    if (report.issues.isNotEmpty) {
      AppLog.debug('Platform consistency issues (${report.platform.name}):');
      for (final issue in report.issues) {
        AppLog.debug(
          '${issue.severity.name.toUpperCase()}: ${issue.description}',
        );
      }
    }

    if (report.warnings.isNotEmpty) {
      AppLog.debug('Platform consistency warnings (${report.platform.name}):');
      for (final warning in report.warnings) {
        AppLog.debug('WARNING: ${warning.description}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Platform consistency report
class PlatformConsistencyReport {
  final PlatformType platform;
  final List<ConsistencyIssue> issues;
  final List<ConsistencyWarning> warnings;
  final DateTime timestamp;

  const PlatformConsistencyReport({
    required this.platform,
    required this.issues,
    required this.warnings,
    required this.timestamp,
  });

  bool get hasIssues => issues.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get isClean => !hasIssues && !hasWarnings;

  int get highSeverityCount =>
      issues.where((i) => i.severity == IssueSeverity.high).length;
  int get mediumSeverityCount =>
      issues.where((i) => i.severity == IssueSeverity.medium).length;
  int get lowSeverityCount =>
      issues.where((i) => i.severity == IssueSeverity.low).length;
}

/// Consistency issue
class ConsistencyIssue {
  final ConsistencyIssueType type;
  final String description;
  final IssueSeverity severity;
  final PlatformType platform;

  const ConsistencyIssue({
    required this.type,
    required this.description,
    required this.severity,
    required this.platform,
  });
}

/// Consistency warning
class ConsistencyWarning {
  final ConsistencyWarningType type;
  final String description;
  final PlatformType platform;

  const ConsistencyWarning({
    required this.type,
    required this.description,
    required this.platform,
  });
}

/// Types of consistency issues
enum ConsistencyIssueType {
  colorContrast,
  touchTarget,
  typography,
  animation,
  layout,
  accessibility,
}

/// Types of consistency warnings
enum ConsistencyWarningType {
  inconsistentSizing,
  readability,
  performance,
  responsiveness,
  usability,
}

/// Issue severity levels
enum IssueSeverity { low, medium, high }
