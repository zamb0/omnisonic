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

/// Follow inline; source, search, override and timing offset in an
/// overflow menu. As a Wrap of six controls they took two or three rows of
/// a phone-height sheet before the first line of lyrics.
class _LyricsControls extends StatelessWidget {
  const _LyricsControls({required this.viewModel, required this.track});

  final LyricsViewModel viewModel;
  final Track track;

  String _sourceLabel(LyricsSource? source) => switch (source) {
    null => 'Automatic',
    LyricsSource.lrclib => 'LRCLIB',
    LyricsSource.lyricsOvh => 'lyrics.ovh',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasSynced = viewModel.lyrics?.isSynced ?? false;
    final offset = viewModel.offsetMs;

    Widget check(bool on) => on
        ? Icon(OmnisonicIcons.check, color: scheme.primary)
        : const SizedBox(width: 24);

    return Row(
      children: [
        if (hasSynced)
          FilterChip(
            label: const Text('Follow'),
            selected: viewModel.follow,
            onSelected: viewModel.setFollow,
          ),
        if (hasSynced && offset != 0) ...[
          const SizedBox(width: OmnisonicSpacing.sm),
          Text(
            '${offset > 0 ? '+' : ''}$offset ms',
            style: OmnisonicTypography.metadata.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const Spacer(),
        IconButton(
          icon: const Icon(OmnisonicIcons.search),
          tooltip: 'Find other lyrics',
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => LyricsSearchSheet(track: track),
          ),
        ),
        MenuAnchor(
          reservedPadding: OmnisonicInsets.menuScreen,
          builder: (context, controller, child) => IconButton(
            icon: const Icon(OmnisonicIcons.moreVert),
            tooltip: 'Lyrics options',
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
          ),
          menuChildren: [
            for (final source in <LyricsSource?>[
              null,
              LyricsSource.lrclib,
              LyricsSource.lyricsOvh,
            ])
              MenuItemButton(
                leadingIcon: check(viewModel.preferredSource == source),
                onPressed: () => viewModel.setPreferredSource(source),
                child: Text('Source: ${_sourceLabel(source)}'),
              ),
            if (viewModel.override != null) ...[
              const Divider(height: 1),
              MenuItemButton(
                leadingIcon: const Icon(OmnisonicIcons.refresh),
                onPressed: viewModel.clearOverride,
                child: const Text('Back to automatic lyrics'),
              ),
            ],
            if (hasSynced) ...[
              const Divider(height: 1),
              MenuItemButton(
                leadingIcon: const Icon(OmnisonicIcons.remove),
                closeOnActivate: false,
                onPressed: () => viewModel.adjustOffset(-250),
                child: const Text('Show lines earlier (−250 ms)'),
              ),
              MenuItemButton(
                leadingIcon: const Icon(OmnisonicIcons.add),
                closeOnActivate: false,
                onPressed: () => viewModel.adjustOffset(250),
                child: const Text('Show lines later (+250 ms)'),
              ),
              if (offset != 0)
                MenuItemButton(
                  leadingIcon: const SizedBox(width: 24),
                  onPressed: viewModel.resetOffset,
                  child: Text('Reset timing ($offset ms)'),
                ),
            ],
          ],
        ),
      ],
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
