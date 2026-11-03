import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/entities/entities.dart';
import '../../../servers/presentation/viewmodels/server_management_view_model.dart';

/// Small coloured dot identifying which source server a track or album came
/// from.
///
/// The colour is picked by the server's position in the user's server list
/// ([OmnisonicColors.serverColorFor] with an index), so two servers never
/// share a dot; it falls back to a hash of the id where the list is not
/// available. Colour is never the only cue: the dot carries the server's name
/// as a tooltip and for screen readers.
///
/// A thin surface-coloured ring keeps the dot legible over cover art of a
/// similar colour.
class ServerDot extends StatelessWidget {
  const ServerDot({super.key, required this.serverId, this.size = 10});

  final String serverId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final servers = _servers(context);
    final index = servers?.indexWhere((s) => s.id == serverId) ?? -1;
    final name = index >= 0 ? servers![index].name : null;

    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: OmnisonicColors.serverColorFor(
          serverId,
          index: index >= 0 ? index : null,
        ),
        border: Border.all(color: scheme.surface, width: size * 0.2),
      ),
    );

    if (name == null) return ExcludeSemantics(child: dot);
    return Tooltip(
      message: name,
      excludeFromSemantics: true,
      child: Semantics(label: 'On $name', child: dot),
    );
  }

  static List<MusicServer>? _servers(BuildContext context) {
    try {
      return context.select<ServerManagementViewModel, List<MusicServer>>(
        (vm) => vm.servers,
      );
    } on ProviderNotFoundException {
      return null;
    }
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

    // One tooltip for the cluster: the per-dot ones overlap and are too
    // small to aim at.
    final servers = ServerDot._servers(context);
    final names = [
      for (final id in serverIds)
        servers?.where((s) => s.id == id).firstOrNull?.name ?? id,
    ];
    final stack = SizedBox(
      width: dotSize + overlap * (shown.length - 1),
      height: dotSize,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: overlap * i,
              child: ExcludeSemantics(
                child: TooltipVisibility(
                  visible: false,
                  child: ServerDot(serverId: shown[i], size: dotSize),
                ),
              ),
            ),
        ],
      ),
    );
    final label = 'On ${names.join(' and ')}';
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(label: label, child: stack),
    );
  }
}
