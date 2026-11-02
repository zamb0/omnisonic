import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// Small colored dot identifying which source server a track/album came
/// from, using [OmnisonicColors.serverColorFor]'s deterministic per-server
/// hue. A thin surface-colored ring keeps the dot legible when it sits over
/// cover art of a similar color.
class ServerDot extends StatelessWidget {
  const ServerDot({super.key, required this.serverId, this.size = 10});

  final String serverId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: OmnisonicColors.serverColorFor(serverId),
        border: Border.all(color: scheme.surface, width: size * 0.2),
      ),
    );
  }
}

/// A small cluster of overlapping [ServerDot]s, used to badge items that
/// exist on more than one server (e.g. a deduplicated album with several
/// source copies).
class ServerDotStack extends StatelessWidget {
  const ServerDotStack({
    super.key,
    required this.serverIds,
    this.dotSize = 10,
    this.maxDots = 3,
  });

  final List<String> serverIds;
  final double dotSize;
  final int maxDots;

  @override
  Widget build(BuildContext context) {
    final shown = serverIds.take(maxDots).toList();
    final overlap = dotSize * 0.55;

    return SizedBox(
      width: dotSize + overlap * (shown.length - 1),
      height: dotSize,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: overlap * i,
              child: ServerDot(serverId: shown[i], size: dotSize),
            ),
        ],
      ),
    );
  }
}
