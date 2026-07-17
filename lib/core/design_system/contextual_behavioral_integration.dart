import 'package:flutter/material.dart';
import 'contextual_adaptation.dart';
import 'behavioral_optimization.dart';
import 'adaptive_performance.dart';

/// Integration widget that combines contextual adaptation and behavioral optimization
/// to provide the most intelligent UI adaptation possible
class IntelligentUIAdapter extends StatefulWidget {
  final Widget Function(BuildContext context, IntelligentUIConfig config)
  builder;

  const IntelligentUIAdapter({super.key, required this.builder});

  @override
  State<IntelligentUIAdapter> createState() => _IntelligentUIAdapterState();
}

class _IntelligentUIAdapterState extends State<IntelligentUIAdapter> {
  late IntelligentUIConfig _config;

  @override
  void initState() {
    super.initState();
    _updateConfig();

    // Listen for changes from all systems
    ContextualAdaptationManager().addContextChangeCallback(_updateConfig);
    ContextualAdaptationManager().addLightLevelChangeCallback(_updateConfig);
    BehavioralOptimizationManager().addOptimizationChangeCallback(
      _updateConfig,
    );
    AdaptivePerformanceManager().addPerformanceLevelChangeCallback(
      _updateConfig,
    );
    AdaptivePerformanceManager().addBatteryOptimizationCallback(_updateConfig);
  }

  @override
  void dispose() {
    ContextualAdaptationManager().removeContextChangeCallback(_updateConfig);
    ContextualAdaptationManager().removeLightLevelChangeCallback(_updateConfig);
    BehavioralOptimizationManager().removeOptimizationChangeCallback(
      _updateConfig,
    );
    AdaptivePerformanceManager().removePerformanceLevelChangeCallback(
      _updateConfig,
    );
    AdaptivePerformanceManager().removeBatteryOptimizationCallback(
      _updateConfig,
    );
    super.dispose();
  }

  void _updateConfig() {
    if (mounted) {
      setState(() {
        _config = _generateIntelligentConfig();
      });
    }
  }

  IntelligentUIConfig _generateIntelligentConfig() {
    final contextualConfig = ContextualAdaptationManager().getUIConfig();
    final behavioralConfig = BehavioralOptimizationManager().getLayoutConfig();
    final performanceConfig = AdaptivePerformanceManager().getAnimationConfig();

    return IntelligentUIConfig(
      contextualConfig: contextualConfig,
      behavioralConfig: behavioralConfig,
      performanceConfig: performanceConfig,

      // Combined adaptations
      adaptiveTouchTargets: _combineAdaptiveTouchTargets(
        contextualConfig,
        behavioralConfig,
      ),
      intelligentSpacing: _combineIntelligentSpacing(
        contextualConfig,
        behavioralConfig,
      ),
      optimizedLayout: _combineOptimizedLayout(
        contextualConfig,
        behavioralConfig,
      ),
      smartAnimations: _combineSmartAnimations(
        contextualConfig,
        performanceConfig,
      ),
      contextAwareColors: _combineContextAwareColors(contextualConfig),
      behavioralShortcuts: _combineBehavioralShortcuts(behavioralConfig),
    );
  }

  Map<String, double> _combineAdaptiveTouchTargets(
    ContextualUIConfig contextual,
    AdaptiveLayoutConfig behavioral,
  ) {
    final touchTargets = <String, double>{};

    // Base size from contextual adaptation
    final baseSize = contextual.touchTargetSize;

    // Adjust for frequently used elements
    for (final element in behavioral.frequentlyUsedElements) {
      final usageMultiplier =
          1.0 + (element.usage.totalUsage / 100.0) * 0.2; // Up to 20% larger
      touchTargets[element.elementId] = baseSize * usageMultiplier;
    }

    return touchTargets;
  }

  EdgeInsets _combineIntelligentSpacing(
    ContextualUIConfig contextual,
    AdaptiveLayoutConfig behavioral,
  ) {
    // Start with contextual spacing
    var spacing = contextual.spacing;

    // Adjust based on behavioral patterns
    final behavioralSpacing = behavioral.adaptiveSpacing;

    // Use the more conservative (larger) spacing for safety
    return EdgeInsets.fromLTRB(
      spacing.left.clamp(behavioralSpacing.left, spacing.left * 1.5),
      spacing.top.clamp(behavioralSpacing.top, spacing.top * 1.5),
      spacing.right.clamp(behavioralSpacing.right, spacing.right * 1.5),
      spacing.bottom.clamp(behavioralSpacing.bottom, spacing.bottom * 1.5),
    );
  }

  Map<String, Offset> _combineOptimizedLayout(
    ContextualUIConfig contextual,
    AdaptiveLayoutConfig behavioral,
  ) {
    final layout = <String, Offset>{};

    // Start with behavioral optimizations
    layout.addAll(behavioral.optimizedElementPositions);

    // Adjust for contextual factors
    for (final entry in layout.entries) {
      var position = entry.value;

      // Adjust for usage context
      switch (contextual.context) {
        case UsageContext.driving:
          // Move elements towards bottom for easier reach
          position = Offset(position.dx, position.dy * 0.8 + 0.2);
          break;
        case UsageContext.walking:
          // Move elements towards center for stability
          position = Offset(position.dx * 0.8 + 0.1, position.dy * 0.8 + 0.1);
          break;
        case UsageContext.stationary:
          // Keep behavioral optimization as-is
          break;
      }

      layout[entry.key] = position;
    }

    return layout;
  }

  Map<String, Duration> _combineSmartAnimations(
    ContextualUIConfig contextual,
    AdaptiveAnimationConfig performance,
  ) {
    final animations = <String, Duration>{};

    // Base duration from contextual adaptation
    final baseDuration = Duration(
      milliseconds: (300 * contextual.animationSpeed).round(),
    );

    // Adjust for performance constraints
    final performanceDuration = Duration(
      milliseconds:
          (baseDuration.inMilliseconds *
                  AdaptivePerformanceManager().animationDurationMultiplier)
              .round(),
    );

    // Set durations for different animation types
    animations['micro'] = Duration(
      milliseconds: (performanceDuration.inMilliseconds * 0.6).round(),
    );
    animations['transition'] = performanceDuration;
    animations['loading'] = Duration(
      milliseconds: (performanceDuration.inMilliseconds * 1.5).round(),
    );

    return animations;
  }

  Map<String, Color> _combineContextAwareColors(ContextualUIConfig contextual) {
    final colors = <String, Color>{};

    // Base colors adjusted for ambient light and contrast
    final baseColor = Colors.blue;
    final intensity = contextual.colorIntensity;
    final contrast = contextual.contrast;

    colors['primary'] = Color.lerp(
      baseColor.withOpacity(0.7),
      baseColor,
      intensity,
    )!;

    colors['secondary'] = Color.lerp(
      Colors.grey.withOpacity(0.5),
      Colors.grey,
      contrast,
    )!;

    // Adjust for light level
    switch (contextual.lightLevel) {
      case AmbientLightLevel.dark:
        colors['background'] = Colors.black;
        colors['surface'] = Colors.grey[900]!;
        break;
      case AmbientLightLevel.dim:
        colors['background'] = Colors.grey[850]!;
        colors['surface'] = Colors.grey[800]!;
        break;
      case AmbientLightLevel.normal:
        colors['background'] = Colors.white;
        colors['surface'] = Colors.grey[50]!;
        break;
      case AmbientLightLevel.bright:
        colors['background'] = Colors.white;
        colors['surface'] = Colors.grey[100]!;
        break;
    }

    return colors;
  }

  List<UIShortcut> _combineBehavioralShortcuts(
    AdaptiveLayoutConfig behavioral,
  ) {
    final shortcuts = <UIShortcut>[];

    // Convert navigation patterns to shortcuts
    for (final path in behavioral.preferredNavigationPaths.take(3)) {
      shortcuts.add(
        UIShortcut(
          id: 'nav_${path.fromRoute}_${path.toRoute}',
          label: '${path.fromRoute} → ${path.toRoute}',
          fromRoute: path.fromRoute,
          toRoute: path.toRoute,
          frequency: path.frequency,
          confidence: path.frequency / 10.0, // Normalize to 0-1
        ),
      );
    }

    // Add element grouping shortcuts
    for (final group in behavioral.intelligentGrouping.entries) {
      if (group.value.length >= 2) {
        shortcuts.add(
          UIShortcut(
            id: 'group_${group.key}',
            label: 'Quick access: ${group.value.join(", ")}',
            elementIds: group.value,
            confidence: 0.8, // High confidence for grouping
          ),
        );
      }
    }

    return shortcuts;
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _config);
  }
}

/// Combined configuration from all intelligent systems
class IntelligentUIConfig {
  final ContextualUIConfig contextualConfig;
  final AdaptiveLayoutConfig behavioralConfig;
  final AdaptiveAnimationConfig performanceConfig;

  // Combined adaptations
  final Map<String, double> adaptiveTouchTargets;
  final EdgeInsets intelligentSpacing;
  final Map<String, Offset> optimizedLayout;
  final Map<String, Duration> smartAnimations;
  final Map<String, Color> contextAwareColors;
  final List<UIShortcut> behavioralShortcuts;

  const IntelligentUIConfig({
    required this.contextualConfig,
    required this.behavioralConfig,
    required this.performanceConfig,
    required this.adaptiveTouchTargets,
    required this.intelligentSpacing,
    required this.optimizedLayout,
    required this.smartAnimations,
    required this.contextAwareColors,
    required this.behavioralShortcuts,
  });

  /// Get touch target size for a specific element
  double getTouchTargetSize(String elementId) {
    return adaptiveTouchTargets[elementId] ?? contextualConfig.touchTargetSize;
  }

  /// Get optimal position for a specific element
  Offset? getOptimalPosition(String elementId) {
    return optimizedLayout[elementId];
  }

  /// Get animation duration for a specific type
  Duration getAnimationDuration(String animationType) {
    return smartAnimations[animationType] ?? const Duration(milliseconds: 300);
  }

  /// Get context-aware color for a specific role
  Color getContextAwareColor(String colorRole) {
    return contextAwareColors[colorRole] ?? Colors.blue;
  }

  /// Check if an element should be promoted based on usage
  bool shouldPromoteElement(String elementId) {
    return behavioralConfig.frequentlyUsedElements.any(
      (element) =>
          element.elementId == elementId && element.usage.totalUsage >= 10,
    );
  }

  /// Get shortcuts relevant to current context
  List<UIShortcut> getRelevantShortcuts() {
    return behavioralShortcuts
        .where((shortcut) => shortcut.confidence > 0.5)
        .toList();
  }

  @override
  String toString() {
    return 'IntelligentUIConfig('
        'context: ${contextualConfig.context.name}, '
        'light: ${contextualConfig.lightLevel.name}, '
        'touchTargets: ${adaptiveTouchTargets.length}, '
        'shortcuts: ${behavioralShortcuts.length})';
  }
}

/// UI shortcut data class
class UIShortcut {
  final String id;
  final String label;
  final String? fromRoute;
  final String? toRoute;
  final List<String>? elementIds;
  final int? frequency;
  final double confidence;

  const UIShortcut({
    required this.id,
    required this.label,
    this.fromRoute,
    this.toRoute,
    this.elementIds,
    this.frequency,
    required this.confidence,
  });

  @override
  String toString() {
    return 'UIShortcut(id: $id, label: $label, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}

/// Example widget demonstrating intelligent UI adaptation
class IntelligentMusicPlayerCard extends StatefulWidget {
  final String albumId;
  final String albumTitle;
  final String artistName;
  final String? albumArtUrl;
  final VoidCallback? onTap;

  const IntelligentMusicPlayerCard({
    super.key,
    required this.albumId,
    required this.albumTitle,
    required this.artistName,
    this.albumArtUrl,
    this.onTap,
  });

  @override
  State<IntelligentMusicPlayerCard> createState() =>
      _IntelligentMusicPlayerCardState();
}

class _IntelligentMusicPlayerCardState extends State<IntelligentMusicPlayerCard>
    with InteractionTracker {
  @override
  Widget build(BuildContext context) {
    return IntelligentUIAdapter(
      builder: (context, config) {
        final touchTargetSize = config.getTouchTargetSize(
          'album_${widget.albumId}',
        );
        final spacing = config.intelligentSpacing;
        final animationDuration = config.getAnimationDuration('micro');
        final backgroundColor = config.getContextAwareColor('surface');
        final shouldPromote = config.shouldPromoteElement(
          'album_${widget.albumId}',
        );

        return AnimatedContainer(
          duration: animationDuration,
          margin: spacing,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(shouldPromote ? 16 : 12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(shouldPromote ? 0.15 : 0.1),
                blurRadius: shouldPromote ? 8 : 4,
                offset: Offset(0, shouldPromote ? 4 : 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Track the interaction
                trackInteraction(
                  elementId: 'album_${widget.albumId}',
                  type: InteractionType.tap,
                  context: 'album_card',
                  wasSuccessful: true,
                );

                widget.onTap?.call();
              },
              borderRadius: BorderRadius.circular(shouldPromote ? 16 : 12),
              child: Container(
                constraints: BoxConstraints(
                  minHeight: touchTargetSize,
                  minWidth: touchTargetSize,
                ),
                padding: EdgeInsets.all(shouldPromote ? 16 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Album artwork
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[300],
                        ),
                        child: widget.albumArtUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.albumArtUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.album, size: 48),
                      ),
                    ),

                    SizedBox(height: spacing.top / 2),

                    // Album title
                    Text(
                      widget.albumTitle,
                      style: TextStyle(
                        fontSize: 16 * config.contextualConfig.fontSize,
                        fontWeight: shouldPromote
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: config.getContextAwareColor('primary'),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: spacing.top / 4),

                    // Artist name
                    Text(
                      widget.artistName,
                      style: TextStyle(
                        fontSize: 14 * config.contextualConfig.fontSize,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Show promotion indicator for frequently used albums
                    if (shouldPromote) ...[
                      SizedBox(height: spacing.top / 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: config
                              .getContextAwareColor('primary')
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Frequently played',
                          style: TextStyle(
                            fontSize: 10 * config.contextualConfig.fontSize,
                            color: config.getContextAwareColor('primary'),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
