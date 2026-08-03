import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../viewmodels/playlist_view_model.dart';
import '../widgets/playlist_creation_dialog.dart';
import '../widgets/playlist_edit_dialog.dart';
import '../widgets/playlist_list_tile.dart';
import '../../../ui/presentation/widgets/loading_indicator.dart';

/// Page for managing playlists - creation, editing, deletion, and organization
class PlaylistManagementPage extends StatefulWidget {
  const PlaylistManagementPage({super.key});

  @override
  State<PlaylistManagementPage> createState() => _PlaylistManagementPageState();
}

class _PlaylistManagementPageState extends State<PlaylistManagementPage> {
  String _searchQuery = '';
  bool _showPublicOnly = false;
  bool _showPrivateOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlist Management'),
        actions: [
          IconButton(
            icon: const Icon(OmnisonicIcons.add),
            onPressed: () => _showCreatePlaylistDialog(context),
            tooltip: 'Create Playlist',
          ),
        ],
      ),
      body: Consumer<PlaylistViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    OmnisonicIcons.errorOutline,
                    size: OmnisonicIconSizes.xxxl,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.errorMessage!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.clearError();
                      viewModel.refreshPlaylists();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildSearchAndFilters(viewModel),
              Expanded(child: _buildPlaylistList(viewModel)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(PlaylistViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search playlists...',
              prefixIcon: const Icon(OmnisonicIcons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(OmnisonicIcons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                        viewModel.clearSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              if (value.trim().isNotEmpty) {
                viewModel.searchPlaylists(value);
              } else {
                viewModel.clearSearch();
              }
            },
          ),
          const SizedBox(height: 12),
          // Filter chips
          Row(
            children: [
              FilterChip(
                label: const Text('Public'),
                selected: _showPublicOnly,
                onSelected: (selected) {
                  setState(() {
                    _showPublicOnly = selected;
                    if (selected) _showPrivateOnly = false;
                  });
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Private'),
                selected: _showPrivateOnly,
                onSelected: (selected) {
                  setState(() {
                    _showPrivateOnly = selected;
                    if (selected) _showPublicOnly = false;
                  });
                },
              ),
              const Spacer(),
              Text(
                '${_getFilteredPlaylists(viewModel).length} playlists',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistList(PlaylistViewModel viewModel) {
    final playlists = _getFilteredPlaylists(viewModel);

    if (playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              OmnisonicIcons.playlistPlay,
              size: OmnisonicIconSizes.xxxl,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No playlists found for "$_searchQuery"'
                  : 'No playlists yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Create your first playlist to get started',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showCreatePlaylistDialog(context),
                icon: const Icon(OmnisonicIcons.add),
                label: const Text('Create Playlist'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.refreshPlaylists,
      child: ListView.builder(
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return PlaylistListTile(
            playlist: playlist,
            onTap: () => _navigateToPlaylistDetail(context, playlist),
            onEdit: () => _showEditPlaylistDialog(context, playlist),
            onDelete: () =>
                _showDeleteConfirmation(context, playlist, viewModel),
            onDuplicate: () =>
                _showDuplicateDialog(context, playlist, viewModel),
          );
        },
      ),
    );
  }

  List<Playlist> _getFilteredPlaylists(PlaylistViewModel viewModel) {
    List<Playlist> playlists;

    if (_searchQuery.isNotEmpty) {
      playlists = viewModel.searchResults;
    } else {
      playlists = viewModel.playlists;
    }

    if (_showPublicOnly) {
      playlists = playlists.where((p) => p.isPublic).toList();
    } else if (_showPrivateOnly) {
      playlists = playlists.where((p) => !p.isPublic).toList();
    }

    return playlists;
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PlaylistCreationDialog(),
    );
  }

  void _showEditPlaylistDialog(BuildContext context, Playlist playlist) {
    showDialog(
      context: context,
      builder: (context) => PlaylistEditDialog(playlist: playlist),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Playlist playlist,
    PlaylistViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await viewModel.deletePlaylist(playlist.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted "${playlist.name}"')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDuplicateDialog(
    BuildContext context,
    Playlist playlist,
    PlaylistViewModel viewModel,
  ) {
    final controller = TextEditingController(text: '${playlist.name} (Copy)');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New playlist name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.of(context).pop();
                final success = await viewModel.duplicatePlaylist(
                  playlist.id,
                  newName,
                );
                if (success && context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Created "$newName"')));
                }
              }
            },
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );
  }

  void _navigateToPlaylistDetail(BuildContext context, Playlist playlist) {
    context.go(AppRouter.playlistDetailLocation(playlist.id));
  }
}
