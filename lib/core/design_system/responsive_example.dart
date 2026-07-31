import 'package:flutter/material.dart';
import 'responsive_layout.dart';
import 'orientation_handler.dart';
import 'spacing.dart';

/// Example implementation of responsive layout system
class ResponsiveLayoutExample extends StatelessWidget {
  const ResponsiveLayoutExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(title: const Text('Responsive Layout Example')),
      body: ResponsiveContainer(
        child: Column(
          children: [
            // Responsive grid example
            Expanded(
              child: ResponsiveGrid(
                children: List.generate(
                  20,
                  (index) => Card(
                    child: CompliantTouchTarget(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tapped card $index')),
                        );
                      },
                      child: Center(child: Text('Item $index')),
                    ),
                  ),
                ),
              ),
            ),

            // Responsive value example
            Container(
              height: ResponsiveValue<double>(
                mobile: 60,
                tablet: 80,
                desktop: 100,
              ).getValue(context),
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Center(
                child: Text(
                  'Screen: ${ResponsiveBreakpoints.getScreenType(context).name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),

            // Orientation adaptive layout example
            OrientationAdaptiveLayout(
              portrait: _buildPortraitLayout(context),
              landscape: _buildLandscapeLayout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context) {
    return Container(
      height: 100,
      margin: const EdgeInsets.all(OmnisonicSpacing.md),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: Text('Portrait Layout')),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.all(OmnisonicSpacing.md),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: Text('Landscape Layout')),
    );
  }
}

/// Example of adaptive layout that changes based on screen size and orientation
class AdaptiveLayoutExample extends StatelessWidget {
  const AdaptiveLayoutExample({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      builder: (context, screenType, isLandscape) {
        return ResponsiveScaffold(
          appBar: AppBar(
            title: Text(
              '${screenType.name} - ${isLandscape ? 'Landscape' : 'Portrait'}',
            ),
          ),
          body: _buildAdaptiveContent(context, screenType, isLandscape),
        );
      },
    );
  }

  Widget _buildAdaptiveContent(
    BuildContext context,
    ScreenType screenType,
    bool isLandscape,
  ) {
    switch (screenType) {
      case ScreenType.mobile:
        return _buildMobileLayout(context, isLandscape);
      case ScreenType.tablet:
        return _buildTabletLayout(context, isLandscape);
      case ScreenType.desktop:
      case ScreenType.largeDesktop:
        return _buildDesktopLayout(context, isLandscape);
    }
  }

  Widget _buildMobileLayout(BuildContext context, bool isLandscape) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(OmnisonicSpacing.md),
      child: Column(
        children: [
          _buildInfoCard('Mobile Layout', Colors.red),
          const SizedBox(height: OmnisonicSpacing.md),
          if (isLandscape) ...[
            Row(
              children: [
                Expanded(child: _buildFeatureCard('Feature 1')),
                const SizedBox(width: OmnisonicSpacing.md),
                Expanded(child: _buildFeatureCard('Feature 2')),
              ],
            ),
          ] else ...[
            _buildFeatureCard('Feature 1'),
            const SizedBox(height: OmnisonicSpacing.md),
            _buildFeatureCard('Feature 2'),
          ],
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, bool isLandscape) {
    return Padding(
      padding: const EdgeInsets.all(OmnisonicSpacing.lg),
      child: Column(
        children: [
          _buildInfoCard('Tablet Layout', Colors.orange),
          const SizedBox(height: OmnisonicSpacing.lg),
          Expanded(
            child: GridView.count(
              crossAxisCount: isLandscape ? 3 : 2,
              crossAxisSpacing: OmnisonicSpacing.md,
              mainAxisSpacing: OmnisonicSpacing.md,
              children: List.generate(
                6,
                (index) => _buildFeatureCard('Feature ${index + 1}'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isLandscape) {
    return Padding(
      padding: const EdgeInsets.all(OmnisonicSpacing.xl),
      child: Column(
        children: [
          _buildInfoCard('Desktop Layout', Colors.green),
          const SizedBox(height: OmnisonicSpacing.xl),
          Expanded(
            child: Row(
              children: [
                // Sidebar
                SizedBox(
                  width: 250,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(OmnisonicSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sidebar',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: OmnisonicSpacing.md),
                          ...List.generate(
                            5,
                            (index) => ListTile(
                              title: Text('Menu Item ${index + 1}'),
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: OmnisonicSpacing.lg),
                // Main content
                Expanded(
                  child: GridView.count(
                    crossAxisCount: isLandscape ? 4 : 3,
                    crossAxisSpacing: OmnisonicSpacing.lg,
                    mainAxisSpacing: OmnisonicSpacing.lg,
                    children: List.generate(
                      12,
                      (index) => _buildFeatureCard('Feature ${index + 1}'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, Color color) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(OmnisonicSpacing.lg),
        child: Row(
          children: [
            Icon(Icons.info, color: color),
            const SizedBox(width: OmnisonicSpacing.md),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title) {
    return Card(
      child: CompliantTouchTarget(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(OmnisonicSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 32),
              const SizedBox(height: OmnisonicSpacing.sm),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Example demonstrating keyboard handling
class KeyboardHandlingExample extends StatefulWidget {
  const KeyboardHandlingExample({super.key});

  @override
  State<KeyboardHandlingExample> createState() =>
      _KeyboardHandlingExampleState();
}

class _KeyboardHandlingExampleState extends State<KeyboardHandlingExample> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardAdaptiveLayout(
      child: ResponsiveScaffold(
        appBar: AppBar(
          title: const Text('Keyboard Handling Example'),
          actions: [
            IconButton(
              icon: const Icon(Icons.keyboard_hide),
              onPressed: () => KeyboardHandler.dismissKeyboard(context),
            ),
          ],
        ),
        body: ResponsiveContainer(
          child: Column(
            children: [
              // Keyboard status indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(OmnisonicSpacing.md),
                color: KeyboardHandler.isKeyboardVisible(context)
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                child: Text(
                  'Keyboard: ${KeyboardHandler.isKeyboardVisible(context) ? 'Visible' : 'Hidden'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),

              // Available height indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(OmnisonicSpacing.md),
                color: Colors.blue.withValues(alpha: 0.1),
                child: Text(
                  'Available Height: ${KeyboardHandler.getAvailableHeight(context).toStringAsFixed(0)}px',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),

              const SizedBox(height: OmnisonicSpacing.lg),

              // Text input field
              Padding(
                padding: const EdgeInsets.all(OmnisonicSpacing.md),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Type here to show keyboard',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(height: OmnisonicSpacing.lg),

              // Control buttons
              Wrap(
                spacing: OmnisonicSpacing.md,
                children: [
                  ElevatedButton(
                    onPressed: () => _focusNode.requestFocus(),
                    child: const Text('Show Keyboard'),
                  ),
                  ElevatedButton(
                    onPressed: () => KeyboardHandler.dismissKeyboard(context),
                    child: const Text('Hide Keyboard'),
                  ),
                ],
              ),

              const Spacer(),

              // Bottom content that should be visible above keyboard
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(OmnisonicSpacing.lg),
                color: Colors.purple.withValues(alpha: 0.1),
                child: const Text(
                  'This content should remain visible when keyboard appears',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
