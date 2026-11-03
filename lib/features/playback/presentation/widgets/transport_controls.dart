import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/repositories/playback_repository.dart' as repo;
import '../../../../core/utils/haptics.dart';
import '../viewmodels/playback_view_model.dart';

/// How shuffle and repeat states look and read.
///
/// Each state has its own icon *shape* — repeat-off and repeat-all used to
/// share one icon and differ only by colour — and its own label, which is
/// both the tooltip and the screen-reader name.
class PlaybackModeVisuals {
  const PlaybackModeVisuals._();

  static IconData shuffleIcon(bool on) =>
      on ? OmnisonicIcons.shuffleOn : OmnisonicIcons.shuffle;

  static String shuffleLabel(bool on) => on ? 'Shuffle on' : 'Shuffle off';

  static IconData repeatIcon(repo.RepeatMode mode) => switch (mode) {
    repo.RepeatMode.none => OmnisonicIcons.repeat,
    repo.RepeatMode.all => OmnisonicIcons.repeatOn,
    repo.RepeatMode.one => OmnisonicIcons.repeatOneOn,
  };

  static String repeatLabel(repo.RepeatMode mode) => switch (mode) {
    repo.RepeatMode.none => 'Repeat off',
    repo.RepeatMode.all => 'Repeat all',
    repo.RepeatMode.one => 'Repeat one',
  };
}

/// An icon button for the transport: always a tooltip, always at least the
/// minimum touch target, Material's 0.38 opacity when disabled, and toggle
/// state announced when [toggled] is set.
class TransportButton extends StatelessWidget {
  const TransportButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = 24,
    this.toggled,
    this.activeColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double size;

  /// On/off controls (shuffle, repeat, favourite) set this so a screen
  /// reader announces the state, which a tooltip alone does not.
  final bool? toggled;

  /// Icon colour while [toggled] is true. Defaults to the primary colour.
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = toggled ?? false;
    final color = on ? (activeColor ?? scheme.primary) : scheme.onSurface;
    final button = IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: size),
      iconSize: size,
      tooltip: label,
      color: toggled == false ? scheme.onSurfaceVariant : color,
      disabledColor: scheme.onSurface.withValues(alpha: 0.38),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: OmnisonicTouchTargets.minimum,
        minHeight: OmnisonicTouchTargets.minimum,
      ),
    );
    if (toggled == null) return button;
    return Semantics(toggled: toggled, child: button);
  }
}

/// Shuffle on/off.
class ShuffleModeButton extends StatelessWidget {
  const ShuffleModeButton({super.key, required this.playback, this.size = 20});

  final PlaybackViewModel playback;
  final double size;

  @override
  Widget build(BuildContext context) {
    final on = playback.shuffleEnabled;
    return TransportButton(
      icon: PlaybackModeVisuals.shuffleIcon(on),
      label: PlaybackModeVisuals.shuffleLabel(on),
      size: size,
      toggled: on,
      onPressed: playback.toggleShuffleMode,
    );
  }
}

/// Repeat off → all → one.
class RepeatModeButton extends StatelessWidget {
  const RepeatModeButton({super.key, required this.playback, this.size = 20});

  final PlaybackViewModel playback;
  final double size;

  @override
  Widget build(BuildContext context) {
    final mode = playback.repeatMode;
    return TransportButton(
      icon: PlaybackModeVisuals.repeatIcon(mode),
      label: PlaybackModeVisuals.repeatLabel(mode),
      size: size,
      toggled: mode != repo.RepeatMode.none,
      onPressed: playback.toggleRepeatMode,
    );
  }
}

/// Previous track.
class SkipPreviousButton extends StatelessWidget {
  const SkipPreviousButton({super.key, required this.playback, this.size = 24});

  final PlaybackViewModel playback;
  final double size;

  @override
  Widget build(BuildContext context) => TransportButton(
    icon: OmnisonicIcons.skipPrevious,
    label: 'Previous track',
    size: size,
    onPressed: playback.hasPrevious ? playback.skipToPrevious : null,
  );
}

/// Next track.
class SkipNextButton extends StatelessWidget {
  const SkipNextButton({super.key, required this.playback, this.size = 24});

  final PlaybackViewModel playback;
  final double size;

  @override
  Widget build(BuildContext context) => TransportButton(
    icon: OmnisonicIcons.skipNext,
    label: 'Next track',
    size: size,
    onPressed: playback.hasNext ? playback.skipToNext : null,
  );
}

/// The round play/pause button: solid ink, the primary action wherever it
/// appears. [prominent] is the full player's large one.
///
/// The full player's used to be accent-coloured and the bar's ink, so the
/// same control changed colour as the player opened.
class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({
    super.key,
    required this.playback,
    this.prominent = false,
  });

  final PlaybackViewModel playback;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final playing = playback.isPlaying;
    final diameter = prominent ? 72.0 : OmnisonicTouchTargets.iconButton;
    final surfaces = OmnisonicSurfaces.of(context);

    return SizedBox.square(
      dimension: diameter,
      child: IconButton(
        onPressed: () {
          Haptics.impact();
          playback.togglePlayPause();
        },
        tooltip: playing ? 'Pause' : 'Play',
        icon: Icon(playing ? OmnisonicIcons.pause : OmnisonicIcons.playArrow),
        iconSize: prominent ? OmnisonicIconSizes.lg : OmnisonicIconSizes.md,
        style: IconButton.styleFrom(
          backgroundColor: surfaces.ink,
          foregroundColor: surfaces.onInk,
          hoverColor: surfaces.onInk.withValues(alpha: 0.08),
          shape: const CircleBorder(),
          side: BorderSide.none,
          elevation: 4,
          shadowColor: OmnisonicColors.scrimStrong,
          fixedSize: Size.square(diameter),
        ),
      ),
    );
  }
}
