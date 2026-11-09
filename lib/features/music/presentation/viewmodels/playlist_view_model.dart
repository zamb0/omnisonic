import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/usecases/usecases.dart';
import '../../../../core/utils/app_log.dart';

/// ViewModel for managing playlist operations and state
///
/// Handles:
/// - Playlist creation, editing, and deletion
/// - Track management within playlists
/// - Playlist search and filtering
/// - Import/export functionality
@lazySingleton
class PlaylistViewModel extends ChangeNotifier {
  PlaylistViewModel(this._playlistRepository, this._managePlaylistUseCase) {
    _initialize();
  }

  final PlaylistRepository _playlistRepository;
  final ManagePlaylistUseCase _managePlaylistUseCase;

  StreamSubscription<List<Playlist>>? _playlistsSubscription;

  // State
  List<Playlist> _playlists = [];
  Playlist? _selectedPlaylist;
  List<Track> _selectedPlaylistTracks = [];
  List<Playlist> _searchResults = [];
  bool _isLoading = false;
  bool _isLoadingTracks = false;
  bool _isOperating = false;
  String? _errorMessage;
  String? _actionError;
  String _searchQuery = '';

  // Getters
  List<Playlist> get playlists => _playlists;
  List<Playlist> get publicPlaylists =>
      _playlists.where((p) => p.isPublic).toList();
  List<Playlist> get privatePlaylists =>
      _playlists.where((p) => !p.isPublic).toList();
  Playlist? get selectedPlaylist => _selectedPlaylist;
  List<Track> get selectedPlaylistTracks => _selectedPlaylistTracks;
  List<Playlist> get searchResults => _searchResults;
  bool get isLoading => _isLoading;

  /// Whether the selected playlist's tracks are still being fetched.
  bool get isLoadingTracks => _isLoadingTracks;
  bool get isOperating => _isOperating;

  /// Why the playlists, or the selected playlist, could not be loaded. A
  /// page-level state: there is nothing to show.
  String? get errorMessage => _errorMessage;

  /// Why the last action (create, delete, reorder, …) failed. Transient:
  /// show it as a snackbar and call [clearActionError]. It never replaces
  /// the page — a failed delete used to swap the whole list for an error
  /// view.
  String? get actionError => _actionError;
  String get searchQuery => _searchQuery;
  bool get hasPlaylists => _playlists.isNotEmpty;
  bool get hasSelectedPlaylist => _selectedPlaylist != null;
  int get playlistCount => _playlists.length;
  int get publicPlaylistCount => publicPlaylists.length;
  int get privatePlaylistCount => privatePlaylists.length;

  void _initialize() {
    _subscribeToPlaylists();
    // What is stored shows straight away; the servers' playlists follow
    // through the subscription once they have been fetched.
    _loadPlaylists().then((_) => _syncFromServers());
  }

  /// Fetches the servers' playlists. Failures are logged by the repository
  /// and do not replace what is already shown.
  Future<void> _syncFromServers() async {
    try {
      await _playlistRepository.syncFromServers();
    } catch (e) {
      AppLog.warn('Playlist sync failed: $e');
    }
  }

  void _subscribeToPlaylists() {
    _playlistsSubscription = _playlistRepository.observePlaylists().listen(
      (playlists) {
        _playlists = playlists;
        _clearError();
        notifyListeners();
      },
      onError: (error) {
        AppLog.error('Playlist stream error: $error');
        _setError("Couldn't load your playlists. Pull to try again.");
      },
    );
  }

  Future<void> _loadPlaylists() async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      final result = await _playlistRepository.getAllPlaylists();
      result.fold(
        (failure) =>
            _setError(describeFailure(failure, action: 'load your playlists')),
        (playlists) => _playlists = playlists,
      );
    } catch (e) {
      AppLog.error('Failed to load playlists: $e');
      _setError(describeUnexpected(action: 'load your playlists'));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new playlist
  ///
  /// [serverId] picks the server it is created on; null keeps it on this
  /// device only.
  Future<bool> createPlaylist({
    required String name,
    String? description,
    bool isPublic = false,
    String? serverId,
  }) async {
    if (_isOperating) return false;

    _isOperating = true;
    _actionError = null;
    notifyListeners();

    try {
      final params = ManagePlaylistParams(
        operation: PlaylistOperation.create,
        name: name,
        description: description,
        isPublic: isPublic,
        serverId: serverId,
      );

      final result = await _managePlaylistUseCase(params);

      return result.fold<bool>(
        (failure) {
          _setActionError(
            describeFailure(failure, action: 'create the playlist'),
          );
          return false;
        },
        (operationResult) {
          if (!operationResult.isSuccess) {
            _setActionError(
              operationResult.message ??
                  describeUnexpected(action: 'create the playlist'),
            );
            return false;
          }
          return true;
        },
      );
    } catch (e) {
      AppLog.error('Playlist operation failed (create playlist): $e');
      _setActionError(describeUnexpected(action: 'create the playlist'));
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Updates an existing playlist
  Future<bool> updatePlaylist(Playlist playlist) async {
    if (_isOperating) return false;

    _isOperating = true;
    _actionError = null;
    notifyListeners();

    try {
      final params = ManagePlaylistParams(
        operation: PlaylistOperation.update,
        playlist: playlist,
      );

      final result = await _managePlaylistUseCase(params);

      return result.fold<bool>(
        (failure) {
          _setActionError(
            describeFailure(failure, action: 'save the playlist'),
          );
          return false;
        },
        (operationResult) {
          if (!operationResult.isSuccess) {
            _setActionError(
              operationResult.message ??
                  describeUnexpected(action: 'save the playlist'),
            );
            return false;
          }

          // Update selected playlist if it's the same one
          if (_selectedPlaylist?.id == playlist.id) {
            _selectedPlaylist = operationResult.playlist;
          }

          return true;
        },
      );
    } catch (e) {
      AppLog.error('Playlist operation failed (update playlist): $e');
      _setActionError(describeUnexpected(action: 'save the playlist'));
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Deletes a playlist
  Future<bool> deletePlaylist(String playlistId) async {
    if (_isOperating) return false;

    _isOperating = true;
    _actionError = null;
    notifyListeners();

    try {
      final params = ManagePlaylistParams(
        operation: PlaylistOperation.delete,
        playlistId: playlistId,
      );

      final result = await _managePlaylistUseCase(params);

      return result.fold<bool>(
        (failure) {
          _setActionError(
            describeFailure(failure, action: 'delete the playlist'),
          );
          return false;
        },
        (operationResult) {
          if (!operationResult.isSuccess) {
            _setActionError(
              operationResult.message ??
                  describeUnexpected(action: 'delete the playlist'),
            );
            return false;
          }

          // Clear selected playlist if it was deleted
          if (_selectedPlaylist?.id == playlistId) {
            _selectedPlaylist = null;
            _selectedPlaylistTracks = [];
          }

          return true;
        },
      );
    } catch (e) {
      AppLog.error('Playlist operation failed (delete playlist): $e');
      _setActionError(describeUnexpected(action: 'delete the playlist'));
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Adds a track to a playlist
  Future<bool> addTrackToPlaylist(String playlistId, String trackId) async {
    if (_isOperating) return false;

    _isOperating = true;
    _actionError = null;
    notifyListeners();

    try {
      final params = ManagePlaylistParams(
        operation: PlaylistOperation.addTrack,
        playlistId: playlistId,
        trackId: trackId,
      );

      final result = await _managePlaylistUseCase(params);

      return result.fold<bool>(
        (failure) {
          _setActionError(describeFailure(failure, action: 'add the track'));
          return false;
        },
        (operationResult) {
          if (!operationResult.isSuccess) {
            _setActionError(
              operationResult.message ??
                  describeUnexpected(action: 'add the track'),
            );
            return false;
          }

          // Update selected playlist if it's the same one
          if (_selectedPlaylist?.id == playlistId) {
            _selectedPlaylist = operationResult.playlist;
            _loadSelectedPlaylistTracks();
          }

          return true;
        },
      );
    } catch (e) {
      AppLog.error('Playlist operation failed (add track to playlist): $e');
      _setActionError(describeUnexpected(action: 'add the track'));
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Removes a track from a playlist
  Future<bool> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  ) async {
    if (_isOperating) return false;

    _isOperating = true;
    _actionError = null;
    notifyListeners();

    try {
      final params = ManagePlaylistParams(
        operation: PlaylistOperation.removeTrack,
        playlistId: playlistId,
        trackId: trackId,
      );

      final result = await _managePlaylistUseCase(params);

      return result.fold<bool>(
        (failure) {
          _setActionError(describeFailure(failure, action: 'remove the track'));
          return false;
        },
        (operationResult) {
          if (!operationResult.isSuccess) {
            _setActionError(
              operationResult.message ??
                  describeUnexpected(action: 'remove the track'),
            );
            return false;
          }

          // Update selected playlist if it's the same one
          if (_selectedPlaylist?.id == playlistId) {
            _selectedPlaylist = operationResult.playlist;
            _loadSelectedPlaylistTracks();
          }

          return true;
        },
      );
    } catch (e) {
      AppLog.error(
        'Playlist operation failed (remove track from playlist): $e',
      );
      _setActionError(describeUnexpected(action: 'remove the track'));
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Reorders tracks in a playlist
  Future<bool> reorderPlaylistTracks(
    String playlistId,
    List<String> trackIds,
  ) async {
    if (_isOperating) return false;

    _isOperating = true;
    _actionError = null;
    notifyListeners();

    try {
      final params = ManagePlaylistParams(
        operation: PlaylistOperation.reorderTracks,
        playlistId: playlistId,
        trackIds: trackIds,
      );

      final result = await _managePlaylistUseCase(params);

      return result.fold<bool>(
        (failure) {
          _setActionError(
            describeFailure(failure, action: 'reorder the playlist'),
          );
          return false;
        },
        (operationResult) {
          if (!operationResult.isSuccess) {
            _setActionError(
              operationResult.message ??
                  describeUnexpected(action: 'reorder the playlist'),
            );
            return false;
          }

          // Update selected playlist if it's the same one
          if (_selectedPlaylist?.id == playlistId) {
            _selectedPlaylist = operationResult.playlist;
            _loadSelectedPlaylistTracks();
          }

          return true;
        },
      );
    } catch (e) {
      AppLog.error('Playlist operation failed (reorder playlist tracks): $e');
      _setActionError(describeUnexpected(action: 'reorder the playlist'));
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Moves a track within a playlist
  /// Moves requests are sent one after another, in the order they were
  /// made, so the server applies them to the same order the UI shows.
  Future<void> _moveQueue = Future.value();

  /// Moves a track within a playlist. [toIndex] is the position after the
  /// track has been taken out, as [SliverReorderableList] reports it.
  ///
  /// Optimistic: the selected playlist's tracks move at once, so the row
  /// stays where it was dropped and a second drag works straight away —
  /// it used to snap back until the round trip finished, and drags made in
  /// that window were ignored. If the server refuses, the tracks are
  /// reloaded from the truth and [actionError] says so.
  Future<bool> moveTrackInPlaylist(
    String playlistId,
    int fromIndex,
    int toIndex,
  ) {
    if (fromIndex == toIndex) return Future.value(true);

    if (_selectedPlaylist?.id == playlistId &&
        fromIndex >= 0 &&
        fromIndex < _selectedPlaylistTracks.length &&
        toIndex >= 0 &&
        toIndex < _selectedPlaylistTracks.length) {
      final tracks = List<Track>.of(_selectedPlaylistTracks);
      tracks.insert(toIndex, tracks.removeAt(fromIndex));
      _selectedPlaylistTracks = tracks;
      _actionError = null;
      notifyListeners();
    }

    final done = _moveQueue.then(
      (_) => _sendMove(playlistId, fromIndex, toIndex),
    );
    _moveQueue = done.then((_) {});
    return done;
  }

  Future<bool> _sendMove(String playlistId, int fromIndex, int toIndex) async {
    Future<bool> fail(String message) async {
      _setActionError(message);
      if (_selectedPlaylist?.id == playlistId) {
        await _loadSelectedPlaylistTracks();
      }
      return false;
    }

    try {
      final result = await _managePlaylistUseCase(
        ManagePlaylistParams(
          operation: PlaylistOperation.moveTrack,
          playlistId: playlistId,
          fromIndex: fromIndex,
          toIndex: toIndex,
        ),
      );
      return await result.fold(
        (failure) => fail(describeFailure(failure, action: 'move the track')),
        (operationResult) {
          if (!operationResult.isSuccess) {
            return fail(
              operationResult.message ??
                  describeUnexpected(action: 'move the track'),
            );
          }
          if (_selectedPlaylist?.id == playlistId &&
              operationResult.playlist != null) {
            _selectedPlaylist = operationResult.playlist;
          }
          return true;
        },
      );
    } catch (e) {
      AppLog.error('Moving a playlist track failed: $e');
      return fail(describeUnexpected(action: 'move the track'));
    }
  }

  /// Duplicates a playlist
  Future<bool> duplicatePlaylist(String playlistId, String newName) async {
    if (_isOperating) return false;

    _isOperating = true;
    _actionError = null;
    notifyListeners();

    try {
      final params = ManagePlaylistParams(
        operation: PlaylistOperation.duplicate,
        playlistId: playlistId,
        name: newName,
      );

      final result = await _managePlaylistUseCase(params);

      return result.fold<bool>(
        (failure) {
          _setActionError(
            describeFailure(failure, action: 'duplicate the playlist'),
          );
          return false;
        },
        (operationResult) {
          if (!operationResult.isSuccess) {
            _setActionError(
              operationResult.message ??
                  describeUnexpected(action: 'duplicate the playlist'),
            );
            return false;
          }

          return true;
        },
      );
    } catch (e) {
      AppLog.error('Playlist operation failed (duplicate playlist): $e');
      _setActionError(describeUnexpected(action: 'duplicate the playlist'));
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Selects a playlist and loads its tracks.
  ///
  /// Completes once the tracks are in, and notifies again at that point —
  /// the detail page used to render "No tracks" because the only notify
  /// happened before the tracks had loaded.
  Future<void> selectPlaylist(String playlistId) async {
    if (_selectedPlaylist?.id != playlistId) {
      _selectedPlaylistTracks = [];
    }
    _isLoadingTracks = true;
    notifyListeners();

    final result = await _playlistRepository.getPlaylistById(playlistId);
    Playlist? playlist;
    result.fold(
      (failure) =>
          _setError(describeFailure(failure, action: 'load this playlist')),
      (found) => playlist = found,
    );
    _selectedPlaylist = playlist;
    if (playlist == null) {
      _selectedPlaylistTracks = [];
      _isLoadingTracks = false;
      notifyListeners();
      return;
    }
    await _loadSelectedPlaylistTracks();
  }

  /// Clears the selected playlist
  void clearSelectedPlaylist() {
    _selectedPlaylist = null;
    _selectedPlaylistTracks = [];
    _isLoadingTracks = false;
    notifyListeners();
  }

  Future<void> _loadSelectedPlaylistTracks() async {
    final playlistId = _selectedPlaylist?.id;
    if (playlistId == null) return;

    _isLoadingTracks = true;
    notifyListeners();
    try {
      final result = await _playlistRepository.getPlaylistTracks(playlistId);
      // A different playlist may have been opened while this was in flight.
      if (_selectedPlaylist?.id != playlistId) return;
      result.fold(
        (failure) => _setError(
          describeFailure(failure, action: "load this playlist's tracks"),
        ),
        (tracks) => _selectedPlaylistTracks = tracks,
      );
    } catch (e) {
      AppLog.error('Failed to load playlist tracks: $e');
      _setError("Couldn't load this playlist's tracks");
    } finally {
      if (_selectedPlaylist?.id == playlistId) {
        _isLoadingTracks = false;
        notifyListeners();
      }
    }
  }

  /// Searches playlists by name
  Future<void> searchPlaylists(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _searchQuery = query;
    _actionError = null;
    notifyListeners();

    try {
      final result = await _playlistRepository.searchPlaylists(query);
      result.fold(
        (failure) => _setActionError(
          describeFailure(failure, action: 'search playlists'),
        ),
        (results) => _searchResults = results,
      );
    } catch (e) {
      AppLog.error('Playlist search failed: $e');
      _setActionError(describeUnexpected(action: 'search playlists'));
    } finally {
      notifyListeners();
    }
  }

  /// Clears the current search results
  void clearSearch() {
    _searchResults = [];
    _searchQuery = '';
    notifyListeners();
  }

  /// Gets recently created playlists
  Future<List<Playlist>> getRecentPlaylists({int limit = 10}) async {
    final result = await _playlistRepository.getRecentPlaylists(limit: limit);
    return result.fold((failure) {
      AppLog.warn('Failed to load recent playlists: ${failure.message}');
      return <Playlist>[];
    }, (playlists) => playlists);
  }

  /// Gets a playlist by ID
  Playlist? getPlaylistById(String playlistId) {
    try {
      return _playlists.firstWhere((playlist) => playlist.id == playlistId);
    } catch (e) {
      return null;
    }
  }

  /// Refreshes the playlist list
  Future<void> refreshPlaylists() async {
    await _syncFromServers();
    await _loadPlaylists();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _setActionError(String message) {
    _actionError = message;
    notifyListeners();
  }

  /// Clears [actionError] once it has been shown.
  void clearActionError() {
    if (_actionError == null) return;
    _actionError = null;
    notifyListeners();
  }

  /// Clears the current error message
  void clearError() {
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _playlistsSubscription?.cancel();
    super.dispose();
  }
}
