import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import '../widgets/widgets.dart';
import '../../../../core/entities/entities.dart';

/// Home page displaying smart collections and recently played content
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MusicLibraryViewModel>().refreshSmartCollections();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 16),
              _buildRecentlyPlayedSection(),
              const SizedBox(height: 24),
              _buildRecentlyAddedSection(),
              const SizedBox(height: 24),
              _buildQuickActionsSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Discover your music collection',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              if (viewModel.isSyncing) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Syncing music collection...',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (viewModel.hasCollection && !viewModel.isSyncing) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.library_music,
                        size: 16,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${viewModel.trackCount} tracks • ${viewModel.albumCount} albums • ${viewModel.artistCount} artists',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentlyPlayedSection() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return _buildLoadingSection('Recently Played');
        }

        final recentTracks = viewModel.recentlyPlayed;
        if (recentTracks.isEmpty) {
          return _buildEmptySection(
            'Recently Played',
            'Start playing music to see your recent tracks here',
            Icons.history,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Recently Played',
              subtitle: 'Your latest listening activity',
              onSeeAllPressed: () => _navigateToRecentlyPlayed(),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recentTracks.length.clamp(0, 10),
                itemBuilder: (context, index) {
                  final track = recentTracks[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildTrackCard(track),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentlyAddedSection() {
    return Consumer<MusicLibraryViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return _buildLoadingSection('Recently Added');
        }

        final recentTracks = viewModel.recentlyAdded;
        if (recentTracks.isEmpty) {
          return _buildEmptySection(
            'Recently Added',
            'New tracks will appear here when synced',
            Icons.new_releases,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Recently Added',
              subtitle: 'Latest additions to your library',
              onSeeAllPressed: () => _navigateToRecentlyAdded(),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recentTracks.length.clamp(0, 10),
                itemBuilder: (context, index) {
                  final track = recentTracks[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildTrackCard(track),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Quick Actions',
          subtitle: 'Manage your music',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.sync,
                      title: 'Sync Library',
                      subtitle: 'Update your collection',
                      onTap: _syncLibrary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.settings,
                      title: 'Manage Servers',
                      subtitle: 'Configure connections',
                      onTap: _navigateToServers,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // DEBUG: Temporary button for testing unique IDs
              SizedBox(
                width: double.infinity,
                child: _buildActionCard(
                  icon: Icons.bug_report,
                  title: 'DEBUG: Clear & Resync',
                  subtitle: 'Test unique IDs (temporary)',
                  onTap: _debugClearAndResync,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final iconColor = color ?? Theme.of(context).primaryColor;
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: iconColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackCard(Track track) {
    return SizedBox(
      width: 160,
      child: Card(
        child: InkWell(
          onTap: () => _onTrackTapped(track),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.grey[300],
                  ),
                  child: track.coverArtUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            track.coverArtUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.music_note, color: Colors.grey),
                          ),
                        )
                      : const Icon(Icons.music_note, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  track.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  track.artist,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            itemBuilder: (context, index) {
              return const Padding(
                padding: EdgeInsets.only(right: 12),
                child: ShimmerCard(width: 160, height: 180),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySection(String title, String message, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        SizedBox(
          height: 200,
          child: EmptyState(
            icon: icon,
            title: 'No $title',
            subtitle: message,
          ),
        ),
      ],
    );
  }

  Future<void> _onRefresh() async {
    final viewModel = context.read<MusicLibraryViewModel>();
    await viewModel.refreshSmartCollections();
  }

  void _onTrackTapped(Track track) {
    context.read<PlaybackViewModel>().playTrack(track);
  }

  void _onAlbumTapped(Album album) {
    // Navigate to album detail page
    context.go('/album-detail', extra: album);
  }

  void _showTrackOptions(Track track) {
    // Show track options bottom sheet
    // TODO: Implement track options
  }

  void _syncLibrary() {
    context.read<MusicLibraryViewModel>().syncCollection();
  }

  void _navigateToServers() {
    // Navigate to server management
    // TODO: Implement server navigation
  }

  void _navigateToRecentlyPlayed() {
    // Navigate to recently played list
    // TODO: Implement navigation
  }

  void _navigateToRecentlyAdded() {
    // Navigate to recently added list
    // TODO: Implement navigation
  }


  void _debugClearAndResync() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DEBUG: Clear & Resync'),
        content: const Text(
          'This will clear ALL music data from the database and resync from servers. '
          'This is for testing unique IDs. Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Clear & Resync'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final viewModel = context.read<MusicLibraryViewModel>();
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🧹 Clearing database and resyncing...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Call debug method (we'll need to add this to the view model)
      await viewModel.debugClearAndResync();
    }
  }
}