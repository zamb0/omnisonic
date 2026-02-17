import 'package:flutter/material.dart';

import '../../../../core/design_system/spacing.dart';
import '../../../../core/entities/entities.dart';

class SyncedLyricsView extends StatefulWidget {
  const SyncedLyricsView({
    super.key,
    required this.lines,
    required this.position,
    required this.follow,
    required this.offsetMs,
  });

  final List<LyricLine> lines;
  final Duration position;
  final bool follow;
  final int offsetMs;

  @override
  State<SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends State<SyncedLyricsView> {
  final ScrollController _controller = ScrollController();
  int _activeIndex = -1;

  @override
  void didUpdateWidget(SyncedLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateActiveIndex();
  }

  @override
  void initState() {
    super.initState();
    _updateActiveIndex();
  }

  int _findActiveIndex(int timeMs) {
    if (widget.lines.isEmpty) return -1;

    for (var i = 0; i < widget.lines.length; i += 1) {
      if (timeMs < widget.lines[i].time.inMilliseconds) {
        return i == 0 ? 0 : i - 1;
      }
    }

    return widget.lines.length - 1;
  }

  void _updateActiveIndex() {
    final timeMs = widget.position.inMilliseconds + widget.offsetMs;
    final index = _findActiveIndex(timeMs);

    if (index != _activeIndex) {
      setState(() {
        _activeIndex = index;
      });

      if (widget.follow && index >= 0 && _controller.hasClients) {
        final textStyle = Theme.of(context).textTheme.bodyLarge;
        final lineHeight = (textStyle?.fontSize ?? 16) * 2.0;
        final targetOffset = (index * lineHeight) - (lineHeight * 2);
        _controller.animateTo(
          targetOffset.clamp(0, _controller.position.maxScrollExtent),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;
    final lineHeight = (textStyle?.fontSize ?? 16) * 2.0;

    if (widget.lines.isEmpty) {
      return Center(
        child: Text(
          'No synced lines found',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.builder(
      controller: _controller,
      itemExtent: lineHeight,
      itemCount: widget.lines.length,
      padding: const EdgeInsets.symmetric(horizontal: OmnisonicSpacing.md),
      itemBuilder: (context, index) {
        final line = widget.lines[index];
        final isActive = index == _activeIndex;
        final colorScheme = Theme.of(context).colorScheme;

        return Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: (textStyle ?? const TextStyle()).copyWith(
              color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              height: 1.2,
            ),
            child: Text(
              line.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
