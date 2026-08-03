import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/services/cover_palette_service.dart';
import '../../../music/presentation/viewmodels/music_library_view_model.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';

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

class _ShellArtTintState extends State<ShellArtTint> {
  Color? _tint;
  String? _tintSourceUrl;

  void _updateTint(String? coverArtUrl) {
    if (coverArtUrl == _tintSourceUrl) return;
    _tintSourceUrl = coverArtUrl;
    CoverPaletteService.instance.extractColor(coverArtUrl).then((color) {
      if (mounted && _tintSourceUrl == coverArtUrl) {
        setState(() => _tint = color);
      }
    });
  }

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
    if (tintSource != _tintSourceUrl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateTint(tintSource);
      });
    }

    return RepaintBoundary(
      child: AnimatedTintSwitcher(seed: _tint, child: widget.child),
    );
  }
}

/// Cross-fades between tints when the source art changes, so a track change
/// doesn't snap the whole window to a new colour.
class AnimatedTintSwitcher extends ImplicitlyAnimatedWidget {
  const AnimatedTintSwitcher({super.key, this.seed, this.child})
    : super(duration: const Duration(milliseconds: 600));

  final Color? seed;
  final Widget? child;

  @override
  AnimatedWidgetBaseState<AnimatedTintSwitcher> createState() =>
      _AnimatedTintSwitcherState();
}

class _AnimatedTintSwitcherState
    extends AnimatedWidgetBaseState<AnimatedTintSwitcher> {
  ColorTween? _seed;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _seed =
        visitor(
              _seed,
              widget.seed,
              (dynamic value) => ColorTween(begin: value as Color?),
            )
            as ColorTween?;
  }

  @override
  Widget build(BuildContext context) {
    return ArtTintBackground(
      seed: _seed?.evaluate(animation),
      child: widget.child,
    );
  }
}
