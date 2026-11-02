import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../ui/presentation/widgets/widgets.dart';

import '../../../../core/design_system/design_system.dart';

import '../../../../core/entities/entities.dart';
import '../../utils/lrc_parser.dart';
import '../viewmodels/lyrics_view_model.dart';
import 'lyrics_search_sheet.dart';
import 'synced_lyrics_view.dart';
import 'unsynced_lyrics_view.dart';

class LyricsPanel extends StatefulWidget {
  const LyricsPanel({super.key, required this.track, required this.position});

  final Track? track;
  final Duration position;

  @override
  State<LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends State<LyricsPanel> {
  @override
  void initState() {
    super.initState();
    _syncTrack();
  }

  @override
  void didUpdateWidget(covariant LyricsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track?.id != widget.track?.id) {
      _syncTrack();
    }
  }

  void _syncTrack() {
    final viewModel = context.read<LyricsViewModel>();
    viewModel.setTrack(widget.track);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LyricsViewModel>();
    final scheme = Theme.of(context).colorScheme;

    if (widget.track == null) {
      return Center(
        child: Text(
          'No track playing',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }

    final lyrics = viewModel.lyrics;

    return Column(
      children: [
        _LyricsControls(viewModel: viewModel, track: widget.track!),
        const SizedBox(height: OmnisonicSpacing.md),
        Expanded(
          child: _LyricsBody(
            viewModel: viewModel,
            lyrics: lyrics,
            position: widget.position,
          ),
        ),
      ],
    );
  }
}

class _LyricsControls extends StatelessWidget {
  const _LyricsControls({required this.viewModel, required this.track});

  final LyricsViewModel viewModel;
  final Track track;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasSynced = viewModel.lyrics?.isSynced ?? false;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: OmnisonicSpacing.sm,
      runSpacing: OmnisonicSpacing.sm,
      children: [
        _SourceDropdown(
          value: viewModel.preferredSource,
          onChanged: viewModel.setPreferredSource,
        ),
        FilledButton.tonalIcon(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => LyricsSearchSheet(track: track),
            );
          },
          icon: const Icon(OmnisonicIcons.search),
          label: const Text('Search'),
        ),
        if (viewModel.override != null)
          OutlinedButton.icon(
            onPressed: viewModel.clearOverride,
            icon: const Icon(OmnisonicIcons.refresh),
            label: const Text('Auto'),
          ),
        if (hasSynced)
          FilterChip(
            label: const Text('Follow'),
            selected: viewModel.follow,
            onSelected: viewModel.setFollow,
          ),
        if (hasSynced)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: OmnisonicSpacing.sm,
              vertical: OmnisonicSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(OmnisonicRadius.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(OmnisonicIcons.remove),
                  onPressed: () => viewModel.adjustOffset(-250),
                  tooltip: 'Offset -250ms',
                ),
                Text('${viewModel.offsetMs} ms'),
                IconButton(
                  icon: const Icon(OmnisonicIcons.add),
                  onPressed: () => viewModel.adjustOffset(250),
                  tooltip: 'Offset +250ms',
                ),
                TextButton(
                  onPressed: viewModel.resetOffset,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SourceDropdown extends StatelessWidget {
  const _SourceDropdown({required this.value, required this.onChanged});

  final LyricsSource? value;
  final ValueChanged<LyricsSource?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<LyricsSource?>(
        value: value,
        items: const [
          DropdownMenuItem(value: null, child: Text('Auto')),
          DropdownMenuItem(value: LyricsSource.lrclib, child: Text('LRCLIB')),
          DropdownMenuItem(
            value: LyricsSource.lyricsOvh,
            child: Text('lyrics.ovh'),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _LyricsBody extends StatelessWidget {
  const _LyricsBody({
    required this.viewModel,
    required this.lyrics,
    required this.position,
  });

  final LyricsViewModel viewModel;
  final LyricsData? lyrics;
  final Duration position;

  @override
  Widget build(BuildContext context) {
    final data = lyrics;

    if (viewModel.isLoading && data == null) {
      return const LoadingStateView(kind: SkeletonKind.list, itemCount: 4);
    }

    // LyricsViewModel has tracked errorMessage all along; nothing rendered
    // it, so a failed fetch was indistinguishable from a track that simply
    // has no lyrics.
    final error = viewModel.errorMessage;
    if (error != null && data == null) {
      return ErrorStateView(
        title: 'Could not load lyrics',
        message: error,
        onRetry: viewModel.refresh,
      );
    }

    if (data == null || data.raw.trim().isEmpty) {
      return const EmptyState(
        icon: OmnisonicIcons.textSnippetOutline,
        title: 'Lyrics not available',
        subtitle: 'No lyrics were found for this track.',
      );
    }

    if (data.isSynced) {
      final lines = parseLrc(data.raw);
      return SyncedLyricsView(
        lines: lines,
        position: position,
        follow: viewModel.follow,
        offsetMs: viewModel.offsetMs,
      );
    }

    return UnsyncedLyricsView(text: data.raw);
  }
}
