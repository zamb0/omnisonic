import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/usecases/usecases.dart';
import '../../../../core/errors/result.dart';

/// BLoC for managing background synchronization state and operations
/// 
/// Handles:
/// - Background sync scheduling and execution
/// - Sync progress tracking and status updates
/// - Conflict resolution during sync operations
/// - Automatic retry logic for failed syncs
@injectable
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc(
    this._syncMusicCollectionUseCase,
    this._serverRepository,
  ) : super(const SyncState.initial()) {
    on<SyncStarted>(_onSyncStarted);
    on<SyncServerRequested>(_onSyncServerRequested);
    on<SyncProgressUpdated>(_onSyncProgressUpdated);
    on<SyncCompleted>(_onSyncCompleted);
    on<SyncFailed>(_onSyncFailed);
    on<SyncCancelled>(_onSyncCancelled);
    on<AutoSyncToggled>(_onAutoSyncToggled);
    on<SyncRetryRequested>(_onSyncRetryRequested);
    
    _initializeAutoSync();
  }

  final SyncMusicCollectionUseCase _syncMusicCollectionUseCase;
  final ServerRepository _serverRepository;

  Timer? _autoSyncTimer;
  StreamSubscription<List<MusicServer>>? _serverSubscription;

  void _initializeAutoSync() {
    // Monitor server changes to trigger auto-sync
    _serverSubscription = _serverRepository.observeServers().listen(
      (servers) {
        if (state.autoSyncEnabled && servers.any((s) => s.isAvailable)) {
          add(const SyncStarted());
        }
      },
    );
  }

  Future<void> _onSyncStarted(SyncStarted event, Emitter<SyncState> emit) async {
    if (state.status == SyncStatus.syncing) return;

    emit(state.copyWith(
      status: SyncStatus.syncing,
      progress: 0.0,
      currentServer: null,
      errorMessage: null,
      lastSyncTime: null,
    ));

    try {
      // Get all online servers
      final serversResult = await _serverRepository.getOnlineServers();
      if (serversResult.isFailure) {
        add(SyncFailed(serversResult.failureOrNull!.message));
        return;
      }

      final onlineServers = serversResult.valueOrNull!;
      if (onlineServers.isEmpty) {
        add(const SyncFailed('No online servers available for synchronization'));
        return;
      }

      // Sync from all servers with progress tracking
      double progressPerServer = 1.0 / onlineServers.length;
      double currentProgress = 0.0;

      for (int i = 0; i < onlineServers.length; i++) {
        final server = onlineServers[i];
        
        emit(state.copyWith(
          currentServer: server,
          progress: currentProgress,
        ));

        final params = SyncMusicCollectionParams(
          serverId: server.id,
          forceRefresh: event.forceRefresh,
        );

        final result = await _syncMusicCollectionUseCase(params);
        if (result.isFailure) {
          add(SyncFailed('Failed to sync from ${server.name}: ${result.failureOrNull!.message}'));
          return;
        }

        currentProgress += progressPerServer;
        emit(state.copyWith(progress: currentProgress));
      }

      add(const SyncCompleted());
    } catch (e) {
      add(SyncFailed('Unexpected error during sync: $e'));
    }
  }

  Future<void> _onSyncServerRequested(SyncServerRequested event, Emitter<SyncState> emit) async {
    if (state.status == SyncStatus.syncing) return;

    emit(state.copyWith(
      status: SyncStatus.syncing,
      progress: 0.0,
      currentServer: null,
      errorMessage: null,
    ));

    try {
      // Get the specific server
      final serverResult = await _serverRepository.getServerById(event.serverId);
      if (serverResult.isFailure) {
        add(SyncFailed('Server not found: ${event.serverId}'));
        return;
      }

      final server = serverResult.valueOrNull;
      if (server == null) {
        add(SyncFailed('Server not found: ${event.serverId}'));
        return;
      }

      if (!server.isAvailable) {
        add(SyncFailed('Server ${server.name} is not available'));
        return;
      }

      emit(state.copyWith(currentServer: server, progress: 0.5));

      final params = SyncMusicCollectionParams(
        serverId: event.serverId,
        forceRefresh: event.forceRefresh,
      );

      final result = await _syncMusicCollectionUseCase(params);
      if (result.isFailure) {
        add(SyncFailed('Failed to sync from ${server.name}: ${result.failureOrNull!.message}'));
        return;
      }

      add(const SyncCompleted());
    } catch (e) {
      add(SyncFailed('Unexpected error during server sync: $e'));
    }
  }

  void _onSyncProgressUpdated(SyncProgressUpdated event, Emitter<SyncState> emit) {
    emit(state.copyWith(progress: event.progress));
  }

  void _onSyncCompleted(SyncCompleted event, Emitter<SyncState> emit) {
    emit(state.copyWith(
      status: SyncStatus.completed,
      progress: 1.0,
      currentServer: null,
      lastSyncTime: DateTime.now(),
      errorMessage: null,
    ));

    // Schedule next auto-sync if enabled
    if (state.autoSyncEnabled) {
      _scheduleAutoSync();
    }
  }

  void _onSyncFailed(SyncFailed event, Emitter<SyncState> emit) {
    emit(state.copyWith(
      status: SyncStatus.failed,
      errorMessage: event.errorMessage,
      currentServer: null,
    ));

    // Schedule retry if auto-sync is enabled
    if (state.autoSyncEnabled) {
      _scheduleAutoSyncRetry();
    }
  }

  void _onSyncCancelled(SyncCancelled event, Emitter<SyncState> emit) {
    emit(state.copyWith(
      status: SyncStatus.idle,
      progress: 0.0,
      currentServer: null,
      errorMessage: null,
    ));
  }

  void _onAutoSyncToggled(AutoSyncToggled event, Emitter<SyncState> emit) {
    emit(state.copyWith(autoSyncEnabled: event.enabled));

    if (event.enabled) {
      _scheduleAutoSync();
    } else {
      _autoSyncTimer?.cancel();
      _autoSyncTimer = null;
    }
  }

  void _onSyncRetryRequested(SyncRetryRequested event, Emitter<SyncState> emit) {
    if (state.status != SyncStatus.failed) return;
    
    add(SyncStarted(forceRefresh: event.forceRefresh));
  }

  void _scheduleAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer(const Duration(minutes: 5), () {
      if (state.autoSyncEnabled && state.status != SyncStatus.syncing) {
        add(const SyncStarted());
      }
    });
  }

  void _scheduleAutoSyncRetry() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer(const Duration(minutes: 1), () {
      if (state.autoSyncEnabled && state.status == SyncStatus.failed) {
        add(const SyncRetryRequested());
      }
    });
  }

  @override
  Future<void> close() {
    _autoSyncTimer?.cancel();
    _serverSubscription?.cancel();
    return super.close();
  }
}

// Events
abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class SyncStarted extends SyncEvent {
  const SyncStarted({this.forceRefresh = false});

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}

class SyncServerRequested extends SyncEvent {
  const SyncServerRequested({
    required this.serverId,
    this.forceRefresh = false,
  });

  final String serverId;
  final bool forceRefresh;

  @override
  List<Object?> get props => [serverId, forceRefresh];
}

class SyncProgressUpdated extends SyncEvent {
  const SyncProgressUpdated(this.progress);

  final double progress;

  @override
  List<Object?> get props => [progress];
}

class SyncCompleted extends SyncEvent {
  const SyncCompleted();
}

class SyncFailed extends SyncEvent {
  const SyncFailed(this.errorMessage);

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}

class SyncCancelled extends SyncEvent {
  const SyncCancelled();
}

class AutoSyncToggled extends SyncEvent {
  const AutoSyncToggled(this.enabled);

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

class SyncRetryRequested extends SyncEvent {
  const SyncRetryRequested({this.forceRefresh = false});

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}

// State
enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
}

class SyncState extends Equatable {
  const SyncState({
    required this.status,
    required this.progress,
    required this.autoSyncEnabled,
    this.currentServer,
    this.lastSyncTime,
    this.errorMessage,
  });

  const SyncState.initial()
      : status = SyncStatus.idle,
        progress = 0.0,
        autoSyncEnabled = true,
        currentServer = null,
        lastSyncTime = null,
        errorMessage = null;

  final SyncStatus status;
  final double progress;
  final bool autoSyncEnabled;
  final MusicServer? currentServer;
  final DateTime? lastSyncTime;
  final String? errorMessage;

  bool get isSyncing => status == SyncStatus.syncing;
  bool get isCompleted => status == SyncStatus.completed;
  bool get isFailed => status == SyncStatus.failed;
  bool get isIdle => status == SyncStatus.idle;
  bool get hasError => errorMessage != null;

  SyncState copyWith({
    SyncStatus? status,
    double? progress,
    bool? autoSyncEnabled,
    MusicServer? currentServer,
    DateTime? lastSyncTime,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      currentServer: currentServer ?? this.currentServer,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        progress,
        autoSyncEnabled,
        currentServer,
        lastSyncTime,
        errorMessage,
      ];
}