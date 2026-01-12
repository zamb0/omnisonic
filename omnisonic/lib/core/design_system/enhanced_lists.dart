import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'spacing.dart';
import 'animation_manager.dart';
import 'micro_interactions.dart';

/// Enhanced animated list with smooth transitions and reordering
/// Implements Requirements: 3.4, 6.5
class EnhancedAnimatedList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index, Animation<double> animation) itemBuilder;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final void Function(T item)? onItemTap;
  final void Function(T item)? onItemLongPress;
  final void Function(T item, int index)? onItemDismissed;
  final bool enableReordering;
  final bool enableDismiss;
  final bool enableStaggeredAnimation;
  final Duration animationDuration;
  final Curve animationCurve;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final ScrollController? controller;

  const EnhancedAnimatedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onReorder,
    this.onItemTap,
    this.onItemLongPress,
    this.onItemDismissed,
    this.enableReordering = false,
    this.enableDismiss = false,
    this.enableStaggeredAnimation = true,
    this.animationDuration = AnimationManager.normalDuration,
    this.animationCurve = AnimationManager.standardCurve,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.controller,
  });

  @override
  State<EnhancedAnimatedList<T>> createState() => _EnhancedAnimatedListState<T>();
}

class _EnhancedAnimatedListState<T> extends State<EnhancedAnimatedList<T>>
    with TickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<T> _items;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
    _initializeAnimations();
  }

  @override
  void didUpdateWidget(EnhancedAnimatedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _updateItems(oldWidget.items, widget.items);
    }
  }

  @override
  void dispose() {
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeAnimations() {
    _itemControllers = [];
    _itemAnimations = [];

    for (int i = 0; i < _items.length; i++) {
      final controller = AnimationManager().createController(
        duration: widget.animationDuration,
        vsync: this,
        debugLabel: 'EnhancedAnimatedList_Item_$i',
      );

      final animation = AnimationUtilities.createFadeAnimation(
        controller: controller,
        curve: widget.animationCurve,
      );

      _itemControllers.add(controller);
      _itemAnimations.add(animation);

      if (widget.enableStaggeredAnimation) {
        Future.delayed(Duration(milliseconds: i * 50), () {
          if (mounted) {
            controller.forward();
          }
        });
      } else {
        controller.forward();
      }
    }
  }

  void _updateItems(List<T> oldItems, List<T> newItems) {
    // Handle item additions
    for (int i = 0; i < newItems.length; i++) {
      if (i >= oldItems.length || newItems[i] != oldItems[i]) {
        _insertItem(i, newItems[i]);
      }
    }

    // Handle item removals
    for (int i = oldItems.length - 1; i >= 0; i--) {
      if (i >= newItems.length || !newItems.contains(oldItems[i])) {
        _removeItem(i, oldItems[i]);
      }
    }

    _items = List.from(newItems);
  }

  void _insertItem(int index, T item) {
    _items.insert(index, item);
    _listKey.currentState?.insertItem(index, duration: widget.animationDuration);

    final controller = AnimationManager().createController(
      duration: widget.animationDuration,
      vsync: this,
      debugLabel: 'EnhancedAnimatedList_Item_$index',
    );

    final animation = AnimationUtilities.createFadeAnimation(
      controller: controller,
      curve: widget.animationCurve,
    );

    _itemControllers.insert(index, controller);
    _itemAnimations.insert(index, animation);

    controller.forward();
  }

  void _removeItem(int index, T item) {
    final controller = _itemControllers.removeAt(index);
    _itemAnimations.removeAt(index);

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildRemovedItem(context, item, index, animation),
      duration: widget.animationDuration,
    );

    controller.dispose();
    _items.removeAt(index);
  }

  Widget _buildRemovedItem(BuildContext context, T item, int index, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-1.0, 0.0),
      ).animate(CurvedAnimation(
        parent: animation,
        curve: AnimationManager.slideOutCurve,
      )),
      child: FadeTransition(
        opacity: animation,
        child: widget.itemBuilder(context, item, index, animation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.enableReordering) {
      return _buildReorderableList();
    } else {
      return _buildAnimatedList();
    }
  }

  Widget _buildAnimatedList() {
    return AnimatedList(
      key: _listKey,
      initialItemCount: _items.length,
      padding: widget.padding,
      physics: widget.physics ?? const BouncingScrollPhysics(),
      shrinkWrap: widget.shrinkWrap,
      controller: widget.controller,
      itemBuilder: (context, index, animation) {
        if (index >= _items.length) return const SizedBox.shrink();

        final item = _items[index];
        Widget listItem = widget.itemBuilder(context, item, index, animation);

        if (widget.enableDismiss) {
          listItem = _buildDismissibleItem(listItem, item, index);
        }

        return _buildInteractiveItem(listItem, item, index, animation);
      },
    );
  }

  Widget _buildReorderableList() {
    return ReorderableListView.builder(
      padding: widget.padding as EdgeInsets?,
      physics: widget.physics ?? const BouncingScrollPhysics(),
      shrinkWrap: widget.shrinkWrap,
      scrollController: widget.controller,
      itemCount: _items.length,
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        
        setState(() {
          final item = _items.removeAt(oldIndex);
          _items.insert(newIndex, item);
          
          final controller = _itemControllers.removeAt(oldIndex);
          _itemControllers.insert(newIndex, controller);
          
          final animation = _itemAnimations.removeAt(oldIndex);
          _itemAnimations.insert(newIndex, animation);
        });

        widget.onReorder?.call(oldIndex, newIndex);
        HapticFeedback.mediumImpact();
      },
      itemBuilder: (context, index) {
        if (index >= _items.length) return const SizedBox.shrink();

        final item = _items[index];
        final animation = _itemAnimations[index];
        
        Widget listItem = widget.itemBuilder(context, item, index, animation);

        if (widget.enableDismiss) {
          listItem = _buildDismissibleItem(listItem, item, index);
        }

        return _buildInteractiveItem(listItem, item, index, animation, key: ValueKey(item));
      },
    );
  }

  Widget _buildDismissibleItem(Widget child, T item, int index) {
    return Dismissible(
      key: ValueKey(item),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: OmnisonicInsets.horizontalLg,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(OmnisonicRadius.sm),
        ),
        child: Icon(
          Icons.delete,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      onDismissed: (direction) {
        widget.onItemDismissed?.call(item, index);
        HapticFeedback.mediumImpact();
      },
      child: child,
    );
  }

  Widget _buildInteractiveItem(Widget child, T item, int index, Animation<double> animation, {Key? key}) {
    Widget interactiveItem = MicroInteractions.interactiveListItem(
      onTap: () => widget.onItemTap?.call(item),
      onLongPress: () => widget.onItemLongPress?.call(item),
      enableSlideAnimation: widget.enableStaggeredAnimation,
      enableFadeAnimation: widget.enableStaggeredAnimation,
      animationDuration: widget.animationDuration,
      animationCurve: widget.animationCurve,
      index: index,
      child: child,
    );
    
    if (key != null) {
      return KeyedSubtree(key: key, child: interactiveItem);
    }
    
    return interactiveItem;
  }
}

/// Enhanced list view with smooth scrolling and momentum effects
class EnhancedListView extends StatefulWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool enableSmoothScrolling;
  final bool enableMomentumEffects;
  final bool enableOverscrollGlow;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final Axis scrollDirection;

  const EnhancedListView({
    super.key,
    required this.children,
    this.controller,
    this.padding,
    this.enableSmoothScrolling = true,
    this.enableMomentumEffects = true,
    this.enableOverscrollGlow = false,
    this.physics,
    this.shrinkWrap = false,
    this.scrollDirection = Axis.vertical,
  });

  const EnhancedListView.builder({
    super.key,
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
    this.controller,
    this.padding,
    this.enableSmoothScrolling = true,
    this.enableMomentumEffects = true,
    this.enableOverscrollGlow = false,
    this.physics,
    this.shrinkWrap = false,
    this.scrollDirection = Axis.vertical,
  }) : children = const [];

  @override
  State<EnhancedListView> createState() => _EnhancedListViewState();
}

class _EnhancedListViewState extends State<EnhancedListView> {
  late ScrollController _controller;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ScrollController();
    
    if (widget.enableSmoothScrolling) {
      _controller.addListener(_handleScrolling);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleScrolling() {
    if (_controller.position.isScrollingNotifier.value != _isScrolling) {
      setState(() {
        _isScrolling = _controller.position.isScrollingNotifier.value;
      });
    }
  }

  ScrollPhysics _getScrollPhysics() {
    if (widget.physics != null) return widget.physics!;

    if (widget.enableMomentumEffects) {
      return const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
    } else {
      return const ClampingScrollPhysics();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget listView = ListView(
      controller: _controller,
      padding: widget.padding,
      physics: _getScrollPhysics(),
      shrinkWrap: widget.shrinkWrap,
      scrollDirection: widget.scrollDirection,
      children: widget.children,
    );

    if (!widget.enableOverscrollGlow) {
      listView = NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (notification) {
          notification.disallowIndicator();
          return true;
        },
        child: listView,
      );
    }

    return listView;
  }
}

/// Enhanced grid view with responsive columns and smooth animations
class EnhancedGridView extends StatefulWidget {
  final List<Widget> children;
  final int? crossAxisCount;
  final double? maxCrossAxisExtent;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool enableStaggeredAnimation;
  final Duration animationDuration;

  const EnhancedGridView({
    super.key,
    required this.children,
    this.crossAxisCount,
    this.maxCrossAxisExtent,
    this.mainAxisSpacing = OmnisonicSpacing.md,
    this.crossAxisSpacing = OmnisonicSpacing.md,
    this.childAspectRatio = 1.0,
    this.padding,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
    this.enableStaggeredAnimation = true,
    this.animationDuration = AnimationManager.normalDuration,
  }) : assert(crossAxisCount != null || maxCrossAxisExtent != null);

  @override
  State<EnhancedGridView> createState() => _EnhancedGridViewState();
}

class _EnhancedGridViewState extends State<EnhancedGridView>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeAnimations() {
    _controllers = [];
    _animations = [];

    for (int i = 0; i < widget.children.length; i++) {
      final controller = AnimationManager().createController(
        duration: widget.animationDuration,
        vsync: this,
        debugLabel: 'EnhancedGridView_Item_$i',
      );

      final animation = AnimationUtilities.createFadeAnimation(
        controller: controller,
        curve: AnimationManager.standardCurve,
      );

      _controllers.add(controller);
      _animations.add(animation);

      if (widget.enableStaggeredAnimation) {
        Future.delayed(Duration(milliseconds: i * 50), () {
          if (mounted) {
            controller.forward();
          }
        });
      } else {
        controller.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: widget.controller,
      padding: widget.padding,
      physics: widget.physics ?? const BouncingScrollPhysics(),
      shrinkWrap: widget.shrinkWrap,
      gridDelegate: widget.crossAxisCount != null
          ? SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.crossAxisCount!,
              mainAxisSpacing: widget.mainAxisSpacing,
              crossAxisSpacing: widget.crossAxisSpacing,
              childAspectRatio: widget.childAspectRatio,
            )
          : SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: widget.maxCrossAxisExtent!,
              mainAxisSpacing: widget.mainAxisSpacing,
              crossAxisSpacing: widget.crossAxisSpacing,
              childAspectRatio: widget.childAspectRatio,
            ),
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        if (widget.enableStaggeredAnimation && index < _animations.length) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return FadeTransition(
                opacity: _animations[index],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.3),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _controllers[index],
                    curve: AnimationManager.standardCurve,
                  )),
                  child: widget.children[index],
                ),
              );
            },
          );
        }
        return widget.children[index];
      },
    );
  }
}

/// Enhanced sliver list for use in custom scroll views
class EnhancedSliverList extends StatefulWidget {
  final List<Widget> children;
  final bool enableStaggeredAnimation;
  final Duration animationDuration;
  final Curve animationCurve;

  const EnhancedSliverList({
    super.key,
    required this.children,
    this.enableStaggeredAnimation = true,
    this.animationDuration = AnimationManager.normalDuration,
    this.animationCurve = AnimationManager.standardCurve,
  });

  @override
  State<EnhancedSliverList> createState() => _EnhancedSliverListState();
}

class _EnhancedSliverListState extends State<EnhancedSliverList>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeAnimations() {
    _controllers = [];
    _animations = [];

    for (int i = 0; i < widget.children.length; i++) {
      final controller = AnimationManager().createController(
        duration: widget.animationDuration,
        vsync: this,
        debugLabel: 'EnhancedSliverList_Item_$i',
      );

      final animation = AnimationUtilities.createFadeAnimation(
        controller: controller,
        curve: widget.animationCurve,
      );

      _controllers.add(controller);
      _animations.add(animation);

      if (widget.enableStaggeredAnimation) {
        Future.delayed(Duration(milliseconds: i * 30), () {
          if (mounted) {
            controller.forward();
          }
        });
      } else {
        controller.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= widget.children.length) return null;

          if (widget.enableStaggeredAnimation && index < _animations.length) {
            return AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                return FadeTransition(
                  opacity: _animations[index],
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.3, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _controllers[index],
                      curve: widget.animationCurve,
                    )),
                    child: widget.children[index],
                  ),
                );
              },
            );
          }
          return widget.children[index];
        },
        childCount: widget.children.length,
      ),
    );
  }
}

/// Utility class for creating smooth scroll animations
class SmoothScrollAnimations {
  /// Animate scroll to a specific position
  static Future<void> animateToPosition({
    required ScrollController controller,
    required double position,
    Duration duration = AnimationManager.normalDuration,
    Curve curve = AnimationManager.standardCurve,
  }) async {
    await controller.animateTo(
      position,
      duration: duration,
      curve: curve,
    );
  }

  /// Animate scroll to a specific item index
  static Future<void> animateToIndex({
    required ScrollController controller,
    required int index,
    required double itemExtent,
    Duration duration = AnimationManager.normalDuration,
    Curve curve = AnimationManager.standardCurve,
  }) async {
    final position = index * itemExtent;
    await animateToPosition(
      controller: controller,
      position: position,
      duration: duration,
      curve: curve,
    );
  }

  /// Create a smooth scroll physics with custom bounce
  static ScrollPhysics createSmoothPhysics({
    double bounciness = 0.8,
    bool enableOverscroll = true,
  }) {
    if (enableOverscroll) {
      return const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
    } else {
      return const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      );
    }
  }
}