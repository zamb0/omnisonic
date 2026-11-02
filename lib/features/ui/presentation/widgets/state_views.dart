import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import 'empty_state.dart';
import 'media_card.dart';
import 'responsive_grid.dart';

/// The four states every screen in the app can be in.
///
/// Each screen used to invent its own vocabulary: some showed a bare
/// `CircularProgressIndicator` and some a shimmer grid; some rendered an
/// error inline with a Retry button, some only a SnackBar, and some nothing
/// at all; empty was an [EmptyState] on four screens and a bare
/// `Center(Text(...))` on three others. The same failure looked like a
/// different app depending on which tab you were on.
///
/// [AsyncStateSwitcher] makes the four branches explicit and ordered the
/// same way everywhere, and [ErrorStateView] takes a *required* `onRetry`,
/// so "an error the user can't do anything about" is not expressible.

/// What a loading placeholder should be shaped like.
///
/// Skeletons beat spinners because they reserve the space the content will
/// occupy, so nothing jumps when it arrives.
enum SkeletonKind {
  /// A grid of cards — library, favourites, offline.
  grid,

  /// A vertical list of tiles — track lists, queue, playlists.
  list,

  /// A horizontal row of cards — the home feed's sections.
  carousel,

  /// A large artwork block with title lines beside it — detail pages.
  detailHeader,
}

/// The loading branch: a skeleton in the shape of what is coming.
class LoadingStateView extends StatelessWidget {
  const LoadingStateView({
    super.key,
    this.kind = SkeletonKind.list,
    this.itemCount,
  });

  final SkeletonKind kind;

  /// How many placeholders to draw. Defaults to roughly a screenful.
  final int? itemCount;

  /// The same view as a sliver, for pages built from a [CustomScrollView].
  ///
  /// The list and grid variants become real slivers rather than being
  /// wrapped in an adapter: a ListView inside a SliverToBoxAdapter is a
  /// vertical viewport with unbounded height, which asserts at layout.
  static Widget sliver({
    SkeletonKind kind = SkeletonKind.list,
    int? itemCount,
  }) {
    switch (kind) {
      case SkeletonKind.list:
        return SliverList.builder(
          itemCount: itemCount ?? 8,
          itemBuilder: (context, index) => const SkeletonTile(),
        );
      case SkeletonKind.grid:
        return SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: OmnisonicSpacing.lg,
            vertical: OmnisonicSpacing.md,
          ),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.crossAxisExtent;
              final columns = MediaGridPreset.columnsFor(width);
              final cell = MediaGridPreset.cellWidth(width, columns);
              return SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: MediaGridPreset.spacing,
                  mainAxisSpacing: MediaGridPreset.spacing,
                  mainAxisExtent: MediaCard.extentFor(
                    context,
                    cell,
                    meta: true,
                  ),
                ),
                itemCount: itemCount ?? 8,
                itemBuilder: (context, index) => const SkeletonCard(),
              );
            },
          ),
        );
      case SkeletonKind.carousel:
      case SkeletonKind.detailHeader:
        // Both are fixed-height boxes, so an adapter is the right wrapper.
        return SliverToBoxAdapter(
          child: LoadingStateView(kind: kind, itemCount: itemCount),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case SkeletonKind.grid:
        return _SkeletonGrid(itemCount: itemCount ?? 8);
      case SkeletonKind.list:
        return _SkeletonList(itemCount: itemCount ?? 8);
      case SkeletonKind.carousel:
        return _SkeletonCarousel(itemCount: itemCount ?? 6);
      case SkeletonKind.detailHeader:
        return const _SkeletonDetailHeader();
    }
  }
}

/// The error branch. [onRetry] is required on purpose.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Something went wrong',
  });

  final String message;
  final VoidCallback onRetry;
  final String title;

  static Widget sliver({
    required String message,
    required VoidCallback onRetry,
    String title = 'Something went wrong',
  }) => SliverFillRemaining(
    hasScrollBody: false,
    child: ErrorStateView(message: message, onRetry: onRetry, title: title),
  );

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: OmnisonicIcons.errorOutline,
      title: title,
      subtitle: message,
      action: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(OmnisonicIcons.refresh),
        label: const Text('Try again'),
      ),
    );
  }
}

/// Renders exactly one of loading / error / empty / content, in that order.
///
/// The order matters and is the same on every screen: a stale list must not
/// be shown while a refresh is failing, and "empty" must not be claimed
/// before the data has had a chance to arrive.
class AsyncStateSwitcher extends StatelessWidget {
  const AsyncStateSwitcher({
    super.key,
    required this.isLoading,
    required this.isEmpty,
    required this.builder,
    required this.onRetry,
    this.error,
    this.skeleton = SkeletonKind.list,
    this.skeletonItemCount,
    this.empty,
  });

  final bool isLoading;
  final String? error;
  final bool isEmpty;

  /// The content branch.
  final WidgetBuilder builder;

  /// What Retry does. Required for the same reason as on [ErrorStateView].
  final VoidCallback onRetry;

  final SkeletonKind skeleton;
  final int? skeletonItemCount;

  /// The empty branch. Screens differ here — the copy and the call to action
  /// are specific to what is missing — so there is no default beyond a
  /// neutral placeholder.
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return LoadingStateView(kind: skeleton, itemCount: skeletonItemCount);
    }

    final message = error;
    if (message != null) {
      return ErrorStateView(message: message, onRetry: onRetry);
    }

    if (isEmpty) {
      return empty ??
          const EmptyState(
            icon: OmnisonicIcons.musicNoteOutline,
            title: 'Nothing here yet',
          );
    }

    return builder(context);
  }
}

// ---------------------------------------------------------------------------
// Skeleton primitives
// ---------------------------------------------------------------------------

/// A shimmering placeholder block.
///
/// Holds still rather than sweeping when the platform asks for reduced
/// motion: a looping animation is exactly what that setting is about.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: AnimationManager.loadingDuration,
    vsync: this,
  );
  late final Animation<double> _sweep = Tween<double>(begin: -1, end: 2)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: AnimationManager.loadingCurve,
        ),
      );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      // A zero-duration repeat() spins forever with nothing to show for it;
      // hold the sweep at a static midpoint instead.
      _controller.value = 0.5;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCircle = widget.shape == BoxShape.circle;

    // Tinted from onSurface rather than the surfaceContainer roles. In this
    // app's dark scheme surfaceContainerHighest is cardDark, which is within
    // a shade of the scaffold background — a skeleton painted with it is
    // invisible in the mode most of the app runs in.
    final base = scheme.onSurface.withValues(alpha: 0.08);
    final highlight = scheme.onSurface.withValues(alpha: 0.16);

    return AnimatedBuilder(
      animation: _sweep,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          shape: widget.shape,
          borderRadius: isCircle
              ? null
              : widget.borderRadius ??
                    BorderRadius.circular(OmnisonicRadius.sm),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [base, highlight, base],
            stops: [
              _sweep.value - 0.3,
              _sweep.value,
              _sweep.value + 0.3,
            ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
          ),
        ),
      ),
    );
  }
}

/// A placeholder line of text.
class SkeletonText extends StatelessWidget {
  const SkeletonText({super.key, this.width = 120, this.height = 12});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SkeletonBox(
    width: width,
    height: height,
    borderRadius: BorderRadius.circular(OmnisonicRadius.xs),
  );
}

/// Artwork square over a title and a subtitle — the shape of a card.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.width});

  /// Fixed width, for carousels. Null fills the grid cell.
  final double? width;

  @override
  Widget build(BuildContext context) {
    Widget card(double w) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SkeletonBox(
          width: w,
          height: w,
          borderRadius: BorderRadius.circular(OmnisonicRadius.art),
        ),
        const SizedBox(height: OmnisonicSpacing.sm),
        SkeletonText(width: w * 0.7),
        const SizedBox(height: OmnisonicSpacing.xs),
        SkeletonText(width: w * 0.45, height: 10),
      ],
    );

    final fixed = width;
    if (fixed != null) return SizedBox(width: fixed, child: card(fixed));
    return LayoutBuilder(
      builder: (context, constraints) => card(constraints.maxWidth),
    );
  }
}

/// Leading square, two lines, trailing stub — the shape of a track row.
class SkeletonTile extends StatelessWidget {
  const SkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OmnisonicSpacing.md,
        vertical: OmnisonicSpacing.sm,
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 48, height: 48),
          const SizedBox(width: OmnisonicSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: 180, height: 14),
                SizedBox(height: OmnisonicSpacing.xs),
                SkeletonText(width: 110, height: 11),
              ],
            ),
          ),
          const SizedBox(width: OmnisonicSpacing.md),
          const SkeletonText(width: 34, height: 11),
        ],
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) => ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    itemCount: itemCount,
    itemBuilder: (context, index) => const SkeletonTile(),
  );
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    // The real grid's own geometry, so the content does not shift when it
    // replaces this.
    return ResponsiveGridView.media(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: OmnisonicSpacing.lg,
        vertical: OmnisonicSpacing.md,
      ),
      meta: true,
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonCard(),
    );
  }
}

class _SkeletonCarousel extends StatelessWidget {
  const _SkeletonCarousel({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 244,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: OmnisonicSpacing.md),
        itemCount: itemCount,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(right: 14),
          child: SkeletonCard(width: 160),
        ),
      ),
    );
  }
}

class _SkeletonDetailHeader extends StatelessWidget {
  const _SkeletonDetailHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(OmnisonicSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(
                width: 150,
                height: 150,
                borderRadius: BorderRadius.circular(OmnisonicRadius.art),
              ),
              const SizedBox(width: OmnisonicSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(width: 220, height: 26),
                    SizedBox(height: OmnisonicSpacing.sm),
                    SkeletonText(width: 140, height: 14),
                    SizedBox(height: OmnisonicSpacing.xs),
                    SkeletonText(width: 90, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: OmnisonicSpacing.lg),
          for (var i = 0; i < 5; i++) const SkeletonTile(),
        ],
      ),
    );
  }
}
