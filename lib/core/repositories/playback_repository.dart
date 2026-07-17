import '../entities/entities.dart';
import '../errors/result.dart';

/// Repository interface for audio playback operations
abstract class PlaybackRepository {
  /// Plays a specific track
  Future<Result<void>> play(Track track);

  /// Pauses the current playback
  Future<Result<void>> pause();

  /// Resumes the current playback
  Future<Result<void>> resume();

  /// Stops the current playback
  Future<Result<void>> stop();

  /// Seeks to a specific position in the current track
  Future<Result<void>> seek(Duration position);

  /// Skips to the next track in the queue
  Future<Result<void>> skipToNext();

  /// Skips to the previous track in the queue
  Future<Result<void>> skipToPrevious();

  /// Sets the playback queue
  Future<Result<void>> setQueue(List<Track> tracks, {int startIndex = 0});

  /// Adds a track to the end of the queue
  Future<Result<void>> addToQueue(Track track);

  /// Inserts a track at a specific position in the queue
  Future<Result<void>> insertInQueue(Track track, int index);

  /// Removes a track from the queue
  Future<Result<void>> removeFromQueue(int index);

  /// Clears the entire queue
  Future<Result<void>> clearQueue();

  /// Shuffles the current queue
  Future<Result<void>> shuffleQueue();

  /// Sets the repeat mode
  Future<Result<void>> setRepeatMode(RepeatMode mode);

  /// Sets the shuffle mode
  Future<Result<void>> setShuffleMode(bool enabled);

  /// Sets the playback volume (0.0 to 1.0)
  Future<Result<void>> setVolume(double volume);

  /// Observes the current playback state
  Stream<PlaybackState> observePlaybackState();

  /// Observes the current playback position
  Stream<Duration> observePosition();

  /// Observes the current queue
  Stream<List<Track>> observeQueue();

  /// Gets the current playback state
  Future<Result<PlaybackState>> getCurrentState();

  /// Gets the current queue
  Future<Result<List<Track>>> getCurrentQueue();

  /// Gets the current track
  Future<Result<Track?>> getCurrentTrack();
}

/// Represents the current state of audio playback
class PlaybackState {
  const PlaybackState({
    required this.isPlaying,
    required this.currentTrack,
    required this.position,
    required this.duration,
    required this.queue,
    required this.currentIndex,
    required this.repeatMode,
    required this.shuffleEnabled,
    required this.volume,
    this.error,
  });

  final bool isPlaying;
  final Track? currentTrack;
  final Duration position;
  final Duration duration;
  final List<Track> queue;
  final int currentIndex;
  final RepeatMode repeatMode;
  final bool shuffleEnabled;
  final double volume;
  final String? error;

  /// Returns true if there is a current track
  bool get hasCurrentTrack => currentTrack != null;

  /// Returns true if playback is paused
  bool get isPaused => !isPlaying && hasCurrentTrack;

  /// Returns true if playback is stopped
  bool get isStopped => !isPlaying && !hasCurrentTrack;

  /// Returns true if there's a next track in the queue
  bool get hasNext => currentIndex < queue.length - 1;

  /// Returns true if there's a previous track in the queue
  bool get hasPrevious => currentIndex > 0;

  /// Returns the progress as a percentage (0.0 to 1.0)
  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  PlaybackState copyWith({
    bool? isPlaying,
    Track? currentTrack,
    Duration? position,
    Duration? duration,
    List<Track>? queue,
    int? currentIndex,
    RepeatMode? repeatMode,
    bool? shuffleEnabled,
    double? volume,
    String? error,
  }) {
    return PlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentTrack: currentTrack ?? this.currentTrack,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      repeatMode: repeatMode ?? this.repeatMode,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      volume: volume ?? this.volume,
      error: error ?? this.error,
    );
  }
}

/// Enum for repeat modes
enum RepeatMode {
  none,
  one,
  all;

  @override
  String toString() {
    switch (this) {
      case RepeatMode.none:
        return 'None';
      case RepeatMode.one:
        return 'Repeat One';
      case RepeatMode.all:
        return 'Repeat All';
    }
  }
}
