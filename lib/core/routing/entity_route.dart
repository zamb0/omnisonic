import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../design_system/design_system.dart';
import '../../features/music/presentation/viewmodels/music_library_view_model.dart';
import '../../features/ui/presentation/widgets/widgets.dart';
import 'app_router.dart';

/// Renders a detail page for an entity that may or may not have travelled
/// with the navigation.
///
/// Detail routes normally receive the entity through `state.extra`, which is
/// free and avoids a round trip. But `extra` is null for anything that
/// doesn't come from an in-app tap — a deep link, a notification, a restored
/// window, a hot restart on the current route. Casting it unconditionally
/// crashed the app on all of those.
///
/// So the entity is optional and the id is authoritative: with an entity,
/// render immediately; without one, look it up in the already-loaded
/// collection and render as soon as it appears. It genuinely isn't there
/// only once the collection has finished loading without it.
class EntityRoute<T> extends StatelessWidget {
  const EntityRoute({
    super.key,
    required this.entity,
    required this.entityId,
    required this.lookup,
    required this.builder,
    required this.missingTitle,
    required this.missingSubtitle,
  });

  /// The entity handed over by the tap that navigated here, if any.
  final T? entity;

  /// The unique ID (`{serverId}_{subsonicId}`) this route points at.
  final String entityId;

  /// Finds the entity in the loaded collection.
  final T? Function(MusicLibraryViewModel library, String id) lookup;

  final Widget Function(T entity) builder;

  final String missingTitle;
  final String missingSubtitle;

  @override
  Widget build(BuildContext context) {
    final provided = entity;
    if (provided != null) return builder(provided);

    final library = context.watch<MusicLibraryViewModel>();
    final resolved = entityId.isEmpty ? null : lookup(library, entityId);
    if (resolved != null) return builder(resolved);

    // No collection yet means the app is still starting up, not that the
    // entity is missing.
    if (library.collection == null || library.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(leading: const _BackToLibraryButton()),
      body: EmptyState(
        icon: OmnisonicIcons.searchOff,
        title: missingTitle,
        subtitle: missingSubtitle,
        action: FilledButton(
          onPressed: () => context.go(AppRouter.library),
          child: const Text('Go to Library'),
        ),
      ),
    );
  }
}

/// Shown for a URL that matches no route at all.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(leading: const _BackToLibraryButton()),
      body: EmptyState(
        icon: OmnisonicIcons.exploreOff,
        title: 'Page not found',
        subtitle: 'Nothing lives at $location.',
        action: FilledButton(
          onPressed: () => context.go(AppRouter.home),
          child: const Text('Go Home'),
        ),
      ),
    );
  }
}

class _BackToLibraryButton extends StatelessWidget {
  const _BackToLibraryButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(OmnisonicIcons.arrowBack),
      tooltip: 'Back',
      onPressed: () =>
          context.canPop() ? context.pop() : context.go(AppRouter.library),
    );
  }
}
