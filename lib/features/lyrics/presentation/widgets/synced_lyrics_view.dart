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
  final Map<int, GlobalKey> _itemKeys = {};
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

  GlobalKey _getKeyForIndex(int index) {
    if (!_itemKeys.containsKey(index)) {
      _itemKeys[index] = GlobalKey();
    }
    return _itemKeys[index]!;
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          final key = _getKeyForIndex(index);
          final context = key.currentContext;

          if (context != null) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: 0.5, // Center the item in the viewport
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;

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
      itemCount: widget.lines.length,
      padding: const EdgeInsets.symmetric(
        horizontal: OmnisonicSpacing.md,
        vertical: OmnisonicSpacing.lg,
      ),
      itemBuilder: (context, index) {
        final line = widget.lines[index];
        final isActive = index == _activeIndex;
        final colorScheme = Theme.of(context).colorScheme;

        return Padding(
          key: _getKeyForIndex(index),
          padding: const EdgeInsets.symmetric(vertical: OmnisonicSpacing.sm),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: (textStyle ?? const TextStyle()).copyWith(
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              height: 1.4,
            ),
            child: Text(line.text, textAlign: TextAlign.center),
          ),
        );
      },
    );
  }
}
