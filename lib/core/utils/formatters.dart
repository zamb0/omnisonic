/// Display formatting shared by every screen.
///
/// There used to be a private copy of each of these per widget, and they
/// disagreed: none of the duration copies handled hours (a 75-minute mix read
/// "75:00"), and the player zero-padded minutes where everything else did not.
library;

/// A track position or length: `3:07`, or `1:15:00` past the hour.
String formatDuration(Duration? duration, {String unknown = '--:--'}) {
  if (duration == null || duration.isNegative) return unknown;
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$seconds';
  }
  return '$minutes:$seconds';
}

/// A running time summarised for a header: `42 min`, `1 h 12 min`.
String formatTotalDuration(Duration total) {
  final hours = total.inHours;
  final minutes = total.inMinutes % 60;
  if (hours > 0) return minutes > 0 ? '$hours h $minutes min' : '$hours h';
  // "0 min" read as empty for a 55s playlist.
  if (total > Duration.zero && total.inMinutes == 0) return '<1 min';
  return '${total.inMinutes} min';
}

/// How long ago [time] was: `Just now`, `5m ago`, `3h ago`, `2d ago`, and the
/// date itself past a week.
String formatRelativeTime(DateTime time, {DateTime? now}) {
  final difference = (now ?? DateTime.now()).difference(time);
  if (difference.inDays > 7) {
    return '${time.day}/${time.month}/${time.year}';
  }
  if (difference.inDays > 0) return '${difference.inDays}d ago';
  if (difference.inHours > 0) return '${difference.inHours}h ago';
  if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
  return 'Just now';
}

/// `1 track`, `3 tracks`. [plural] defaults to [singular] + `s`.
String pluralize(int count, String singular, {String? plural}) =>
    '$count ${count == 1 ? singular : (plural ?? '${singular}s')}';
