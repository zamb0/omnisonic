import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/utils/animation_utils.dart';
import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';
import 'art_tint.dart';

/// [ArtTintBackground] wired to whatever art is most relevant right now: the
/// playing track first, then the most recently played album.
///
/// Kept out of the design system so `core/design_system` stays free of
/// feature dependencies.
class ShellArtTint extends StatefulWidget {
  const ShellArtTint({super.key, this.child});

  final Widget? child;

  @override
  State<ShellArtTint> createState() => _ShellArtTintState();
}

class _ShellArtTintState extends State<ShellArtTint> with ArtTintMixin {
  @override
  Widget build(BuildContext context) {
    // Selecting only the cover art URLs, not the whole view models: this
    // widget wraps every pane in the window and repaints three gradients, and
    // PlaybackViewModel notifies several times a second while playing.
    final playingArt = context.select<PlaybackViewModel, String?>(
      (playback) => playback.currentTrack?.coverArtUrl,
    );
    final libraryArt = context.select<MusicLibraryViewModel, String?>((
      library,
    ) {
      if (library.recentlyPlayedAlbums.isNotEmpty) {
        return library.recentlyPlayedAlbums.first.coverArtUrl;
      }
      if (library.recentlyAddedAlbums.isNotEmpty) {
        return library.recentlyAddedAlbums.first.coverArtUrl;
      }
      return null;
    });

    // Palette extraction is a side effect, so it waits until after this frame
    // rather than running inside build.
    final tintSource = playingArt ?? libraryArt;
    if (tintSource != artTintUrl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) updateArtTint(tintSource);
      });
    }

    return RepaintBoundary(
      child: AnimatedTintSwitcher(
        seed: artTint,
        // A 600ms colour wash across the whole window is motion too.
        duration: AnimationUtils.adjustedDuration(
          context,
          AnimatedTintSwitcher.defaultDuration,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Cross-fades between tints when the source art changes, so a track change
/// doesn't snap the whole window to a new colour.
class AnimatedTintSwitcher extends ImplicitlyAnimatedWidget {
  const AnimatedTintSwitcher({
    super.key,
    this.seed,
    this.child,
    super.duration = defaultDuration,
  });

  static const Duration defaultDuration = AnimationManager.tintDuration;

  final Color? seed;
  final Widget? child;

  @override
  AnimatedWidgetBaseState<AnimatedTintSwitcher> createState() =>
      _AnimatedTintSwitcherState();
}

class _AnimatedTintSwitcherState
    extends AnimatedWidgetBaseState<AnimatedTintSwitcher> {
  ColorTween? _cover;
  Tween<double>? _fallback;

  /// The last cover colour seen, kept while fading to the fallback mesh so
  /// the washes have something to fade out.
  Color? _lastCover;

  /// Tweens the cover colour and, separately, how much of the Aurora
  /// fallback shows. A single colour tween cannot express "no cover": going
  /// to or from the mesh used to cut on the first or last frame.
  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    final cover = widget.seed ?? _lastCover;
    _cover =
        visitor(
              _cover,
              cover,
              (dynamic value) => ColorTween(begin: value as Color?),
            )
            as ColorTween?;
    _fallback =
        visitor(
              _fallback,
              widget.seed == null ? 1.0 : 0.0,
              (dynamic value) => Tween<double>(begin: value as double),
            )
            as Tween<double>?;
    _lastCover = cover;
  }

  @override
  Widget build(BuildContext context) {
    return ArtTintBackground(
      seed: _cover?.evaluate(animation),
      fallbackOpacity: _fallback?.evaluate(animation),
      child: widget.child,
    );
  }
}
