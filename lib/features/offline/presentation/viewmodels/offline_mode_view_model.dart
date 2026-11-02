import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/repositories/offline_repository.dart';
import '../../../../core/services/offline_mode_service.dart';
import '../../domain/usecases/manage_offline_mode_use_case.dart';
import '../../domain/services/offline_content_filter.dart';

/// View model for offline mode functionality
@lazySingleton
class OfflineModeViewModel extends ChangeNotifier {
  OfflineModeViewModel({
    required OfflineModeService offlineModeService,
    required ManageOfflineModeUseCase manageOfflineModeUseCase,
    required OfflineRepository offlineRepository,
  }) : _offlineModeService = offlineModeService,
       _manageOfflineModeUseCase = manageOfflineModeUseCase,
       _offlineRepository = offlineRepository {
    _initialize();
  }

  final OfflineModeService _offlineModeService;
  final ManageOfflineModeUseCase _manageOfflineModeUseCase;
  final OfflineRepository _offlineRepository;

  StreamSubscription<bool>? _offlineModeSubscription;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // State
  bool _isOffline = false;
  ConnectivityResult _connectivityType = ConnectivityResult.none;
  NetworkQuality _networkQuality = NetworkQuality.none;
  bool _isLoading = false;
  String? _errorMessage;

  // Offline collection
  List<Track> _offlineTracks = [];
  List<Album> _offlineAlbums = [];
  List<Artist> _offlineArtists = [];
  List<Playlist> _offlinePlaylists = [];
  OfflineCacheStats? _cacheStats;

  // Getters
  bool get isOffline => _isOffline;

  /// Whether the user switched offline mode on themselves, as opposed to
  /// the network being down.
  bool get isForcedOffline => _isForcedOffline;
  bool _isForcedOffline = false;
  ConnectivityResult get connectivityType => _connectivityType;
  NetworkQuality get networkQuality => _networkQuality;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Track> get offlineTracks => List.unmodifiable(_offlineTracks);
  List<Album> get offlineAlbums => List.unmodifiable(_offlineAlbums);
  List<Artist> get offlineArtists => List.unmodifiable(_offlineArtists);
  List<Playlist> get offlinePlaylists => List.unmodifiable(_offlinePlaylists);
  OfflineCacheStats? get cacheStats => _cacheStats;

  // Convenience getters
  bool get hasNetworkConnection => _offlineModeService.hasNetworkConnection;
  bool get isWiFiConnection => _offlineModeService.isWiFiConnection;
  bool get isMeteredConnection => _offlineModeService.isMeteredConnection;
  bool get canStream => _networkQuality.canStream;

  int get offlineTrackCount => _offlineTracks.length;
  int get offlineAlbumCount => _offlineAlbums.length;
  int get offlineArtistCount => _offlineArtists.length;
  int get offlinePlaylistCount => _offlinePlaylists.length;

  bool get hasOfflineContent =>
      _offlineTracks.isNotEmpty ||
      _offlineAlbums.isNotEmpty ||
      _offlineArtists.isNotEmpty ||
      _offlinePlaylists.isNotEmpty;

  /// Initializes the view model
  void _initialize() {
    _subscribeToOfflineMode();
    _subscribeToConnectivity();
    _loadOfflineCollection();
  }

  /// Subscribes to offline mode changes
  void _subscribeToOfflineMode() {
    _offlineModeSubscription = _offlineModeService.offlineModeStream.listen(
      (isOffline) {
        _isOffline = isOffline;
        notifyListeners();

        // Reload offline collection when mode changes
        if (isOffline) {
          _loadOfflineCollection();
        }
      },
      onError: (error) {
        _setError('Offline mode error: $error');
      },
    );
  }

  /// Subscribes to connectivity changes
  void _subscribeToConnectivity() {
    _connectivitySubscription = _offlineModeService.connectivityStream.listen(
      (connectivity) {
        _connectivityType = connectivity;
        _networkQuality = _offlineModeService.networkQuality;
        notifyListeners();
      },
      onError: (error) {
        _setError('Connectivity error: $error');
      },
    );
  }

  /// Loads the offline collection
  Future<void> _loadOfflineCollection() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      final params = const OfflineModeParams(
        action: OfflineModeAction.getOfflineCollection,
      );
      final result = await _manageOfflineModeUseCase(params);

      result.fold(
        (failure) => _setError('Failed to load offline collection: $failure'),
        (value) {
          final collection = value as OfflineCollectionResult;
          _offlineTracks = collection.tracks;
          _offlineAlbums = collection.albums;
          _offlineArtists = collection.artists;
          _offlinePlaylists = collection.playlists;
          _cacheStats = collection.stats;
        },
      );
    } catch (e) {
      _setError('Unexpected error loading offline collection: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refreshes the offline collection
  Future<void> refreshOfflineCollection() async {
    await _loadOfflineCollection();
  }

  /// Checks connectivity manually
  Future<void> checkConnectivity() async {
    _setLoading(true);
    _clearError();

    try {
      final params = const OfflineModeParams(
        action: OfflineModeAction.checkConnectivity,
      );
      final result = await _manageOfflineModeUseCase(params);

      result.fold(
        (failure) => _setError('Failed to check connectivity: $failure'),
        (_) {
          // The connectivity state will be updated via the stream subscription
        },
      );
    } catch (e) {
      _setError('Unexpected error checking connectivity: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sets offline mode manually
  Future<void> setOfflineMode(bool forceOffline) async {
    try {
      final params = OfflineModeParams(
        action: OfflineModeAction.setOfflineMode,
        forceOffline: forceOffline,
      );

      final result = await _manageOfflineModeUseCase(params);

      result.fold(
        (failure) => _setError('Failed to set offline mode: $failure'),
        (_) {
          _isForcedOffline = forceOffline;
          notifyListeners();
        },
      );
    } catch (e) {
      _setError('Unexpected error setting offline mode: $e');
    }
  }

  /// Gets offline statistics
  Future<Map<String, dynamic>?> getOfflineStats() async {
    _setLoading(true);
    _clearError();

    try {
      final params = const OfflineModeParams(
        action: OfflineModeAction.getOfflineStats,
      );
      final result = await _manageOfflineModeUseCase(params);

      return result.fold<Map<String, dynamic>?>((failure) {
        _setError('Failed to get offline stats: $failure');
        return null;
      }, (value) => value as Map<String, dynamic>);
    } catch (e) {
      _setError('Unexpected error getting offline stats: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Filters tracks for offline mode
  List<Track> filterTracksForOffline(List<Track> tracks) {
    if (!_isOffline) return tracks;
    return tracks
        .where((track) => _offlineTracks.any((t) => t.id == track.id))
        .toList();
  }

  /// Filters albums for offline mode
  List<Album> filterAlbumsForOffline(List<Album> albums) {
    if (!_isOffline) return albums;
    return albums
        .where((album) => _offlineAlbums.any((a) => a.id == album.id))
        .toList();
  }

  /// Filters artists for offline mode
  List<Artist> filterArtistsForOffline(List<Artist> artists) {
    if (!_isOffline) return artists;
    return artists
        .where((artist) => _offlineArtists.any((a) => a.id == artist.id))
        .toList();
  }

  /// Filters playlists for offline mode
  List<Playlist> filterPlaylistsForOffline(List<Playlist> playlists) {
    if (!_isOffline) return playlists;
    return playlists
        .where((playlist) => _offlinePlaylists.any((p) => p.id == playlist.id))
        .toList();
  }

  /// Checks if a track is available offline
  bool isTrackAvailableOffline(String trackId) {
    return _offlineTracks.any((track) => track.id == trackId);
  }

  /// Whether a download for [trackId] is currently running.
  bool isTrackDownloading(String trackId) =>
      _offlineRepository.isTrackDownloading(trackId);

  /// Downloads [track] for offline playback.
  ///
  /// Returns the failure message, or null when the download succeeded.
  Future<String?> downloadTrack(Track track) async {
    final result = await _offlineRepository.downloadTrack(track);
    if (result.isFailure) {
      return result.failureOrNull?.message ?? 'Download failed';
    }
    await refreshOfflineCollection();
    return null;
  }

  /// Downloads every track in [tracks], skipping the ones already available.
  ///
  /// Returns the number of tracks that failed.
  Future<int> downloadTracks(List<Track> tracks) async {
    var failures = 0;
    for (final track in tracks) {
      if (isTrackAvailableOffline(track.id)) continue;
      final result = await _offlineRepository.downloadTrack(track);
      if (result.isFailure) failures++;
    }
    await refreshOfflineCollection();
    return failures;
  }

  /// Removes a downloaded track from the local cache.
  Future<String?> removeDownload(String trackId) async {
    final result = await _offlineRepository.removeCachedTrack(trackId);
    if (result.isFailure) {
      return result.failureOrNull?.message ?? 'Could not remove download';
    }
    await refreshOfflineCollection();
    return null;
  }

  /// Checks if an album is available offline
  bool isAlbumAvailableOffline(String albumId) {
    return _offlineAlbums.any((album) => album.id == albumId);
  }

  /// Checks if an artist is available offline
  bool isArtistAvailableOffline(String artistId) {
    return _offlineArtists.any((artist) => artist.id == artistId);
  }

  /// Checks if a playlist is available offline
  bool isPlaylistAvailableOffline(String playlistId) {
    return _offlinePlaylists.any((playlist) => playlist.id == playlistId);
  }

  /// Gets network quality description
  String get networkQualityDescription => _networkQuality.description;

  /// Gets recommended streaming quality for current network
  AudioQuality get recommendedStreamingQuality =>
      _networkQuality.recommendedStreamingQuality;

  /// Sets loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Sets error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clears error message
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _offlineModeSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
