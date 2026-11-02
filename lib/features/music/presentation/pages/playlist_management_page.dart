import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../viewmodels/playlist_view_model.dart';
import '../../../../core/utils/formatters.dart';
import '../widgets/playlist_actions.dart';
import '../widgets/playlist_form_dialog.dart';
import '../widgets/playlist_list_tile.dart';
import '../../../ui/presentation/widgets/widgets.dart';

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
      appBar: PageHeaderAppBar(
        title: 'Playlists',
        actions: [
          IconButton(
            icon: const Icon(OmnisonicIcons.add),
            onPressed: () => showPlaylistFormDialog(context),
            tooltip: 'New playlist',
          ),
        ],
      ),
      body: Consumer<PlaylistViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const LoadingStateView(kind: SkeletonKind.list);
          }

          // Only a failure to load the list replaces it. A failed delete
          // or duplicate is an action error, shown as a snackbar.
          final error = viewModel.errorMessage;
          if (error != null && !viewModel.hasPlaylists) {
            return ErrorStateView(
              message: error,
              onRetry: () {
                viewModel.clearError();
                viewModel.refreshPlaylists();
              },
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
                      tooltip: 'Clear search',
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
                pluralize(_getFilteredPlaylists(viewModel).length, 'playlist'),
                style: OmnisonicTypography.metadata.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
      final searching = _searchQuery.isNotEmpty;
      return RefreshIndicator(
        onRefresh: viewModel.refreshPlaylists,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: EmptyState(
                icon: OmnisonicIcons.playlistPlay,
                title: searching
                    ? 'No playlists match "$_searchQuery"'
                    : 'No playlists yet',
                subtitle: searching
                    ? 'Try a different search.'
                    : 'Make one, then add tracks from any album or search.',
                action: searching
                    ? null
                    : FilledButton.icon(
                        onPressed: () => showPlaylistFormDialog(context),
                        icon: const Icon(OmnisonicIcons.add),
                        label: const Text('New playlist'),
                      ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.refreshPlaylists,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return PlaylistListTile(
            playlist: playlist,
            onTap: () => _navigateToPlaylistDetail(context, playlist),
            onEdit: () => showPlaylistFormDialog(context, playlist: playlist),
            onDelete: () => confirmAndDeletePlaylist(context, playlist),
            onDuplicate: () => duplicatePlaylistFlow(context, playlist),
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

  void _navigateToPlaylistDetail(BuildContext context, Playlist playlist) {
    context.push(AppRouter.playlistDetailLocation(playlist.id));
  }
}
