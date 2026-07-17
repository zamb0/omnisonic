import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/entities/entities.dart';
import '../../../playback/presentation/viewmodels/playback_view_model.dart';

/// Service class for handling track-related actions
class TrackActions {
  final BuildContext context;

  TrackActions(this.context);

  /// Show the track options bottom sheet
  void showOptions(Track track, {VoidCallback? onPlayNow}) {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          _buildTrackOptionsSheet(track, onPlayNow: onPlayNow),
    );
  }

  Widget _buildTrackOptionsSheet(Track track, {VoidCallback? onPlayNow}) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Play Now'),
            onTap: () {
              Navigator.pop(context);
              onPlayNow?.call();
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music),
            title: const Text('Add to Queue'),
            onTap: () {
              Navigator.pop(context);
              addToQueue(track);
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Add to Playlist'),
            onTap: () {
              Navigator.pop(context);
              addToPlaylist(track);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Track Info'),
            onTap: () {
              Navigator.pop(context);
              showInfo(track);
            },
          ),
        ],
      ),
    );
  }

  /// Add track to playback queue
  void addToQueue(Track track) {
    context.read<PlaybackViewModel>().addToQueue(track);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Added to queue')));
  }

  /// Add track to a playlist (placeholder for future implementation)
  void addToPlaylist(Track track) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add to playlist - Coming soon')),
    );
  }

  /// Show detailed information about the track
  void showInfo(Track track) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(track.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Artist', track.artist),
            _buildInfoRow('Album', track.album),
            _buildInfoRow('Duration', _formatDuration(track.duration)),
            if (track.year != null)
              _buildInfoRow('Year', track.year.toString()),
            if (track.genre != null) _buildInfoRow('Genre', track.genre!),
            _buildInfoRow('Quality', track.quality.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
