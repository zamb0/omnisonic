import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Behavioral optimization system that learns from user interaction patterns
/// and adapts the UI layout and navigation for improved efficiency
class BehavioralOptimizationManager {
  static final BehavioralOptimizationManager _instance = BehavioralOptimizationManager._internal();
  factory BehavioralOptimizationManager() => _instance;
  BehavioralOptimizationManager._internal();
  
  // Interaction tracking
  final Map<String, InteractionPattern> _interactionPatterns = {};
  final Queue<UserInteraction> _recentInteractions = Queue<UserInteraction>();
  final Map<String, NavigationPattern> _navigationPatterns = {};
  final Map<String, UIElementUsage> _elementUsageStats = {};
  
  // Learning parameters
  static const int _maxRecentInteractions = 100;
  static const int _minInteractionsForPattern = 5;
  static const Duration _interactionWindow = Duration(minutes: 30);
  static const double _learningRate = 0.1;
  
  // Optimization state
  final Map<String, OptimizationSuggestion> _currentOptimizations = {};
  Timer? _analysisTimer;
  bool _isInitialized = false;
  
  // Callbacks
  final List<VoidCallback> _optimizationChangeCallbacks = [];
  
  /// Initialize the behavioral optimization manager
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _startPeriodicAnalysis();
    _isInitialized = true;
    
    developer.log('Behavioral optimization initialized', name: 'BehavioralOptimization');
  }
  
  /// Record a user interaction for pattern analysis
  void recordInteraction(UserInteraction interaction) {
    try {
      // Add to recent interactions
      _recentInteractions.addLast(interaction);
      
      // Maintain queue size
      while (_recentInteractions.length > _maxRecentInteractions) {
        _recentInteractions.removeFirst();
      }
      
      // Update interaction patterns
      _updateInteractionPattern(interaction);
      
      // Update navigation patterns if applicable
      if (interaction.type == InteractionType.navigation) {
        _updateNavigationPattern(interaction);
      }
      
      // Update element usage statistics
      _updateElementUsage(interaction);
      
      developer.log('Recorded interaction: ${interaction.elementId} (${interaction.type.name})', name: 'BehavioralOptimization');
    } catch (e) {
      developer.log('Error recording interaction: $e', name: 'BehavioralOptimization');
    }
  }
  
  /// Get current optimization suggestions
  Map<String, OptimizationSuggestion> get currentOptimizations => Map.unmodifiable(_currentOptimizations);
  
  /// Get interaction pattern for a specific element
  InteractionPattern? getInteractionPattern(String elementId) {
    return _interactionPatterns[elementId];
  }
  
  /// Get navigation pattern for a specific route
  NavigationPattern? getNavigationPattern(String routeName) {
    return _navigationPatterns[routeName];
  }
  
  /// Get usage statistics for a specific UI element
  UIElementUsage? getElementUsage(String elementId) {
    return _elementUsageStats[elementId];
  }
  
  /// Get adaptive layout configuration based on learned patterns
  AdaptiveLayoutConfig getLayoutConfig() {
    return AdaptiveLayoutConfig(
      frequentlyUsedElements: _getFrequentlyUsedElements(),
      preferredNavigationPaths: _getPreferredNavigationPaths(),
      optimizedElementPositions: _getOptimizedElementPositions(),
      suggestedShortcuts: _getSuggestedShortcuts(),
      adaptiveSpacing: _getAdaptiveSpacing(),
      intelligentGrouping: _getIntelligentGrouping(),
    );
  }
  
  /// Add callback for optimization changes
  void addOptimizationChangeCallback(VoidCallback callback) {
    _optimizationChangeCallbacks.add(callback);
  }
  
  /// Remove callback for optimization changes
  void removeOptimizationChangeCallback(VoidCallback callback) {
    _optimizationChangeCallbacks.remove(callback);
  }
  
  /// Clear all learned patterns (for testing or reset)
  void clearPatterns() {
    _interactionPatterns.clear();
    _navigationPatterns.clear();
    _elementUsageStats.clear();
    _recentInteractions.clear();
    _currentOptimizations.clear();
    
    developer.log('All behavioral patterns cleared', name: 'BehavioralOptimization');
    _notifyOptimizationChange();
  }
  
  /// Dispose the behavioral optimization manager
  void dispose() {
    _analysisTimer?.cancel();
    _optimizationChangeCallbacks.clear();
    _isInitialized = false;
  }
  
  // Private methods
  
  void _startPeriodicAnalysis() {
    _analysisTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _analyzePatterns(),
    );
  }
  
  void _updateInteractionPattern(UserInteraction interaction) {
    final elementId = interaction.elementId;
    final pattern = _interactionPatterns[elementId] ?? InteractionPattern(elementId: elementId);
    
    // Update pattern statistics
    pattern.totalInteractions++;
    pattern.lastInteractionTime = interaction.timestamp;
    
    // Update frequency by time of day
    final hour = interaction.timestamp.hour;
    pattern.hourlyFrequency[hour] = (pattern.hourlyFrequency[hour] ?? 0) + 1;
    
    // Update interaction type frequency
    pattern.typeFrequency[interaction.type] = (pattern.typeFrequency[interaction.type] ?? 0) + 1;
    
    // Calculate average time between interactions
    if (pattern.previousInteractionTime != null) {
      final timeBetween = interaction.timestamp.difference(pattern.previousInteractionTime!);
      pattern.averageTimeBetween = pattern.averageTimeBetween == null
          ? timeBetween
          : Duration(
              milliseconds: ((pattern.averageTimeBetween!.inMilliseconds * (1 - _learningRate)) +
                  (timeBetween.inMilliseconds * _learningRate)).round(),
            );
    }
    pattern.previousInteractionTime = interaction.timestamp;
    
    // Update success rate if applicable
    if (interaction.wasSuccessful != null) {
      final successCount = pattern.successfulInteractions;
      final totalCount = pattern.totalInteractions;
      pattern.successfulInteractions = interaction.wasSuccessful! ? successCount + 1 : successCount;
      pattern.successRate = pattern.successfulInteractions / totalCount;
    }
    
    _interactionPatterns[elementId] = pattern;
  }
  
  void _updateNavigationPattern(UserInteraction interaction) {
    if (interaction.fromRoute == null || interaction.toRoute == null) return;
    
    final routeKey = '${interaction.fromRoute}->${interaction.toRoute}';
    final pattern = _navigationPatterns[routeKey] ?? NavigationPattern(
      fromRoute: interaction.fromRoute!,
      toRoute: interaction.toRoute!,
    );
    
    pattern.frequency++;
    pattern.lastUsed = interaction.timestamp;
    
    // Update time-based patterns
    final hour = interaction.timestamp.hour;
    pattern.hourlyUsage[hour] = (pattern.hourlyUsage[hour] ?? 0) + 1;
    
    // Calculate average navigation time if available
    if (interaction.duration != null) {
      pattern.averageDuration = pattern.averageDuration == null
          ? interaction.duration!
          : Duration(
              milliseconds: ((pattern.averageDuration!.inMilliseconds * (1 - _learningRate)) +
                  (interaction.duration!.inMilliseconds * _learningRate)).round(),
            );
    }
    
    _navigationPatterns[routeKey] = pattern;
  }
  
  void _updateElementUsage(UserInteraction interaction) {
    final elementId = interaction.elementId;
    final usage = _elementUsageStats[elementId] ?? UIElementUsage(elementId: elementId);
    
    usage.totalUsage++;
    usage.lastUsed = interaction.timestamp;
    
    // Update position-based usage if available
    if (interaction.position != null) {
      usage.positions.add(interaction.position!);
      
      // Keep only recent positions
      if (usage.positions.length > 20) {
        usage.positions.removeAt(0);
      }
      
      // Calculate average position
      if (usage.positions.isNotEmpty) {
        double avgX = usage.positions.map((p) => p.dx).reduce((a, b) => a + b) / usage.positions.length;
        double avgY = usage.positions.map((p) => p.dy).reduce((a, b) => a + b) / usage.positions.length;
        usage.averagePosition = Offset(avgX, avgY);
      }
    }
    
    // Update context-based usage
    if (interaction.context != null) {
      usage.contextUsage[interaction.context!] = (usage.contextUsage[interaction.context!] ?? 0) + 1;
    }
    
    _elementUsageStats[elementId] = usage;
  }
  
  void _analyzePatterns() {
    try {
      developer.log('Analyzing behavioral patterns...', name: 'BehavioralOptimization');
      
      _generateOptimizationSuggestions();
      _cleanupOldData();
      
      developer.log('Pattern analysis complete. ${_currentOptimizations.length} optimizations active.', name: 'BehavioralOptimization');
    } catch (e) {
      developer.log('Error analyzing patterns: $e', name: 'BehavioralOptimization');
    }
  }
  
  void _generateOptimizationSuggestions() {
    final newOptimizations = <String, OptimizationSuggestion>{};
    
    // Analyze frequently used elements
    final frequentElements = _getFrequentlyUsedElements();
    for (final element in frequentElements) {
      if (element.usage.totalUsage >= _minInteractionsForPattern) {
        newOptimizations['frequent_${element.elementId}'] = OptimizationSuggestion(
          id: 'frequent_${element.elementId}',
          type: OptimizationType.elementPromotion,
          elementId: element.elementId,
          description: 'Promote frequently used element: ${element.elementId}',
          confidence: _calculateConfidence(element.usage.totalUsage),
          suggestedPosition: _calculateOptimalPosition(element),
        );
      }
    }
    
    // Analyze navigation patterns
    final frequentPaths = _getPreferredNavigationPaths();
    for (final path in frequentPaths.take(3)) {
      newOptimizations['nav_${path.fromRoute}_${path.toRoute}'] = OptimizationSuggestion(
        id: 'nav_${path.fromRoute}_${path.toRoute}',
        type: OptimizationType.navigationShortcut,
        description: 'Add shortcut: ${path.fromRoute} → ${path.toRoute}',
        confidence: _calculateConfidence(path.frequency),
        navigationPath: path,
      );
    }
    
    // Analyze element grouping opportunities
    final groupingSuggestions = _analyzeGroupingOpportunities();
    for (final suggestion in groupingSuggestions) {
      newOptimizations['group_${suggestion.id}'] = suggestion;
    }
    
    // Update optimizations if they've changed
    if (!_mapsEqual(_currentOptimizations, newOptimizations)) {
      _currentOptimizations.clear();
      _currentOptimizations.addAll(newOptimizations);
      _notifyOptimizationChange();
    }
  }
  
  void _cleanupOldData() {
    final cutoffTime = DateTime.now().subtract(const Duration(days: 7));
    
    // Remove old interactions
    _recentInteractions.removeWhere((interaction) => interaction.timestamp.isBefore(cutoffTime));
    
    // Remove unused patterns
    _interactionPatterns.removeWhere((key, pattern) => 
        pattern.lastInteractionTime.isBefore(cutoffTime) && pattern.totalInteractions < _minInteractionsForPattern);
    
    _navigationPatterns.removeWhere((key, pattern) => 
        pattern.lastUsed.isBefore(cutoffTime) && pattern.frequency < _minInteractionsForPattern);
    
    _elementUsageStats.removeWhere((key, usage) => 
        usage.lastUsed.isBefore(cutoffTime) && usage.totalUsage < _minInteractionsForPattern);
  }
  
  List<ElementUsageRank> _getFrequentlyUsedElements() {
    final elements = _elementUsageStats.entries
        .map((entry) => ElementUsageRank(elementId: entry.key, usage: entry.value))
        .toList();
    
    elements.sort((a, b) => b.usage.totalUsage.compareTo(a.usage.totalUsage));
    return elements.take(10).toList();
  }
  
  List<NavigationPattern> _getPreferredNavigationPaths() {
    final patterns = _navigationPatterns.values.toList();
    patterns.sort((a, b) => b.frequency.compareTo(a.frequency));
    return patterns.take(5).toList();
  }
  
  Map<String, Offset> _getOptimizedElementPositions() {
    final positions = <String, Offset>{};
    
    for (final entry in _elementUsageStats.entries) {
      if (entry.value.averagePosition != null && entry.value.totalUsage >= _minInteractionsForPattern) {
        positions[entry.key] = entry.value.averagePosition!;
      }
    }
    
    return positions;
  }
  
  List<String> _getSuggestedShortcuts() {
    return _getPreferredNavigationPaths()
        .where((pattern) => pattern.frequency >= _minInteractionsForPattern)
        .map((pattern) => '${pattern.fromRoute}->${pattern.toRoute}')
        .toList();
  }
  
  EdgeInsets _getAdaptiveSpacing() {
    // Calculate adaptive spacing based on usage patterns
    final frequentElements = _getFrequentlyUsedElements();
    
    if (frequentElements.isEmpty) {
      return const EdgeInsets.all(16.0);
    }
    
    // Reduce spacing around frequently used elements
    final avgUsage = frequentElements.map((e) => e.usage.totalUsage).reduce((a, b) => a + b) / frequentElements.length;
    final spacingMultiplier = math.max(0.7, 1.0 - (avgUsage / 100.0) * 0.3);
    
    return EdgeInsets.all(16.0 * spacingMultiplier);
  }
  
  Map<String, List<String>> _getIntelligentGrouping() {
    final grouping = <String, List<String>>{};
    
    // Group elements that are frequently used together
    final coUsagePatterns = _analyzeCoUsagePatterns();
    
    for (final pattern in coUsagePatterns) {
      if (pattern.confidence > 0.6) {
        grouping[pattern.groupName] = pattern.elementIds;
      }
    }
    
    return grouping;
  }
  
  List<CoUsagePattern> _analyzeCoUsagePatterns() {
    final patterns = <CoUsagePattern>[];
    final elementIds = _elementUsageStats.keys.toList();
    
    // Analyze pairs of elements for co-usage
    for (int i = 0; i < elementIds.length; i++) {
      for (int j = i + 1; j < elementIds.length; j++) {
        final element1 = elementIds[i];
        final element2 = elementIds[j];
        
        final coUsageCount = _calculateCoUsage(element1, element2);
        if (coUsageCount >= _minInteractionsForPattern) {
          final confidence = coUsageCount / math.max(_elementUsageStats[element1]!.totalUsage, _elementUsageStats[element2]!.totalUsage);
          
          patterns.add(CoUsagePattern(
            groupName: '${element1}_${element2}',
            elementIds: [element1, element2],
            coUsageCount: coUsageCount,
            confidence: confidence,
          ));
        }
      }
    }
    
    patterns.sort((a, b) => b.confidence.compareTo(a.confidence));
    return patterns;
  }
  
  int _calculateCoUsage(String element1, String element2) {
    int coUsageCount = 0;
    
    // Look for interactions with both elements within a time window
    final interactions = _recentInteractions.toList();
    
    for (int i = 0; i < interactions.length - 1; i++) {
      final current = interactions[i];
      final next = interactions[i + 1];
      
      if ((current.elementId == element1 && next.elementId == element2) ||
          (current.elementId == element2 && next.elementId == element1)) {
        if (next.timestamp.difference(current.timestamp) <= _interactionWindow) {
          coUsageCount++;
        }
      }
    }
    
    return coUsageCount;
  }
  
  List<OptimizationSuggestion> _analyzeGroupingOpportunities() {
    final suggestions = <OptimizationSuggestion>[];
    final coUsagePatterns = _analyzeCoUsagePatterns();
    
    for (final pattern in coUsagePatterns.take(3)) {
      if (pattern.confidence > 0.5) {
        suggestions.add(OptimizationSuggestion(
          id: 'group_${pattern.groupName}',
          type: OptimizationType.elementGrouping,
          description: 'Group frequently co-used elements: ${pattern.elementIds.join(", ")}',
          confidence: pattern.confidence,
          elementIds: pattern.elementIds,
        ));
      }
    }
    
    return suggestions;
  }
  
  double _calculateConfidence(int usageCount) {
    return math.min(1.0, usageCount / 20.0); // Max confidence at 20 uses
  }
  
  Offset _calculateOptimalPosition(ElementUsageRank element) {
    return element.usage.averagePosition ?? const Offset(0.5, 0.5); // Center as default
  }
  
  bool _mapsEqual(Map<String, OptimizationSuggestion> map1, Map<String, OptimizationSuggestion> map2) {
    if (map1.length != map2.length) return false;
    
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key]!.confidence != map2[key]!.confidence) {
        return false;
      }
    }
    
    return true;
  }
  
  void _notifyOptimizationChange() {
    for (final callback in _optimizationChangeCallbacks) {
      try {
        callback();
      } catch (e) {
        developer.log('Error in optimization change callback: $e', name: 'BehavioralOptimization');
      }
    }
  }
}

/// User interaction data class
class UserInteraction {
  final String elementId;
  final InteractionType type;
  final DateTime timestamp;
  final Offset? position;
  final String? context;
  final String? fromRoute;
  final String? toRoute;
  final Duration? duration;
  final bool? wasSuccessful;
  
  const UserInteraction({
    required this.elementId,
    required this.type,
    required this.timestamp,
    this.position,
    this.context,
    this.fromRoute,
    this.toRoute,
    this.duration,
    this.wasSuccessful,
  });
  
  @override
  String toString() {
    return 'UserInteraction(elementId: $elementId, type: ${type.name}, timestamp: $timestamp)';
  }
}

/// Interaction type enumeration
enum InteractionType {
  tap,
  longPress,
  swipe,
  scroll,
  navigation,
  search,
  playback,
  other,
}

/// Interaction pattern data class
class InteractionPattern {
  final String elementId;
  int totalInteractions = 0;
  int successfulInteractions = 0;
  double successRate = 0.0;
  DateTime lastInteractionTime = DateTime.now();
  DateTime? previousInteractionTime;
  Duration? averageTimeBetween;
  final Map<int, int> hourlyFrequency = {}; // Hour -> count
  final Map<InteractionType, int> typeFrequency = {}; // Type -> count
  
  InteractionPattern({required this.elementId});
  
  @override
  String toString() {
    return 'InteractionPattern(elementId: $elementId, total: $totalInteractions, success: ${(successRate * 100).toStringAsFixed(1)}%)';
  }
}

/// Navigation pattern data class
class NavigationPattern {
  final String fromRoute;
  final String toRoute;
  int frequency = 0;
  DateTime lastUsed = DateTime.now();
  Duration? averageDuration;
  final Map<int, int> hourlyUsage = {}; // Hour -> count
  
  NavigationPattern({
    required this.fromRoute,
    required this.toRoute,
  });
  
  @override
  String toString() {
    return 'NavigationPattern($fromRoute -> $toRoute, frequency: $frequency)';
  }
}

/// UI element usage statistics
class UIElementUsage {
  final String elementId;
  int totalUsage = 0;
  DateTime lastUsed = DateTime.now();
  final List<Offset> positions = [];
  Offset? averagePosition;
  final Map<String, int> contextUsage = {}; // Context -> count
  
  UIElementUsage({required this.elementId});
  
  @override
  String toString() {
    return 'UIElementUsage(elementId: $elementId, usage: $totalUsage, avgPos: $averagePosition)';
  }
}

/// Element usage ranking
class ElementUsageRank {
  final String elementId;
  final UIElementUsage usage;
  
  const ElementUsageRank({
    required this.elementId,
    required this.usage,
  });
}

/// Co-usage pattern for element grouping
class CoUsagePattern {
  final String groupName;
  final List<String> elementIds;
  final int coUsageCount;
  final double confidence;
  
  const CoUsagePattern({
    required this.groupName,
    required this.elementIds,
    required this.coUsageCount,
    required this.confidence,
  });
}

/// Optimization suggestion types
enum OptimizationType {
  elementPromotion,
  elementGrouping,
  navigationShortcut,
  layoutReorganization,
  spacingOptimization,
}

/// Optimization suggestion data class
class OptimizationSuggestion {
  final String id;
  final OptimizationType type;
  final String description;
  final double confidence;
  final String? elementId;
  final List<String>? elementIds;
  final Offset? suggestedPosition;
  final NavigationPattern? navigationPath;
  
  const OptimizationSuggestion({
    required this.id,
    required this.type,
    required this.description,
    required this.confidence,
    this.elementId,
    this.elementIds,
    this.suggestedPosition,
    this.navigationPath,
  });
  
  @override
  String toString() {
    return 'OptimizationSuggestion(id: $id, type: ${type.name}, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}

/// Adaptive layout configuration based on learned patterns
class AdaptiveLayoutConfig {
  final List<ElementUsageRank> frequentlyUsedElements;
  final List<NavigationPattern> preferredNavigationPaths;
  final Map<String, Offset> optimizedElementPositions;
  final List<String> suggestedShortcuts;
  final EdgeInsets adaptiveSpacing;
  final Map<String, List<String>> intelligentGrouping;
  
  const AdaptiveLayoutConfig({
    required this.frequentlyUsedElements,
    required this.preferredNavigationPaths,
    required this.optimizedElementPositions,
    required this.suggestedShortcuts,
    required this.adaptiveSpacing,
    required this.intelligentGrouping,
  });
  
  @override
  String toString() {
    return 'AdaptiveLayoutConfig('
        'frequentElements: ${frequentlyUsedElements.length}, '
        'navPaths: ${preferredNavigationPaths.length}, '
        'shortcuts: ${suggestedShortcuts.length})';
  }
}

/// Widget that adapts its layout based on behavioral patterns
class BehavioralOptimizationBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, AdaptiveLayoutConfig config) builder;
  
  const BehavioralOptimizationBuilder({
    super.key,
    required this.builder,
  });
  
  @override
  State<BehavioralOptimizationBuilder> createState() => _BehavioralOptimizationBuilderState();
}

class _BehavioralOptimizationBuilderState extends State<BehavioralOptimizationBuilder> {
  late AdaptiveLayoutConfig _config;
  
  @override
  void initState() {
    super.initState();
    _config = BehavioralOptimizationManager().getLayoutConfig();
    
    // Listen for optimization changes
    BehavioralOptimizationManager().addOptimizationChangeCallback(_updateConfig);
  }
  
  @override
  void dispose() {
    BehavioralOptimizationManager().removeOptimizationChangeCallback(_updateConfig);
    super.dispose();
  }
  
  void _updateConfig() {
    if (mounted) {
      setState(() {
        _config = BehavioralOptimizationManager().getLayoutConfig();
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _config);
  }
}

/// Mixin for widgets that want to track user interactions
mixin InteractionTracker<T extends StatefulWidget> on State<T> {
  void trackInteraction({
    required String elementId,
    required InteractionType type,
    Offset? position,
    String? context,
    String? fromRoute,
    String? toRoute,
    Duration? duration,
    bool? wasSuccessful,
  }) {
    final interaction = UserInteraction(
      elementId: elementId,
      type: type,
      timestamp: DateTime.now(),
      position: position,
      context: context,
      fromRoute: fromRoute,
      toRoute: toRoute,
      duration: duration,
      wasSuccessful: wasSuccessful,
    );
    
    BehavioralOptimizationManager().recordInteraction(interaction);
  }
}