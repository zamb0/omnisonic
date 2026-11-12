import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/utils/formatters.dart';
import '../../../ui/presentation/widgets/cover_art.dart';
import '../../data/datasources/handoff_service.dart';

/// The player bar while another of the user's devices plays and this one
/// does not: what is playing there, with its progress, and a way to bring
/// it here.
///
/// Deliberately unlike the local bar — a device icon and "Playing on
/// iPhone" where the transport controls would be — so it never reads as
/// this device playing.
class RemotePlaybackBar extends StatelessWidget {
  const RemotePlaybackBar({
    super.key,
    required this.remote,
    required this.onContinue,
    this.compact = true,
  });

  final RemoteNowPlaying remote;
  final VoidCallback onContinue;

  /// The phone bar (one 64pt row) rather than the wider desktop one.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final track = remote.track;
    final where = remote.playing
        ? 'Playing on ${remote.deviceName}'
        : 'Paused on ${remote.deviceName}';

    return Semantics(
      container: true,
      label: '$where: ${track.title} by ${track.artist}',
      child: GlassPanel(
        borderRadius: BorderRadius.circular(OmnisonicRadius.panel),
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: compact ? 64 : 72,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: OmnisonicSpacing.ms,
                  ),
                  child: Row(
                    children: [
                      // Dimmed: the music is not coming out of this device.
                      Opacity(
                        opacity: 0.85,
                        child: CoverArt(
                          url: track.coverArtUrl,
                          seed: track.albumId ?? track.id,
                          size: compact ? 44 : 52,
                          radius: OmnisonicRadius.sm,
                        ),
                      ),
                      const SizedBox(width: OmnisonicSpacing.ms),
                      Expanded(
                        child: ExcludeSemantics(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: OmnisonicTypography.titleSmall.copyWith(
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    OmnisonicIcons.devices,
                                    size: OmnisonicIconSizes.xs,
                                    color: scheme.primary,
                                  ),
                                  const SizedBox(width: OmnisonicSpacing.xs),
                                  Flexible(
                                    child: Text(
                                      where,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: OmnisonicTypography.bodySmall
                                          .copyWith(
                                            color: scheme.primary,
                                            fontWeight:
                                                OmnisonicTypography.medium,
                                          ),
                                    ),
                                  ),
                                  if (!compact) ...[
                                    const SizedBox(width: OmnisonicSpacing.sm),
                                    _RemoteClock(remote: remote),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: OmnisonicSpacing.sm),
                      if (compact)
                        IconButton(
                          onPressed: onContinue,
                          tooltip: 'Continue here',
                          icon: const Icon(OmnisonicIcons.playArrow),
                        )
                      else
                        OmnisonicButton(
                          label: 'Continue here',
                          icon: OmnisonicIcons.playArrow,
                          onPressed: onContinue,
                        ),
                    ],
                  ),
                ),
              ),
              _RemoteProgressLine(remote: remote),
            ],
          ),
        ),
      ),
    );
  }
}

/// Repaints itself while the other device plays: the view model only
/// notifies when the remote state changes, not as it advances.
mixin _RemoteTicker<T extends StatefulWidget> on State<T> {
  RemoteNowPlaying get remote;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  void _sync() {
    _timer?.cancel();
    if (remote.playing) {
      _timer = Timer.periodic(
        RemoteNowPlaying.refreshEvery,
        (_) => setState(() {}),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class _RemoteProgressLine extends StatefulWidget {
  const _RemoteProgressLine({required this.remote});

  final RemoteNowPlaying remote;

  @override
  State<_RemoteProgressLine> createState() => _RemoteProgressLineState();
}

class _RemoteProgressLineState extends State<_RemoteProgressLine>
    with _RemoteTicker {
  @override
  RemoteNowPlaying get remote => widget.remote;

  @override
  void didUpdateWidget(_RemoteProgressLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.remote.playing != remote.playing) _sync();
  }

  @override
  Widget build(BuildContext context) {
    final duration = remote.duration.inMilliseconds;
    final fraction = duration <= 0
        ? 0.0
        : remote.positionAt(DateTime.now()).inMilliseconds / duration;
    return RepaintBoundary(
      child: AuroraProgressLine(fraction: fraction.clamp(0.0, 1.0)),
    );
  }
}

class _RemoteClock extends StatefulWidget {
  const _RemoteClock({required this.remote});

  final RemoteNowPlaying remote;

  @override
  State<_RemoteClock> createState() => _RemoteClockState();
}

class _RemoteClockState extends State<_RemoteClock> with _RemoteTicker {
  @override
  RemoteNowPlaying get remote => widget.remote;

  @override
  void didUpdateWidget(_RemoteClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.remote.playing != remote.playing) _sync();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      '${formatDuration(remote.positionAt(DateTime.now()))} / '
      '${formatDuration(remote.duration)}',
      style: OmnisonicTypography.technicalSmall.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
