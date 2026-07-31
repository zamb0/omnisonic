import 'package:flutter/material.dart';
import 'accessibility.dart';
import 'colors.dart';

/// Accessibility testing utilities for validating WCAG compliance
class AccessibilityTesting {
  /// Test all color combinations in a theme for WCAG compliance
  static AccessibilityTestResults testThemeCompliance(ThemeData theme) {
    final results = AccessibilityTestResults();
    final colorScheme = theme.colorScheme;

    // Test primary color combinations
    results.addTest(
      'Primary on Surface',
      OmnisonicAccessibility.meetsWCAGAA(
        colorScheme.primary,
        colorScheme.surface,
      ),
      OmnisonicAccessibility.calculateContrastRatio(
        colorScheme.primary,
        colorScheme.surface,
      ),
    );

    results.addTest(
      'On Primary on Primary',
      OmnisonicAccessibility.meetsWCAGAA(
        colorScheme.onPrimary,
        colorScheme.primary,
      ),
      OmnisonicAccessibility.calculateContrastRatio(
        colorScheme.onPrimary,
        colorScheme.primary,
      ),
    );

    // Test secondary color combinations
    results.addTest(
      'Secondary on Surface',
      OmnisonicAccessibility.meetsWCAGAA(
        colorScheme.secondary,
        colorScheme.surface,
      ),
      OmnisonicAccessibility.calculateContrastRatio(
        colorScheme.secondary,
        colorScheme.surface,
      ),
    );

    results.addTest(
      'On Secondary on Secondary',
      OmnisonicAccessibility.meetsWCAGAA(
        colorScheme.onSecondary,
        colorScheme.secondary,
      ),
      OmnisonicAccessibility.calculateContrastRatio(
        colorScheme.onSecondary,
        colorScheme.secondary,
      ),
    );

    // Test error color combinations
    results.addTest(
      'Error on Surface',
      OmnisonicAccessibility.meetsWCAGAA(
        colorScheme.error,
        colorScheme.surface,
      ),
      OmnisonicAccessibility.calculateContrastRatio(
        colorScheme.error,
        colorScheme.surface,
      ),
    );

    results.addTest(
      'On Error on Error',
      OmnisonicAccessibility.meetsWCAGAA(
        colorScheme.onError,
        colorScheme.error,
      ),
      OmnisonicAccessibility.calculateContrastRatio(
        colorScheme.onError,
        colorScheme.error,
      ),
    );

    // Test surface color combinations
    results.addTest(
      'On Surface on Surface',
      OmnisonicAccessibility.meetsWCAGAA(
        colorScheme.onSurface,
        colorScheme.surface,
      ),
      OmnisonicAccessibility.calculateContrastRatio(
        colorScheme.onSurface,
        colorScheme.surface,
      ),
    );

    results.addTest(
      'Outline on Surface',
      OmnisonicAccessibility.meetsWCAGAA(
        colorScheme.outline,
        colorScheme.surface,
      ),
      OmnisonicAccessibility.calculateContrastRatio(
        colorScheme.outline,
        colorScheme.surface,
      ),
    );

    // Test custom Omnisonic colors
    results.addTest(
      'Playing Indicator on Surface',
      OmnisonicAccessibility.meetsWCAGAA(
        OmnisonicColors.playingIndicator,
        colorScheme.surface,
      ),
      OmnisonicAccessibility.calculateContrastRatio(
        OmnisonicColors.playingIndicator,
        colorScheme.surface,
      ),
    );

    results.addTest(
      'Success on Surface',
      OmnisonicAccessibility.meetsWCAGAA(
        OmnisonicColors.success,
        colorScheme.surface,
      ),
      OmnisonicAccessibility.calculateContrastRatio(
        OmnisonicColors.success,
        colorScheme.surface,
      ),
    );

    results.addTest(
      'Warning on Surface',
      OmnisonicAccessibility.meetsWCAGAA(
        OmnisonicColors.warning,
        colorScheme.surface,
      ),
      OmnisonicAccessibility.calculateContrastRatio(
        OmnisonicColors.warning,
        colorScheme.surface,
      ),
    );

    return results;
  }

  /// Test specific color combination
  static AccessibilityTestResult testColorCombination(
    String name,
    Color foreground,
    Color background,
  ) {
    final contrastRatio = OmnisonicAccessibility.calculateContrastRatio(
      foreground,
      background,
    );
    final meetsAA = OmnisonicAccessibility.meetsWCAGAA(foreground, background);
    final meetsAAA = OmnisonicAccessibility.meetsWCAGAAA(
      foreground,
      background,
    );

    return AccessibilityTestResult(
      name: name,
      passed: meetsAA,
      contrastRatio: contrastRatio,
      meetsAAA: meetsAAA,
      foregroundColor: foreground,
      backgroundColor: background,
    );
  }

  /// Generate accessibility report
  static String generateReport(AccessibilityTestResults results) {
    final buffer = StringBuffer();
    buffer.writeln('# Accessibility Test Report');
    buffer.writeln();
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Total Tests: ${results.totalTests}');
    buffer.writeln('Passed: ${results.passedTests}');
    buffer.writeln('Failed: ${results.failedTests}');
    buffer.writeln(
      'Pass Rate: ${(results.passRate * 100).toStringAsFixed(1)}%',
    );
    buffer.writeln();

    if (results.failedResults.isNotEmpty) {
      buffer.writeln('## Failed Tests');
      buffer.writeln();
      for (final result in results.failedResults) {
        buffer.writeln('### ${result.name}');
        buffer.writeln(
          '- Contrast Ratio: ${result.contrastRatio.toStringAsFixed(2)}:1',
        );
        buffer.writeln('- Required: 4.5:1 (AA)');
        buffer.writeln('- Status: FAILED');
        buffer.writeln();
      }
    }

    if (results.passedResults.isNotEmpty) {
      buffer.writeln('## Passed Tests');
      buffer.writeln();
      for (final result in results.passedResults) {
        buffer.writeln('### ${result.name}');
        buffer.writeln(
          '- Contrast Ratio: ${result.contrastRatio.toStringAsFixed(2)}:1',
        );
        buffer.writeln('- AA Standard: PASSED');
        if (result.meetsAAA == true) {
          buffer.writeln('- AAA Standard: PASSED');
        }
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// Create accessibility test widget for visual testing
  static Widget createTestWidget(AccessibilityTestResults results) {
    return AccessibilityTestWidget(results: results);
  }
}

/// Results container for accessibility tests
class AccessibilityTestResults {
  final List<AccessibilityTestResult> _results = [];

  void addTest(
    String name,
    bool passed,
    double contrastRatio, {
    bool? meetsAAA,
  }) {
    _results.add(
      AccessibilityTestResult(
        name: name,
        passed: passed,
        contrastRatio: contrastRatio,
        meetsAAA: meetsAAA ?? false,
      ),
    );
  }

  void addResult(AccessibilityTestResult result) {
    _results.add(result);
  }

  List<AccessibilityTestResult> get allResults => List.unmodifiable(_results);
  List<AccessibilityTestResult> get passedResults =>
      _results.where((r) => r.passed).toList();
  List<AccessibilityTestResult> get failedResults =>
      _results.where((r) => !r.passed).toList();

  int get totalTests => _results.length;
  int get passedTests => passedResults.length;
  int get failedTests => failedResults.length;
  double get passRate => totalTests > 0 ? passedTests / totalTests : 0.0;

  bool get allTestsPassed => failedTests == 0;
}

/// Individual accessibility test result
class AccessibilityTestResult {
  final String name;
  final bool passed;
  final double contrastRatio;
  final bool? meetsAAA;
  final Color? foregroundColor;
  final Color? backgroundColor;

  const AccessibilityTestResult({
    required this.name,
    required this.passed,
    required this.contrastRatio,
    this.meetsAAA,
    this.foregroundColor,
    this.backgroundColor,
  });

  String get grade {
    if (meetsAAA == true) return 'AAA';
    if (passed) return 'AA';
    return 'FAIL';
  }

  Color get statusColor {
    if (meetsAAA == true) return Colors.green.shade700;
    if (passed) return Colors.green;
    return Colors.red;
  }
}

/// Widget for displaying accessibility test results
class AccessibilityTestWidget extends StatelessWidget {
  final AccessibilityTestResults results;

  const AccessibilityTestWidget({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility Test Results'),
        backgroundColor: results.allTestsPassed ? Colors.green : Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(context),
            const SizedBox(height: 16),
            _buildResultsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Summary',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildSummaryItem(
                  'Total',
                  results.totalTests.toString(),
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildSummaryItem(
                  'Passed',
                  results.passedTests.toString(),
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _buildSummaryItem(
                  'Failed',
                  results.failedTests.toString(),
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: results.passRate,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                results.allTestsPassed ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pass Rate: ${(results.passRate * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildResultsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Test Results', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        ...results.allResults.map((result) => _buildResultItem(result)),
      ],
    );
  }

  Widget _buildResultItem(AccessibilityTestResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: result.statusColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              result.grade,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        title: Text(result.name),
        subtitle: Text(
          'Contrast Ratio: ${result.contrastRatio.toStringAsFixed(2)}:1',
        ),
        trailing:
            result.foregroundColor != null && result.backgroundColor != null
            ? _buildColorSample(
                result.foregroundColor!,
                result.backgroundColor!,
              )
            : null,
      ),
    );
  }

  Widget _buildColorSample(Color foreground, Color background) {
    return Container(
      width: 60,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          'Aa',
          style: TextStyle(color: foreground, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// Debug overlay for accessibility information
class AccessibilityDebugOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const AccessibilityDebugOverlay({
    super.key,
    required this.child,
    this.enabled = false,
  });

  @override
  State<AccessibilityDebugOverlay> createState() =>
      _AccessibilityDebugOverlayState();
}

class _AccessibilityDebugOverlayState extends State<AccessibilityDebugOverlay> {
  bool _showOverlay = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      children: [
        widget.child,
        if (_showOverlay) Positioned.fill(child: _buildDebugOverlay()),
        Positioned(
          top: MediaQuery.of(context).padding.top + 100,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            onPressed: () {
              setState(() {
                _showOverlay = !_showOverlay;
              });
            },
            child: Icon(_showOverlay ? Icons.visibility_off : Icons.visibility),
          ),
        ),
      ],
    );
  }

  Widget _buildDebugOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: const Center(
        child: Text(
          'Accessibility Debug Mode\n\nThis overlay shows accessibility information\nfor testing and development purposes.',
          style: TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
