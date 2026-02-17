import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/usecases/usecases.dart';
import '../../../../core/errors/result.dart';

/// BLoC for managing complex playback state and operations
/// 
/// Handles:
/// - Advanced playback state management
/// - Queue operations and smart shuffling
/// - Crossfade and gapless playback
/// - Playback analytics and history
@injectable
class PlaybackBloc extends Bloc<PlaybackEvent, PlaybackBlocState> {
  PlaybackBloc(
    this._playbackRepository,
    this._playTrackUseCase,
  ) : super(const PlaybackBlocState.initial()) {
    on<PlaybackInitialized>(_onPlaybackInitialized);
    on<PlaybackTrackRequested>(_onPlaybackTrackRequested);
    on<PlaybackStateChanged>(_onPlaybackStateChanged);
    on<PlaybackPositionChanged>(_onPlaybackPositionChanged);
    on<PlaybackQueueChanged>(_onPlaybackQueueChanged);
    on<PlaybackControlRequested>(_onPlaybackControlRequested);
    on<PlaybackQueueOperationRequested>(_onPlaybackQueueOperationRequested);
    on<PlaybackSettingsChanged>(_onPlaybackSettingsChanged);
    on<PlaybackAnalyticsUpdated>(_onPlaybackAnalyticsUpdated);
    
    _initialize();
  }

  final PlaybackRepository _playbackRepository;
  final PlayTrackUseCase _playTrackUseCase;

  StreamSubscription<PlaybackState>? _playbackStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<List<Track>>? _queueSubscription;
  Timer? _analyticsTimer;

  void _initialize() {
    add(const PlaybackInitialized());
  }

  Future<void> _onPlaybackInitialized(PlaybackInitialized event, Emitter<PlaybackBlocState> emit) async {
    emit(state.copyWith(status: PlaybackBlocStatus.loading));

    try {
      // Subscribe to playback state changes
      _playbackStateSubscription = _playbackRepository.observePlaybackState().listen(
        (playbackState) => add(PlaybackStateChanged(playbackState)),
      );

      // Subscribe to position changes
      _positionSubscription = _playbackRepository.observePosition().listen(
        (position) => add(PlaybackPositionChanged(position)),
      );

      // Subscribe to queue changes
      _queueSubscription = _playbackRepository.observeQueue().listen(
        (queue) => add(PlaybackQueueChanged(queue)),
      );

      // Load current state
      final currentStateResult = await _playbackRepository.getCurrentState();
      if (currentStateResult.isSuccess) {
        final currentState = currentStateResult.valueOrNull!;
        emit(state.copyWith(
          status: PlaybackBlocStatus.ready,
          playbackState: currentState,
        ));
      } else {
        emit(state.copyWith(
          status: PlaybackBlocStatus.error,
          errorMessage: 'Failed to initialize playback: ${currentStateResult.failureOrNull?.message}',
        ));
      }

      // Start analytics timer
      _startAnalyticsTimer();
    } catch (e) {
      emit(state.copyWith(
        status: PlaybackBlocStatus.error,
        errorMessage: 'Unexpected error during initialization: $e',
      ));
    }
  }

  Future<void> _onPlaybackTrackRequested(PlaybackTrackRequested event, Emitter<PlaybackBlocState> emit) async {
    emit(state.copyWith(status: PlaybackBlocStatus.loading));

    try {
      final params = PlayTrackParams(
        track: event.track,
        queue: event.queue,
        startIndex: event.startIndex,
        useBestSource: event.useBestSource,
        allowFallback: event.allowFallback,
      );

      final result = await _playTrackUseCase(params);
      
      result.fold(
        (failure) => emit(state.copyWith(
          status: PlaybackBlocStatus.error,
          errorMessage: 'Failed to play track: ${failure.message}',
        )),
        (_) => emit(state.copyWith(
          status: PlaybackBlocStatus.ready,
          errorMessage: null,
        )),
      );
    } catch (e) {
      emit(state.copyWith(
        status: PlaybackBlocStatus.error,
        errorMessage: 'Unexpected error playing track: $e',
      ));
    }
  }

  void _onPlaybackStateChanged(PlaybackStateChanged event, Emitter<PlaybackBlocState> emit) {
    final newState = state.copyWith(
      playbackState: event.playbackState,
      status: PlaybackBlocStatus.ready,
      errorMessage: null,
    );

    // Update analytics if track changed
    if (state.playbackState.currentTrack?.id != event.playbackState.currentTrack?.id) {
      final analytics = _updateTrackAnalytics(newState.analytics, event.playbackState.currentTrack);
      emit(newState.copyWith(analytics: analytics));
    } else {
      emit(newState);
    }
  }

  void _onPlaybackPositionChanged(PlaybackPositionChanged event, Emitter<PlaybackBlocState> emit) {
    if (state.playbackState.currentTrack != null) {
      final updatedPlaybackState = state.playbackState.copyWith(position: event.position);
      emit(state.copyWith(playbackState: updatedPlaybackState));
    }
  }

  void _onPlaybackQueueChanged(PlaybackQueueChanged event, Emitter<PlaybackBlocState> emit) {
    final updatedPlaybackState = state.playbackState.copyWith(queue: event.queue);
    emit(state.copyWith(playbackState: updatedPlaybackState));
  }

  Future<void> _onPlaybackControlRequested(PlaybackControlRequested event, Emitter<PlaybackBlocState> emit) async {
    try {
      Result<void> result;
      
      switch (event.control) {
        case PlaybackControl.play:
          if (state.playbackState.currentTrack != null) {
            result = await _playbackRepository.resume();
          } else {
            return; // No track to play
          }
          break;
        case PlaybackControl.pause:
          result = await _playbackRepository.pause();
          break;
        case PlaybackControl.stop:
          result = await _playbackRepository.stop();
          break;
        case PlaybackControl.next:
          result = await _playbackRepository.skipToNext();
          break;
        case PlaybackControl.previous:
          result = await _playbackRepository.skipToPrevious();
          break;
        case PlaybackControl.seek:
          if (event.seekPosition != null) {
            result = await _playbackRepository.seek(event.seekPosition!);
          } else {
            return;
          }
          break;
      }

      if (result.isFailure) {
        emit(state.copyWith(
          status: PlaybackBlocStatus.error,
          errorMessage: 'Playback control failed: ${result.failureOrNull?.message}',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: PlaybackBlocStatus.error,
        errorMessage: 'Unexpected error during playback control: $e',
      ));
    }
  }

  Future<void> _onPlaybackQueueOperationRequested(PlaybackQueueOperationRequested event, Emitter<PlaybackBlocState> emit) async {
    try {
      Result<void> result;
      
      switch (event.operation) {
        case QueueOperation.add:
          if (event.track != null) {
            result = await _playbackRepository.addToQueue(event.track!);
          } else {
            return;
          }
          break;
        case QueueOperation.insert:
          if (event.track != null && event.index != null) {
            result = await _playbackRepository.insertInQueue(event.track!, event.index!);
          } else {
            return;
          }
          break;
        case QueueOperation.remove:
          if (event.index != null) {
            result = await _playbackRepository.removeFromQueue(event.index!);
          } else {
            return;
          }
          break;
        case QueueOperation.clear:
          result = await _playbackRepository.clearQueue();
          break;
        case QueueOperation.shuffle:
          result = await _playbackRepository.shuffleQueue();
          break;
        case QueueOperation.setQueue:
          if (event.tracks != null) {
            result = await _playbackRepository.setQueue(event.tracks!, startIndex: event.index ?? 0);
          } else {
            return;
          }
          break;
      }

      if (result.isFailure) {
        emit(state.copyWith(
          status: PlaybackBlocStatus.error,
          errorMessage: 'Queue operation failed: ${result.failureOrNull?.message}',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: PlaybackBlocStatus.error,
        errorMessage: 'Unexpected error during queue operation: $e',
      ));
    }
  }

  Future<void> _onPlaybackSettingsChanged(PlaybackSettingsChanged event, Emitter<PlaybackBlocState> emit) async {
    try {
      if (event.repeatMode != null) {
        final result = await _playbackRepository.setRepeatMode(event.repeatMode!);
        if (result.isFailure) {
          emit(state.copyWith(
            errorMessage: 'Failed to set repeat mode: ${result.failureOrNull?.message}',
          ));
          return;
        }
      }

      if (event.shuffleEnabled != null) {
        final result = await _playbackRepository.setShuffleMode(event.shuffleEnabled!);
        if (result.isFailure) {
          emit(state.copyWith(
            errorMessage: 'Failed to set shuffle mode: ${result.failureOrNull?.message}',
          ));
          return;
        }
      }

      if (event.volume != null) {
        final result = await _playbackRepository.setVolume(event.volume!);
        if (result.isFailure) {
          emit(state.copyWith(
            errorMessage: 'Failed to set volume: ${result.failureOrNull?.message}',
          ));
          return;
        }
      }

      if (event.settings != null) {
        emit(state.copyWith(settings: event.settings));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Unexpected error changing settings: $e',
      ));
    }
  }

  void _onPlaybackAnalyticsUpdated(PlaybackAnalyticsUpdated event, Emitter<PlaybackBlocState> emit) {
    emit(state.copyWith(analytics: event.analytics));
  }

  void _startAnalyticsTimer() {
    _analyticsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (state.playbackState.isPlaying && state.playbackState.currentTrack != null) {
        final updatedAnalytics = _updatePlaytimeAnalytics(state.analytics);
        add(PlaybackAnalyticsUpdated(updatedAnalytics));
      }
    });
  }

  PlaybackAnalytics _updateTrackAnalytics(PlaybackAnalytics current, Track? track) {
    if (track == null) return current;

    final updatedHistory = List<Track>.from(current.playHistory);
    updatedHistory.insert(0, track);
    
    // Keep only last 100 tracks
    if (updatedHistory.length > 100) {
      updatedHistory.removeRange(100, updatedHistory.length);
    }

    final updatedPlayCounts = Map<String, int>.from(current.playCounts);
    updatedPlayCounts[track.id] = (updatedPlayCounts[track.id] ?? 0) + 1;

    return current.copyWith(
      playHistory: updatedHistory,
      playCounts: updatedPlayCounts,
      totalTracksPlayed: current.totalTracksPlayed + 1,
    );
  }

  PlaybackAnalytics _updatePlaytimeAnalytics(PlaybackAnalytics current) {
    return current.copyWith(
      totalPlaytime: current.totalPlaytime + const Duration(seconds: 5),
    );
  }

  @override
  Future<void> close() {
    _playbackStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _queueSubscription?.cancel();
    _analyticsTimer?.cancel();
    return super.close();
  }
}

// Events
abstract class PlaybackEvent extends Equatable {
  const PlaybackEvent();

  @override
  List<Object?> get props => [];
}

class PlaybackInitialized extends PlaybackEvent {
  const PlaybackInitialized();
}

class PlaybackTrackRequested extends PlaybackEvent {
  const PlaybackTrackRequested({
    required this.track,
    this.queue,
    this.startIndex,
    this.useBestSource = true,
    this.allowFallback = true,
  });

  final Track track;
  final List<Track>? queue;
  final int? startIndex;
  final bool useBestSource;
  final bool allowFallback;

  @override
  List<Object?> get props => [track, queue, startIndex, useBestSource, allowFallback];
}

class PlaybackStateChanged extends PlaybackEvent {
  const PlaybackStateChanged(this.playbackState);

  final PlaybackState playbackState;

  @override
  List<Object?> get props => [playbackState];
}

class PlaybackPositionChanged extends PlaybackEvent {
  const PlaybackPositionChanged(this.position);

  final Duration position;

  @override
  List<Object?> get props => [position];
}

class PlaybackQueueChanged extends PlaybackEvent {
  const PlaybackQueueChanged(this.queue);

  final List<Track> queue;

  @override
  List<Object?> get props => [queue];
}

class PlaybackControlRequested extends PlaybackEvent {
  const PlaybackControlRequested({
    required this.control,
    this.seekPosition,
  });

  final PlaybackControl control;
  final Duration? seekPosition;

  @override
  List<Object?> get props => [control, seekPosition];
}

class PlaybackQueueOperationRequested extends PlaybackEvent {
  const PlaybackQueueOperationRequested({
    required this.operation,
    this.track,
    this.tracks,
    this.index,
  });

  final QueueOperation operation;
  final Track? track;
  final List<Track>? tracks;
  final int? index;

  @override
  List<Object?> get props => [operation, track, tracks, index];
}

class PlaybackSettingsChanged extends PlaybackEvent {
  const PlaybackSettingsChanged({
    this.repeatMode,
    this.shuffleEnabled,
    this.volume,
    this.settings,
  });

  final RepeatMode? repeatMode;
  final bool? shuffleEnabled;
  final double? volume;
  final PlaybackSettings? settings;

  @override
  List<Object?> get props => [repeatMode, shuffleEnabled, volume, settings];
}

class PlaybackAnalyticsUpdated extends PlaybackEvent {
  const PlaybackAnalyticsUpdated(this.analytics);

  final PlaybackAnalytics analytics;

  @override
  List<Object?> get props => [analytics];
}

// Enums
enum PlaybackBlocStatus {
  initial,
  loading,
  ready,
  error,
}

enum PlaybackControl {
  play,
  pause,
  stop,
  next,
  previous,
  seek,
}

enum QueueOperation {
  add,
  insert,
  remove,
  clear,
  shuffle,
  setQueue,
}

// State
class PlaybackBlocState extends Equatable {
  const PlaybackBlocState({
    required this.status,
    required this.playbackState,
    required this.settings,
    required this.analytics,
    this.errorMessage,
  });

  const PlaybackBlocState.initial()
      : status = PlaybackBlocStatus.initial,
        playbackState = const PlaybackState(
          isPlaying: false,
          currentTrack: null,
          position: Duration.zero,
          duration: Duration.zero,
          queue: [],
          currentIndex: -1,
          repeatMode: RepeatMode.none,
          shuffleEnabled: false,
          volume: 1.0,
        ),
        settings = const PlaybackSettings(),
        analytics = const PlaybackAnalytics(),
        errorMessage = null;

  final PlaybackBlocStatus status;
  final PlaybackState playbackState;
  final PlaybackSettings settings;
  final PlaybackAnalytics analytics;
  final String? errorMessage;

  bool get isInitial => status == PlaybackBlocStatus.initial;
  bool get isLoading => status == PlaybackBlocStatus.loading;
  bool get isReady => status == PlaybackBlocStatus.ready;
  bool get isError => status == PlaybackBlocStatus.error;
  bool get hasError => errorMessage != null;

  PlaybackBlocState copyWith({
    PlaybackBlocStatus? status,
    PlaybackState? playbackState,
    PlaybackSettings? settings,
    PlaybackAnalytics? analytics,
    String? errorMessage,
  }) {
    return PlaybackBlocState(
      status: status ?? this.status,
      playbackState: playbackState ?? this.playbackState,
      settings: settings ?? this.settings,
      analytics: analytics ?? this.analytics,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        playbackState,
        settings,
        analytics,
        errorMessage,
      ];
}

// Additional classes
class PlaybackSettings extends Equatable {
  const PlaybackSettings({
    this.crossfadeEnabled = false,
    this.crossfadeDuration = const Duration(seconds: 3),
    this.gaplessPlayback = true,
    this.replayGain = false,
    this.audioNormalization = false,
  });

  final bool crossfadeEnabled;
  final Duration crossfadeDuration;
  final bool gaplessPlayback;
  final bool replayGain;
  final bool audioNormalization;

  PlaybackSettings copyWith({
    bool? crossfadeEnabled,
    Duration? crossfadeDuration,
    bool? gaplessPlayback,
    bool? replayGain,
    bool? audioNormalization,
  }) {
    return PlaybackSettings(
      crossfadeEnabled: crossfadeEnabled ?? this.crossfadeEnabled,
      crossfadeDuration: crossfadeDuration ?? this.crossfadeDuration,
      gaplessPlayback: gaplessPlayback ?? this.gaplessPlayback,
      replayGain: replayGain ?? this.replayGain,
      audioNormalization: audioNormalization ?? this.audioNormalization,
    );
  }

  @override
  List<Object?> get props => [
        crossfadeEnabled,
        crossfadeDuration,
        gaplessPlayback,
        replayGain,
        audioNormalization,
      ];
}

class PlaybackAnalytics extends Equatable {
  const PlaybackAnalytics({
    this.playHistory = const [],
    this.playCounts = const {},
    this.totalPlaytime = Duration.zero,
    this.totalTracksPlayed = 0,
    this.sessionStartTime,
  });

  final List<Track> playHistory;
  final Map<String, int> playCounts;
  final Duration totalPlaytime;
  final int totalTracksPlayed;
  final DateTime? sessionStartTime;

  PlaybackAnalytics copyWith({
    List<Track>? playHistory,
    Map<String, int>? playCounts,
    Duration? totalPlaytime,
    int? totalTracksPlayed,
    DateTime? sessionStartTime,
  }) {
    return PlaybackAnalytics(
      playHistory: playHistory ?? this.playHistory,
      playCounts: playCounts ?? this.playCounts,
      totalPlaytime: totalPlaytime ?? this.totalPlaytime,
      totalTracksPlayed: totalTracksPlayed ?? this.totalTracksPlayed,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
    );
  }

  @override
  List<Object?> get props => [
        playHistory,
        playCounts,
        totalPlaytime,
        totalTracksPlayed,
        sessionStartTime,
      ];
}