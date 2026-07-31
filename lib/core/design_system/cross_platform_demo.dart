import 'package:flutter/material.dart';
import 'design_system.dart';
import '../entities/album.dart';
import '../entities/artist.dart';

/// Cross-platform demo app to showcase visual consistency across platforms
/// Implements Requirements: 2.1, 2.2, 9.1
class CrossPlatformDemoApp extends StatelessWidget {
  const CrossPlatformDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Omnisonic Cross-Platform Demo',
      theme: addPlatformExtensions(OmnisonicTheme.lightTheme),
      darkTheme: addPlatformExtensions(OmnisonicTheme.darkTheme),
      home: const CrossPlatformDemoHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Demo home page showcasing platform-optimized components
class CrossPlatformDemoHome extends StatefulWidget {
  const CrossPlatformDemoHome({super.key});

  @override
  State<CrossPlatformDemoHome> createState() => _CrossPlatformDemoHomeState();
}

class _CrossPlatformDemoHomeState extends State<CrossPlatformDemoHome> {
  bool _isDarkMode = false;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return PlatformConsistencyValidator(
      child: PerformanceMonitoringWidget(
        child: ResponsiveBehaviorValidatorWidget(
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                'Platform: ${PlatformOptimizations().currentPlatform.name}',
              ),
              actions: [
                PlatformIconButton(
                  icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () {
                    setState(() {
                      _isDarkMode = !_isDarkMode;
                    });
                  },
                  tooltip: 'Toggle theme',
                ),
              ],
            ),
            body: ResponsiveLayout(
              mobile: _buildMobileLayout(),
              tablet: _buildTabletLayout(),
              desktop: _buildDesktopLayout(),
            ),
            bottomNavigationBar: _buildBottomNavigation(),
            floatingActionButton: PlatformFloatingActionButton(
              onPressed: () => _showPlatformDialog(context),
              child: const Icon(Icons.info),
              tooltip: 'Platform Info',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(OmnisonicSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlatformInfoCard(),
          const SizedBox(height: OmnisonicSpacing.lg),
          _buildButtonShowcase(),
          const SizedBox(height: OmnisonicSpacing.lg),
          _buildCardShowcase(),
          const SizedBox(height: OmnisonicSpacing.lg),
          _buildAnimationShowcase(),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Padding(
      padding: const EdgeInsets.all(OmnisonicSpacing.lg),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildPlatformInfoCard(),
                const SizedBox(height: OmnisonicSpacing.lg),
                _buildButtonShowcase(),
              ],
            ),
          ),
          const SizedBox(width: OmnisonicSpacing.lg),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildCardShowcase(),
                const SizedBox(height: OmnisonicSpacing.lg),
                _buildAnimationShowcase(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(OmnisonicSpacing.xl),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildPlatformInfoCard(),
                const SizedBox(height: OmnisonicSpacing.lg),
                _buildButtonShowcase(),
              ],
            ),
          ),
          const SizedBox(width: OmnisonicSpacing.xl),
          Expanded(flex: 2, child: _buildCardShowcase()),
          const SizedBox(width: OmnisonicSpacing.xl),
          Expanded(flex: 1, child: _buildAnimationShowcase()),
        ],
      ),
    );
  }

  Widget _buildPlatformInfoCard() {
    final platform = PlatformOptimizations();
    final platformTheme = context.platformTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(OmnisonicSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Platform Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: OmnisonicSpacing.sm),
            _buildInfoRow('Platform', platform.currentPlatform.name),
            _buildInfoRow('Supports Hover', platform.supportsHover.toString()),
            _buildInfoRow(
              'Supports Haptics',
              platform.supportsHaptics.toString(),
            ),
            _buildInfoRow(
              'Touch Target Size',
              '${platformTheme.touchTargetSize}px',
            ),
            _buildInfoRow('Border Radius', '${platformTheme.borderRadius}px'),
            _buildInfoRow('Default Elevation', '${platformTheme.elevation}px'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonShowcase() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(OmnisonicSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Platform Buttons',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: OmnisonicSpacing.md),
            Wrap(
              spacing: OmnisonicSpacing.sm,
              runSpacing: OmnisonicSpacing.sm,
              children: [
                PlatformButton(
                  type: PlatformButtonType.elevated,
                  onPressed: () => _showSnackBar('Elevated button pressed'),
                  child: const Text('Elevated'),
                ),
                PlatformButton(
                  type: PlatformButtonType.filled,
                  onPressed: () => _showSnackBar('Filled button pressed'),
                  child: const Text('Filled'),
                ),
                PlatformButton(
                  type: PlatformButtonType.outlined,
                  onPressed: () => _showSnackBar('Outlined button pressed'),
                  child: const Text('Outlined'),
                ),
                PlatformButton(
                  type: PlatformButtonType.text,
                  onPressed: () => _showSnackBar('Text button pressed'),
                  child: const Text('Text'),
                ),
              ],
            ),
            const SizedBox(height: OmnisonicSpacing.md),
            Row(
              children: [
                PlatformIconButton(
                  icon: const Icon(Icons.favorite),
                  onPressed: () => _showSnackBar('Favorite pressed'),
                  tooltip: 'Favorite',
                ),
                const SizedBox(width: OmnisonicSpacing.sm),
                PlatformIconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _showSnackBar('Share pressed'),
                  tooltip: 'Share',
                ),
                const SizedBox(width: OmnisonicSpacing.sm),
                PlatformIconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showSnackBar('More pressed'),
                  tooltip: 'More options',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardShowcase() {
    // Create sample album data
    final sampleAlbum = Album(
      id: 'demo-album',
      title: 'Platform Demo Album',
      artist: 'Cross-Platform Artist',
      serverId: 'demo-server',
      lastModified: DateTime.now(),
      coverArtUrl: null, // Will show placeholder
      trackCount: 12,
      year: 2024,
      duration: const Duration(minutes: 45),
    );

    final sampleArtist = Artist(
      id: 'demo-artist',
      name: 'Demo Artist',
      serverId: 'demo-server',
      lastModified: DateTime.now(),
      imageUrl: null, // Will show placeholder
      albumCount: 5,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(OmnisonicSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Platform Cards',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: OmnisonicSpacing.md),
            ResponsiveLayout(
              mobile: Column(
                children: [
                  PlatformEnhancedAlbumCard(
                    album: sampleAlbum,
                    onTap: () => _showSnackBar('Album card tapped'),
                  ),
                  const SizedBox(height: OmnisonicSpacing.md),
                  PlatformEnhancedArtistCard(
                    artist: sampleArtist,
                    onTap: () => _showSnackBar('Artist card tapped'),
                  ),
                ],
              ),
              tablet: Row(
                children: [
                  Expanded(
                    child: PlatformEnhancedAlbumCard(
                      album: sampleAlbum,
                      onTap: () => _showSnackBar('Album card tapped'),
                    ),
                  ),
                  const SizedBox(width: OmnisonicSpacing.md),
                  Expanded(
                    child: PlatformEnhancedArtistCard(
                      artist: sampleArtist,
                      onTap: () => _showSnackBar('Artist card tapped'),
                    ),
                  ),
                ],
              ),
              desktop: Row(
                children: [
                  Expanded(
                    child: PlatformEnhancedAlbumCard(
                      album: sampleAlbum,
                      onTap: () => _showSnackBar('Album card tapped'),
                    ),
                  ),
                  const SizedBox(width: OmnisonicSpacing.md),
                  Expanded(
                    child: PlatformEnhancedArtistCard(
                      artist: sampleArtist,
                      onTap: () => _showSnackBar('Artist card tapped'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationShowcase() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(OmnisonicSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Platform Animations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: OmnisonicSpacing.md),
            const PlatformAnimationDemo(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
        _showSnackBar('Tab ${index + 1} selected');
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_music),
          label: 'Library',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showPlatformDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Platform Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Platform: ${PlatformOptimizations().currentPlatform.name}',
            ),
            const SizedBox(height: 8),
            Text('Supports Hover: ${PlatformOptimizations().supportsHover}'),
            Text(
              'Supports Haptics: ${PlatformOptimizations().supportsHaptics}',
            ),
            const SizedBox(height: 8),
            Text(
              'Touch Target Size: ${context.platformTheme.touchTargetSize}px',
            ),
            Text('Border Radius: ${context.platformTheme.borderRadius}px'),
            Text('Elevation: ${context.platformTheme.elevation}px'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Demo widget showing platform-specific animations
class PlatformAnimationDemo extends StatefulWidget {
  const PlatformAnimationDemo({super.key});

  @override
  State<PlatformAnimationDemo> createState() => _PlatformAnimationDemoState();
}

class _PlatformAnimationDemoState extends State<PlatformAnimationDemo>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    final platformAnimations = PlatformAnimations();

    _scaleController = AnimationController(
      duration: platformAnimations.durations.medium,
      vsync: this,
    );

    _slideController = AnimationController(
      duration: platformAnimations.durations.medium,
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: platformAnimations.durations.medium,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final platformAnimations = PlatformAnimations();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                if (_scaleController.isCompleted) {
                  _scaleController.reverse();
                } else {
                  _scaleController.forward();
                }
              },
              child: const Text('Scale'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_slideController.isCompleted) {
                  _slideController.reverse();
                } else {
                  _slideController.forward();
                }
              },
              child: const Text('Slide'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_fadeController.isCompleted) {
                  _fadeController.reverse();
                } else {
                  _fadeController.forward();
                }
              },
              child: const Text('Fade'),
            ),
          ],
        ),
        const SizedBox(height: OmnisonicSpacing.md),
        SizedBox(
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              platformAnimations.scaleTransition(
                animation: _scaleController,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
              ),
              platformAnimations.slideTransition(
                animation: _slideController,
                direction: SlideDirection.fromLeft,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.album, color: Colors.white),
                ),
              ),
              platformAnimations.fadeTransition(
                animation: _fadeController,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.headphones, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
