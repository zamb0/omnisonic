import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/spacing.dart';
import '../../../../core/entities/entities.dart';
import '../viewmodels/lyrics_view_model.dart';

class LyricsSearchSheet extends StatefulWidget {
  const LyricsSearchSheet({
    super.key,
    required this.track,
  });

  final Track track;

  @override
  State<LyricsSearchSheet> createState() => _LyricsSearchSheetState();
}

class _LyricsSearchSheetState extends State<LyricsSearchSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late final TextEditingController _albumController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.track.title);
    _artistController = TextEditingController(text: widget.track.artist);
    _albumController = TextEditingController(text: widget.track.album);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LyricsViewModel>();
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: OmnisonicSpacing.md),
          Text(
            'Search lyrics (LRCLIB)',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: OmnisonicSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: OmnisonicSpacing.md),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                  ),
                ),
                const SizedBox(height: OmnisonicSpacing.sm),
                TextField(
                  controller: _artistController,
                  decoration: const InputDecoration(
                    labelText: 'Artist',
                  ),
                ),
                const SizedBox(height: OmnisonicSpacing.sm),
                TextField(
                  controller: _albumController,
                  decoration: const InputDecoration(
                    labelText: 'Album',
                  ),
                ),
                const SizedBox(height: OmnisonicSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: viewModel.isSearching
                            ? null
                            : () {
                                viewModel.searchLyrics(
                                  title: _titleController.text.trim(),
                                  artist: _artistController.text.trim(),
                                  album: _albumController.text.trim(),
                                );
                              },
                        icon: viewModel.isSearching
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: const Text('Search'),
                      ),
                    ),
                    const SizedBox(width: OmnisonicSpacing.sm),
                    if (viewModel.override != null)
                      OutlinedButton(
                        onPressed: () async {
                          await viewModel.clearOverride();
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Clear override'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: OmnisonicSpacing.md),
          _SearchResultsList(viewModel: viewModel),
          const SizedBox(height: OmnisonicSpacing.md),
        ],
      ),
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({
    required this.viewModel,
  });

  final LyricsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final results = viewModel.searchResults;
    final theme = Theme.of(context);

    if (viewModel.isSearching) {
      return const SizedBox.shrink();
    }

    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: OmnisonicSpacing.md),
        child: Text(
          'No results yet',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      height: 260,
      child: ListView.separated(
        itemCount: results.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final result = results[index];
          return ListTile(
            title: Text(result.title),
            subtitle: Text(result.artist),
            trailing: result.isSynced
                ? const Icon(Icons.sync)
                : const Icon(Icons.text_snippet_outlined),
            onTap: () async {
              await viewModel.applySearchResult(result);
              if (context.mounted) Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
