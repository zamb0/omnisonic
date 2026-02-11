import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/usecases/usecases.dart';

/// ViewModel for managing music library collection state
/// 
/// Handles:
/// - Unified collection display and updates
/// - Smart collections (recently played, recently added)
/// - Collection filtering and search
/// - Sync status and progress
@injectable
class MusicLibraryViewModel extends ChangeNotifier {
  MusicLibraryViewModel(
    this._musicRepository,
    this._syncMusicCollectionUseCase,
    this._searchMusicUseCase,
  ) {
    _initialize();
  }

  final MusicRepository _musicRepository;
  final SyncMusicCollectionUseCase _syncMusicCollectionUseCase;
  final SearchMusicUseCase _searchMusicUseCase;

  StreamSubscription<UnifiedCollection>? _collectionSubscription;

  // State
  UnifiedCollection? _collection;
  List<Track> _recentlyPlayed = [];
  List<Track> _recentlyAdded = [];
  SearchResults? _searchResults;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;
  String _searchQuery = '';

  // Getters
  UnifiedCollection? get collection => _collection;
  List<Track> get tracks => _collection?.tracks ?? [];
  List<Album> get albums => _collection?.albums ?? [];
  List<Artist> get artists => _collection?.artists ?? [];
  List<Track> get recentlyPlayed => _recentlyPlayed;
  List<Track> get recentlyAdded => _recentlyAdded;
  SearchResults? get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  bool get hasCollection => _collection != null && _collection!.isNotEmpty;
  bool get isEmpty => _collection?.isEmpty ?? true;
  int get trackCount => _collection?.uniqueTrackCount ?? 0;
  int get albumCount => _collection?.albumCount ?? 0;
  int get artistCount => _collection?.artistCount ?? 0;
  int get duplicateGroupCount => _collection?.duplicateGroupCount ?? 0;
  DateTime? get lastUpdated => _collection?.lastUpdated;

  void _initialize() {
    print('🎵 MusicLibraryViewModel initialized');
    _subscribeToCollection();
    _loadSmartCollections();
    // Auto sync library on app startup
    _autoSyncOnStartup();
  }

  /// Automatically syncs the library on application startup
  void _autoSyncOnStartup() {
    // Use a short delay to ensure the app is fully initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      print('🔄 Auto-syncing library on startup...');
      syncCollection(forceRefresh: false);
    });
  }

  void _subscribeToCollection() {
    _collectionSubscription = _musicRepository.observeCollection().listen(
      (collection) {
        print('🎵 MusicLibraryViewModel received collection update: ${collection.albums.length} albums, ${collection.artists.length} artists, ${collection.tracks.length} tracks');
        _collection = collection;
        _clearError();
        notifyListeners();
      },
      onError: (error) {
        print('❌ MusicLibraryViewModel collection stream error: $error');
        _setError('Failed to load music collection: $error');
      },
    );
  }

  /// Syncs the music collection from all connected servers
  Future<void> syncCollection({String? serverId, bool forceRefresh = false}) async {
    if (_isSyncing) return;

    _isSyncing = true;
    _clearError();
    notifyListeners();

    try {
      final params = SyncMusicCollectionParams(
        serverId: serverId,
        forceRefresh: forceRefresh,
      );

      final result = await _syncMusicCollectionUseCase(params);
      result.fold(
        (failure) => _setError('Sync failed: ${failure.message}'),
        (collection) {
          _collection = collection;
          _loadSmartCollections(); // Refresh smart collections after sync
        },
      );
    } catch (e) {
      _setError('Unexpected error during sync: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Searches for music across all connected servers
  Future<void> searchMusic(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = null;
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _searchQuery = query;
    _clearError();
    notifyListeners();

    try {
      final params = SearchMusicParams(query: query);
      final result = await _searchMusicUseCase(params);
      
      result.fold(
        (failure) => _setError('Search failed: ${failure.message}'),
        (results) => _searchResults = results,
      );
    } catch (e) {
      _setError('Unexpected error during search: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears the current search results
  void clearSearch() {
    _searchResults = null;
    _searchQuery = '';
    notifyListeners();
  }

  /// Loads smart collections (recently played, recently added)
  Future<void> _loadSmartCollections() async {
    try {
      // Load recently played tracks
      final recentlyPlayedResult = await _musicRepository.getRecentlyPlayed();
      recentlyPlayedResult.fold(
        (failure) => debugPrint('Failed to load recently played: ${failure.message}'),
        (tracks) => _recentlyPlayed = tracks,
      );

      // Load recently added tracks
      final recentlyAddedResult = await _musicRepository.getRecentlyAdded();
      recentlyAddedResult.fold(
        (failure) => debugPrint('Failed to load recently added: ${failure.message}'),
        (tracks) => _recentlyAdded = tracks,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading smart collections: $e');
    }
  }

  /// Refreshes smart collections
  Future<void> refreshSmartCollections() async {
    await _loadSmartCollections();
  }

  /// Filters tracks by various criteria
  Future<List<Track>> filterTracks({
    String? genre,
    int? year,
    String? serverId,
    AudioQuality? minQuality,
  }) async {
    final result = await _musicRepository.filterTracks(
      genre: genre,
      year: year,
      serverId: serverId,
      minQuality: minQuality,
    );

    return result.fold(
      (failure) {
        _setError('Filter failed: ${failure.message}');
        return <Track>[];
      },
      (tracks) => tracks,
    );
  }

  /// Gets tracks for a specific album
  Future<List<Track>> getAlbumTracks(String albumId) async {
    final result = await _musicRepository.getAlbumTracks(albumId);
    return result.fold(
      (failure) {
        _setError('Failed to load album tracks: ${failure.message}');
        return <Track>[];
      },
      (tracks) => tracks,
    );
  }

  /// Gets albums for a specific artist
  Future<List<Album>> getArtistAlbums(String artistId) async {
    final result = await _musicRepository.getArtistAlbums(artistId);
    return result.fold(
      (failure) {
        _setError('Failed to load artist albums: ${failure.message}');
        return <Album>[];
      },
      (albums) => albums,
    );
  }

  /// Gets duplicate groups for deduplication management
  Future<Map<String, List<Track>>> getDuplicateGroups() async {
    final result = await _musicRepository.getDuplicateGroups();
    return result.fold(
      (failure) {
        _setError('Failed to load duplicate groups: ${failure.message}');
        return <String, List<Track>>{};
      },
      (groups) => groups,
    );
  }

  /// Marks tracks as duplicates manually
  Future<void> markAsDuplicates(List<String> trackIds) async {
    final result = await _musicRepository.markAsDuplicates(trackIds);
    result.fold(
      (failure) => _setError('Failed to mark as duplicates: ${failure.message}'),
      (_) => debugPrint('Tracks marked as duplicates successfully'),
    );
  }

  /// Marks tracks as unique (not duplicates)
  Future<void> markAsUnique(List<String> trackIds) async {
    final result = await _musicRepository.markAsUnique(trackIds);
    result.fold(
      (failure) => _setError('Failed to mark as unique: ${failure.message}'),
      (_) => debugPrint('Tracks marked as unique successfully'),
    );
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

  /// DEBUG: Clear all data and resync (for testing unique IDs)
  Future<void> debugClearAndResync() async {
    try {
      _isSyncing = true;
      _errorMessage = null;
      notifyListeners();

      print('🧹 DEBUG: Starting clear and resync...');
      
      final result = await _musicRepository.debugClearAndResync();
      
      result.fold(
        (failure) {
          _errorMessage = failure.message;
          print('❌ DEBUG: Clear and resync failed: $_errorMessage');
        },
        (_) {
          print('✅ DEBUG: Clear and resync completed successfully');
        },
      );
    } catch (e) {
      _errorMessage = 'Debug clear and resync failed: $e';
      print('❌ DEBUG: Clear and resync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _collectionSubscription?.cancel();
    super.dispose();
  }
}