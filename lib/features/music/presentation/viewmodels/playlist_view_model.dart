import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/usecases/usecases.dart';

/// ViewModel for managing playlist operations and state
/// 
/// Handles:
/// - Playlist creation, editing, and deletion
/// - Track management within playlists
/// - Playlist search and filtering
/// - Import/export functionality
@injectable
class PlaylistViewModel extends ChangeNotifier {
  PlaylistViewModel(
    this._playlistRepository,
    this._managePlaylistUseCase,
  ) {
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
  bool _isOperating = false;
  String? _errorMessage;
  String _searchQuery = '';

  // Getters
  List<Playlist> get playlists => _playlists;
  List<Playlist> get publicPlaylists => _playlists.where((p) => p.isPublic).toList();
  List<Playlist> get privatePlaylists => _playlists.where((p) => !p.isPublic).toList();
  Playlist? get selectedPlaylist => _selectedPlaylist;
  List<Track> get selectedPlaylistTracks => _selectedPlaylistTracks;
  List<Playlist> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isOperating => _isOperating;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  bool get hasPlaylists => _playlists.isNotEmpty;
  bool get hasSelectedPlaylist => _selectedPlaylist != null;
  int get playlistCount => _playlists.length;
  int get publicPlaylistCount => publicPlaylists.length;
  int get privatePlaylistCount => privatePlaylists.length;

  void _initialize() {
    _subscribeToPlaylists();
    _loadPlaylists();
  }

  void _subscribeToPlaylists() {
    _playlistsSubscription = _playlistRepository.observePlaylists().listen(
      (playlists) {
        _playlists = playlists;
        _clearError();
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load playlists: $error');
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
        (failure) => _setError('Failed to load playlists: ${failure.message}'),
        (playlists) => _playlists = playlists,
      );
    } catch (e) {
      _setError('Unexpected error loading playlists: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new playlist
  Future<bool> createPlaylist({
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    if (_isOperating) return false;

    _isOperating = true;
    _clearError();
    notifyListeners();

    try {
      final params = ManagePlaylistParams(
        operation: PlaylistOperation.create,
        name: name,
        description: description,
        isPublic: isPublic,
      );

      final result = await _managePlaylistUseCase(params);
      
      return result.fold(
        (failure) {
          _setError('Failed to create playlist: ${failure.message}');
          return false;
        },
        (operationResult) {
          if (!operationResult.isSuccess) {
            _setError('Failed to create playlist: ${operationResult.message}');
            return false;
          }
          return true;
        },
      );
    } catch (e) {
      _setError('Unexpected error creating playlist: $e');
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
    _clearError();
    notifyListeners();

    try {
      final params = ManagePlaylistParams(
        operation: PlaylistOperation.update,
        playlist: playlist,
      );

      final result = await _managePlaylistUseCase(params);
      
      return result.fold(
        (failure) {
          _setError('Failed to update playlist: ${failure.message}');
          return false;
        },
        (operationResult) {
          if (!operationResult.isSuccess) {
            _setError('Failed to update playlist: ${operationResult.message}');
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
      _setError('Unexpected error updating playlist: $e');
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
    _clearError();
    notifyListeners();

    try {
      final params = ManagePlaylistParams(
        operation: PlaylistOperation.delete,
        playlistId: playlistId,
      );

      final result = await _managePlaylistUseCase(params);
      
      return result.fold(
        (failure) {
          _setError('Failed to delete playlist: ${failure.message}');
          return false;
        },
        (operationResult) {
          if (!operationResult.isSuccess) {
            _setError('Failed to delete playlist: ${operationResult.message}');
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
      _setError('Unexpected error deleting playlist: $e');
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
    _clearError();
    notifyListeners();

    try {
      final params = ManagePlaylistParams(
        operation: PlaylistOperation.addTrack,
        playlistId: playlistId,
        trackId: trackId,
      );

      final result = await _managePlaylistUseCase(params);
      
      return result.fold(
        (failure) {
          _setError('Failed to add track to playlist: ${failure.message}');
          return false;
        },
        (operationResult) {
          if (!operationResult.isSuccess) {
            _setError('Failed to add track to playlist: ${operationResult.message}');
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
      _setError('Unexpected error adding track to playlist: $e');
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Removes a track from a playlist
  Future<bool> removeTrackFromPlaylist(String playlistId, String trackId) async {
    if (_isOperating) return false;

    _isOperating = true;
    _clearError();
    notifyListeners();

    try {
      final params = ManagePlaylistParams(
        operation: PlaylistOperation.removeTrack,
        playlistId: playlistId,
        trackId: trackId,
      );

      final result = await _managePlaylistUseCase(params);
      
      return result.fold(
        (failure) {
          _setError('Failed to remove track from playlist: ${failure.message}');
          return false;
        },
        (operationResult) {
          if (!operationResult.isSuccess) {
            _setError('Failed to remove track from playlist: ${operationResult.message}');
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
      _setError('Unexpected error removing track from playlist: $e');
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Reorders tracks in a playlist
  Future<bool> reorderPlaylistTracks(String playlistId, List<String> trackIds) async {
    if (_isOperating) return false;

    _isOperating = true;
    _clearError();
    notifyListeners();

    try {
      final params = ManagePlaylistParams(
        operation: PlaylistOperation.reorderTracks,
        playlistId: playlistId,
        trackIds: trackIds,
      );

      final result = await _managePlaylistUseCase(params);
      
      return result.fold(
        (failure) {
          _setError('Failed to reorder playlist tracks: ${failure.message}');
          return false;
        },
        (operationResult) {
          if (!operationResult.isSuccess) {
            _setError('Failed to reorder playlist tracks: ${operationResult.message}');
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
      _setError('Unexpected error reordering playlist tracks: $e');
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Moves a track within a playlist
  Future<bool> moveTrackInPlaylist(String playlistId, int fromIndex, int toIndex) async {
    if (_isOperating) return false;

    _isOperating = true;
    _clearError();
    notifyListeners();

    try {
      final params = ManagePlaylistParams(
        operation: PlaylistOperation.moveTrack,
        playlistId: playlistId,
        fromIndex: fromIndex,
        toIndex: toIndex,
      );

      final result = await _managePlaylistUseCase(params);
      
      return result.fold(
        (failure) {
          _setError('Failed to move track in playlist: ${failure.message}');
          return false;
        },
        (operationResult) {
          if (!operationResult.isSuccess) {
            _setError('Failed to move track in playlist: ${operationResult.message}');
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
      _setError('Unexpected error moving track in playlist: $e');
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Duplicates a playlist
  Future<bool> duplicatePlaylist(String playlistId, String newName) async {
    if (_isOperating) return false;

    _isOperating = true;
    _clearError();
    notifyListeners();

    try {
      final params = ManagePlaylistParams(
        operation: PlaylistOperation.duplicate,
        playlistId: playlistId,
        name: newName,
      );

      final result = await _managePlaylistUseCase(params);
      
      return result.fold(
        (failure) {
          _setError('Failed to duplicate playlist: ${failure.message}');
          return false;
        },
        (operationResult) {
          if (!operationResult.isSuccess) {
            _setError('Failed to duplicate playlist: ${operationResult.message}');
            return false;
          }

          return true;
        },
      );
    } catch (e) {
      _setError('Unexpected error duplicating playlist: $e');
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Selects a playlist and loads its tracks
  Future<void> selectPlaylist(String playlistId) async {
    final result = await _playlistRepository.getPlaylistById(playlistId);
    result.fold(
      (failure) => _setError('Failed to load playlist: ${failure.message}'),
      (playlist) {
        _selectedPlaylist = playlist;
        if (playlist != null) {
          _loadSelectedPlaylistTracks();
        } else {
          _selectedPlaylistTracks = [];
        }
        notifyListeners();
      },
    );
  }

  /// Clears the selected playlist
  void clearSelectedPlaylist() {
    _selectedPlaylist = null;
    _selectedPlaylistTracks = [];
    notifyListeners();
  }

  Future<void> _loadSelectedPlaylistTracks() async {
    if (_selectedPlaylist == null) return;

    try {
      final result = await _playlistRepository.getPlaylistTracks(_selectedPlaylist!.id);
      result.fold(
        (failure) => _setError('Failed to load playlist tracks: ${failure.message}'),
        (tracks) => _selectedPlaylistTracks = tracks,
      );
    } catch (e) {
      _setError('Unexpected error loading playlist tracks: $e');
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
    _clearError();
    notifyListeners();

    try {
      final result = await _playlistRepository.searchPlaylists(query);
      result.fold(
        (failure) => _setError('Search failed: ${failure.message}'),
        (results) => _searchResults = results,
      );
    } catch (e) {
      _setError('Unexpected error during search: $e');
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
    return result.fold(
      (failure) {
        _setError('Failed to load recent playlists: ${failure.message}');
        return <Playlist>[];
      },
      (playlists) => playlists,
    );
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
    await _loadPlaylists();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
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