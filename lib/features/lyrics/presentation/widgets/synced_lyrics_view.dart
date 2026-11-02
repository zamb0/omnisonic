import 'package:flutter/material.dart';

import '../../../../core/utils/animation_utils.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/design_system/design_system.dart';
import 'package:flutter/rendering.dart';

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

  /// Following pauses while the user scrolls the lyrics themselves, and
  /// resumes this long after they stop — the auto-scroll used to fight
  /// every manual scroll.
  static const _resumeFollowAfter = Duration(seconds: 4);
  DateTime? _userScrolledAt;

  bool get _followPaused =>
      _userScrolledAt != null &&
      DateTime.now().difference(_userScrolledAt!) < _resumeFollowAfter;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
    if (index == _activeIndex) return;

    setState(() => _activeIndex = index);
    if (widget.follow && index >= 0 && !_followPaused) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(index));
    }
  }

  /// Brings line [index] to the middle of the view.
  ///
  /// The list is lazy, so after a seek the target line usually has not been
  /// built and `ensureVisible` had nothing to scroll to — following then
  /// stopped, silently. This first jumps to an estimate from the average
  /// line height, which builds the line, then centres it exactly.
  void _scrollTo(int index) {
    if (!mounted || !_controller.hasClients) return;
    final duration = AnimationUtils.adjustedDuration(
      context,
      const Duration(milliseconds: 250),
    );

    final target = _itemKeys[index]?.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: duration,
        curve: Curves.easeOut,
        alignment: 0.5,
      );
      return;
    }

    final position = _controller.position;
    final content = position.maxScrollExtent + position.viewportDimension;
    final average = content / widget.lines.length;
    final estimate = (index * average - position.viewportDimension / 2).clamp(
      0.0,
      position.maxScrollExtent,
    );
    _controller.jumpTo(estimate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final built = _itemKeys[index]?.currentContext;
      if (!mounted || built == null) return;
      Scrollable.ensureVisible(built, alignment: 0.5);
    });
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

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction != ScrollDirection.idle) {
          _userScrolledAt = DateTime.now();
        }
        return false;
      },
      child: ListView.builder(
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
              duration: AnimationUtils.adjustedDuration(
                context,
                AnimationManager.fastDuration,
              ),
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
      ),
    );
  }
}
