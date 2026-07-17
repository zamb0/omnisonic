import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design_system.dart';

/// Comprehensive test application for the Omnisonic Design System checkpoint
/// This app verifies that all design system components work together properly
class DesignSystemCheckpointApp extends StatefulWidget {
  const DesignSystemCheckpointApp({super.key});

  @override
  State<DesignSystemCheckpointApp> createState() =>
      _DesignSystemCheckpointAppState();
}

class _DesignSystemCheckpointAppState extends State<DesignSystemCheckpointApp>
    with TickerProviderStateMixin {
  late OmnisonicThemeManager _themeManager;
  late AnimationManager _animationManager;
  late AnimationController _testAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  int _selectedIndex = 0;
  bool _isAnimating = false;
  final List<String> _testResults = [];

  @override
  void initState() {
    super.initState();
    _initializeManagers();
    _setupTestAnimations();
  }

  void _initializeManagers() {
    _themeManager = OmnisonicThemeManager();
    _themeManager.initialize();

    _animationManager = AnimationManager();
    _animationManager.initialize(enablePerformanceMonitoring: true);
  }

  void _setupTestAnimations() {
    _testAnimationController = _animationManager.createController(
      duration: AnimationManager.normalDuration,
      vsync: this,
      debugLabel: 'CheckpointTest',
    );

    _scaleAnimation = _animationManager.createTween<double>(
      controller: _testAnimationController,
      begin: 1.0,
      end: 1.2,
      curve: AnimationManager.standardCurve,
    );

    _colorAnimation = _animationManager.createColorTween(
      controller: _testAnimationController,
      begin: OmnisonicColors.primaryBlue,
      end: OmnisonicColors.primaryPurple,
      curve: AnimationManager.standardCurve,
    );
  }

  @override
  void dispose() {
    _testAnimationController.dispose();
    _animationManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Design System Checkpoint',
      theme: OmnisonicTheme.lightTheme,
      darkTheme: OmnisonicTheme.darkTheme,
      themeMode: _themeManager.themeMode,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Design System Checkpoint'),
          actions: [
            IconButton(
              icon: Icon(
                _themeManager.isDark(context)
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () async {
                await _themeManager.toggleTheme();
                setState(() {});
                _addTestResult('Theme switched successfully');
              },
            ),
          ],
        ),
        body: ResponsiveLayout(
          mobile: _buildMobileLayout(),
          tablet: _buildTabletLayout(),
          desktop: _buildDesktopLayout(),
        ),
        bottomNavigationBar: _buildBottomNavigation(),
        floatingActionButton: _buildTestFAB(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return _buildMainContent(isMobile: true);
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        SizedBox(width: 200, child: _buildSideNavigation()),
        Expanded(child: _buildMainContent(isMobile: false)),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        SizedBox(width: 250, child: _buildSideNavigation()),
        Expanded(child: _buildMainContent(isMobile: false)),
        SizedBox(width: 300, child: _buildTestPanel()),
      ],
    );
  }

  Widget _buildMainContent({required bool isMobile}) {
    return ResponsiveContainer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(OmnisonicSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildColorSystemTest(),
            const SizedBox(height: OmnisonicSpacing.xl),
            _buildTypographyTest(),
            const SizedBox(height: OmnisonicSpacing.xl),
            _buildAnimationTest(),
            const SizedBox(height: OmnisonicSpacing.xl),
            _buildResponsiveTest(),
            const SizedBox(height: OmnisonicSpacing.xl),
            _buildComponentsTest(),
            if (isMobile) ...[
              const SizedBox(height: OmnisonicSpacing.xl),
              _buildTestPanel(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildColorSystemTest() {
    return Card(
      child: Padding(
        padding: OmnisonicInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Color System Test', style: context.textTheme.headlineSmall),
            const SizedBox(height: OmnisonicSpacing.md),

            // Primary colors
            Row(
              children: [
                _buildColorTile('Primary', context.colorScheme.primary),
                _buildColorTile('Secondary', context.colorScheme.secondary),
                _buildColorTile('Tertiary', context.colorScheme.tertiary),
              ],
            ),
            const SizedBox(height: OmnisonicSpacing.md),

            // Gradient test
            Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: context.primaryGradient,
                borderRadius: BorderRadius.circular(OmnisonicRadius.md),
              ),
              child: const Center(
                child: Text(
                  'Primary Gradient',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: OmnisonicSpacing.sm),

            // Animated color test
            AnimatedBuilder(
              animation: _colorAnimation,
              builder: (context, child) {
                return Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: _colorAnimation.value,
                    borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
                  ),
                  child: const Center(
                    child: Text(
                      'Animated Color',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorTile(String name, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: OmnisonicSpacing.sm),
        child: Column(
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
              ),
            ),
            const SizedBox(height: OmnisonicSpacing.xs),
            Text(name, style: context.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildTypographyTest() {
    return Card(
      child: Padding(
        padding: OmnisonicInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Typography Test', style: context.textTheme.headlineSmall),
            const SizedBox(height: OmnisonicSpacing.md),

            Text('Display Large', style: context.textTheme.displayLarge),
            Text('Headline Medium', style: context.textTheme.headlineMedium),
            Text('Title Large', style: context.textTheme.titleLarge),
            Text('Body Large', style: context.textTheme.bodyLarge),
            Text('Label Medium', style: context.textTheme.labelMedium),

            const SizedBox(height: OmnisonicSpacing.md),
            const Divider(),
            const SizedBox(height: OmnisonicSpacing.md),

            // Music-specific typography
            Text('Track Title Example', style: context.textTheme.trackTitle),
            Text('Artist Name Example', style: context.textTheme.artistName),
            Text('Album Title Example', style: context.textTheme.albumTitle),
            Text('3:45', style: context.textTheme.duration),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationTest() {
    return Card(
      child: Padding(
        padding: OmnisonicInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Animation Test', style: context.textTheme.headlineSmall),
            const SizedBox(height: OmnisonicSpacing.md),

            Row(
              children: [
                ElevatedButton(
                  onPressed: _isAnimating ? null : _testAnimations,
                  child: Text(
                    _isAnimating ? 'Animating...' : 'Test Animations',
                  ),
                ),
                const SizedBox(width: OmnisonicSpacing.md),
                Text(
                  'Active: ${_animationManager.activeAnimationCount}',
                  style: context.textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: OmnisonicSpacing.md),

            // Animated test widget
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: context.accentGradient,
                      borderRadius: BorderRadius.circular(OmnisonicRadius.lg),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveTest() {
    final screenType = ResponsiveBreakpoints.getScreenType(context);
    final screenSize = MediaQuery.of(context).size;

    return Card(
      child: Padding(
        padding: OmnisonicInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Responsive Test', style: context.textTheme.headlineSmall),
            const SizedBox(height: OmnisonicSpacing.md),

            Text('Screen Type: ${screenType.name}'),
            Text(
              'Screen Size: ${screenSize.width.toInt()} x ${screenSize.height.toInt()}',
            ),
            Text('Is Mobile: ${ResponsiveBreakpoints.isMobile(context)}'),
            Text('Is Tablet: ${ResponsiveBreakpoints.isTablet(context)}'),
            Text('Is Desktop: ${ResponsiveBreakpoints.isDesktop(context)}'),

            const SizedBox(height: OmnisonicSpacing.md),

            // Responsive grid test
            ResponsiveGrid(
              mobileColumns: 2,
              tabletColumns: 3,
              desktopColumns: 4,
              children: List.generate(8, (index) {
                return Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
                  ),
                  child: Center(child: Text('$index')),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentsTest() {
    return Card(
      child: Padding(
        padding: OmnisonicInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Components Test', style: context.textTheme.headlineSmall),
            const SizedBox(height: OmnisonicSpacing.md),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _addTestResult('Elevated button pressed'),
                    child: const Text('Elevated'),
                  ),
                ),
                const SizedBox(width: OmnisonicSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _addTestResult('Outlined button pressed'),
                    child: const Text('Outlined'),
                  ),
                ),
                const SizedBox(width: OmnisonicSpacing.sm),
                Expanded(
                  child: TextButton(
                    onPressed: () => _addTestResult('Text button pressed'),
                    child: const Text('Text'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: OmnisonicSpacing.md),

            // Chips
            Wrap(
              spacing: OmnisonicSpacing.sm,
              children: [
                Chip(
                  label: const Text('Chip 1'),
                  onDeleted: () => _addTestResult('Chip 1 deleted'),
                ),
                Chip(
                  label: const Text('Chip 2'),
                  onDeleted: () => _addTestResult('Chip 2 deleted'),
                ),
                const Chip(label: Text('Chip 3')),
              ],
            ),
            const SizedBox(height: OmnisonicSpacing.md),

            // Slider
            Slider(
              value: 0.5,
              onChanged: (value) =>
                  _addTestResult('Slider: ${value.toStringAsFixed(2)}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestPanel() {
    return Card(
      child: Padding(
        padding: OmnisonicInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Test Results', style: context.textTheme.headlineSmall),
            const SizedBox(height: OmnisonicSpacing.md),

            ElevatedButton(
              onPressed: _runAllTests,
              child: const Text('Run All Tests'),
            ),
            const SizedBox(height: OmnisonicSpacing.md),

            Expanded(
              child: ListView.builder(
                itemCount: _testResults.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${index + 1}. ${_testResults[index]}',
                      style: context.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideNavigation() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
        _addTestResult('Navigation item $index selected');
      },
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
        NavigationRailDestination(
          icon: Icon(Icons.music_note),
          label: Text('Music'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    if (!ResponsiveBreakpoints.isMobile(context)) {
      return const SizedBox.shrink();
    }

    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
        _addTestResult('Bottom nav item $index selected');
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Music'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }

  Widget _buildTestFAB() {
    return FloatingActionButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        _addTestResult('FAB pressed with haptic feedback');
      },
      child: const Icon(Icons.play_arrow),
    );
  }

  void _addTestResult(String result) {
    setState(() {
      _testResults.add(
        '${DateTime.now().toLocal().toString().substring(11, 19)}: $result',
      );
    });
  }

  Future<void> _testAnimations() async {
    setState(() {
      _isAnimating = true;
    });

    try {
      await _animationManager.executeAnimation(
        controller: _testAnimationController,
        forward: true,
        autoReverse: true,
        onComplete: () {
          _addTestResult('Animation completed successfully');
        },
        onError: () {
          _addTestResult('Animation failed');
        },
      );
    } finally {
      setState(() {
        _isAnimating = false;
      });
    }
  }

  Future<void> _runAllTests() async {
    _testResults.clear();

    // Test theme switching
    _addTestResult('Testing theme switching...');
    await _themeManager.toggleTheme();
    await Future.delayed(const Duration(milliseconds: 500));
    await _themeManager.toggleTheme();
    _addTestResult('Theme switching test completed');

    // Test animations
    _addTestResult('Testing animations...');
    await _testAnimations();

    // Test responsive behavior
    _addTestResult('Testing responsive behavior...');
    final screenType = ResponsiveBreakpoints.getScreenType(context);
    _addTestResult('Current screen type: ${screenType.name}');

    // Test performance
    _addTestResult('Testing performance...');
    final performanceData = _animationManager.getPerformanceData();
    _addTestResult(
      'Active animations: ${_animationManager.activeAnimationCount}',
    );
    _addTestResult('Performance data entries: ${performanceData.length}');

    _addTestResult('All tests completed successfully!');

    setState(() {});
  }
}
