import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/repositories/repositories.dart';
import '../../../../core/usecases/usecases.dart';
import '../../../../core/utils/album_grouping.dart';
import '../../../../core/utils/app_log.dart';
import '../../../../core/utils/artist_grouping.dart';

/// ViewModel for managing music library collection state
///
/// Handles:
/// - Unified collection display and updates
/// - Smart collections (recently played, recently added)
/// - Collection filtering and search
/// - Sync status and progress
@lazySingleton
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
  List<Track> _mostPlayed = [];
  List<Album> _recentlyAddedAlbums = [];
  List<Album> _recentlyPlayedAlbums = [];
  List<Album> _mostPlayedAlbums = [];
  List<Album> _starredAlbums = [];
  List<Artist> _starredArtists = [];
  List<Track> _starredTracks = [];
  List<Genre> _genres = [];
  String? _selectedGenre;
  bool _showStarredOnly = false;
  final Set<String> _starredAlbumIds =
      {}; // Track starred album IDs for immediate UI updates
  // Albums unstarred locally whose server-side starred list has not been
  // reloaded yet; without this an unstar shows no effect until the reload.
  final Set<String> _unstarredAlbumIds = {};
  SearchResults? _searchResults;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;
  String _searchQuery = '';

  // `albums`/`filteredAlbums` are consumed from a Consumer2 build method and
  // previously rebuilt a fresh list (map + dedupe + sort by the caller) on
  // every notifyListeners, including ones that don't touch album data (e.g.
  // sync-progress toggles). Cached here and invalidated only when the inputs
  // that actually feed them change, so unrelated rebuilds reuse the same
  // list instance.
  List<Album>? _albumsCache;
  List<Album>? _filteredAlbumsCache;

  void _invalidateAlbumsCache() {
    _albumsCache = null;
    _filteredAlbumsCache = null;
  }

  // Getters
  UnifiedCollection? get collection => _collection;
  List<Track> get tracks => _collection?.tracks ?? [];

  /// Fetches collection stream observable
  List<Album> get albums {
    if (_albumsCache != null) return _albumsCache!;

    if (_collection?.albums == null) {
      return _albumsCache = const [];
    }

    // Update isStarred status dynamically based on starred albums list
    final starredIds = _starredAlbums.map((a) => a.id).toSet();

    return _albumsCache = _collection!.albums.map((album) {
      final starred =
          !_unstarredAlbumIds.contains(album.id) &&
          (_starredAlbumIds.contains(album.id) ||
              starredIds.contains(album.id));
      return album.isStarred == starred
          ? album
          : album.copyWith(isStarred: starred);
    }).toList();
  }

  /// One entry per artist across servers (see [dedupeArtists]).
  List<Artist> get artists => _artistDedupe.artists;

  /// Every per-server artist before deduplication.
  List<Artist> get allArtists => _collection?.artists ?? [];

  UnifiedCollection? _artistDedupeSource;
  ArtistDedupeResult _artistDedupeCache = (artists: [], memberIds: {});

  ArtistDedupeResult get _artistDedupe {
    final collection = _collection;
    if (collection == null) return (artists: <Artist>[], memberIds: {});
    if (!identical(collection, _artistDedupeSource)) {
      _artistDedupeCache = dedupeArtists(collection.artists, collection.albums);
      _artistDedupeSource = collection;
    }
    return _artistDedupeCache;
  }

  /// IDs of every server's copy of the artist [artistId] belongs to.
  List<String> artistMemberIds(String artistId) {
    for (final ids in _artistDedupe.memberIds.values) {
      if (ids.contains(artistId)) return ids;
    }
    return [artistId];
  }

  /// The deduplicated artist for any copy's ID, so links built from a
  /// non-representative copy still resolve.
  Artist? artistById(String id) {
    final memberIds = artistMemberIds(id);
    return artists.where((a) => memberIds.contains(a.id)).firstOrNull;
  }
  List<Track> get recentlyPlayed => _recentlyPlayed;
  List<Track> get recentlyAdded => _recentlyAdded;
  List<Track> get mostPlayed => _mostPlayed;
  List<Album> get recentlyAddedAlbums => _recentlyAddedAlbums;
  List<Album> get recentlyPlayedAlbums => _recentlyPlayedAlbums;
  List<Album> get mostPlayedAlbums => _mostPlayedAlbums;
  List<Album> get starredAlbums => _starredAlbums;
  List<Artist> get starredArtists => _starredArtists;
  List<Track> get starredTracks => _starredTracks;
  List<Genre> get genres => _genres;
  String? get selectedGenre => _selectedGenre;
  bool get showStarredOnly => _showStarredOnly;
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
    AppLog.debug('MusicLibraryViewModel initialized');
    _subscribeToCollection();
    _loadSmartCollections();
    // Auto sync library on app startup
    _autoSyncOnStartup();
  }

  /// Automatically syncs the library on application startup
  void _autoSyncOnStartup() {
    // Use a short delay to ensure the app is fully initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      AppLog.info('Auto-syncing library on startup');
      syncCollection(forceRefresh: false);
    });
  }

  void _subscribeToCollection() {
    _collectionSubscription = _musicRepository.observeCollection().listen(
      (collection) {
        AppLog.debug(
          'Collection update: ${collection.albums.length} albums, ${collection.artists.length} artists, ${collection.tracks.length} tracks',
        );
        _collection = collection;
        _invalidateAlbumsCache();
        _clearError();
        notifyListeners();
      },
      onError: (error) {
        AppLog.warn('Collection stream error: $error');
        AppLog.error('Collection stream error: $error');
        _setError("Couldn't load your library. Pull down to try again.");
      },
    );
  }

  /// Syncs the music collection from all connected servers.
  ///
  /// Returns whether the sync succeeded, so callers can show a terminal
  /// success/error message (with retry) instead of leaving the user with
  /// just the initial "Syncing..." toast.
  Future<bool> syncCollection({
    String? serverId,
    bool forceRefresh = false,
  }) async {
    if (_isSyncing) return false;

    _isSyncing = true;
    _clearError();
    notifyListeners();

    var success = false;
    try {
      final params = SyncMusicCollectionParams(
        serverId: serverId,
        forceRefresh: forceRefresh,
      );

      final result = await _syncMusicCollectionUseCase(params);
      result.fold(
        (failure) {
          if (failure is NoServersFailure) return;
          _setError(describeFailure(failure, action: 'sync your library'));
        },
        (collection) {
          _collection = collection;
          _invalidateAlbumsCache();
          success = true;
          _loadSmartCollections(); // Refresh smart collections after sync
        },
      );
    } catch (e) {
      AppLog.error('Sync failed: $e');
      _setError(describeUnexpected(action: 'sync your library'));
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
    return success;
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
        (failure) => _setError(describeFailure(failure, action: 'search')),
        (results) => _searchResults = results,
      );
    } catch (e) {
      AppLog.error('Search failed: $e');
      _setError(describeUnexpected(action: 'search'));
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

  /// Loads smart collections (recently played, recently added, most played)
  Future<void> _loadSmartCollections() async {
    try {
      // These are ten independent repository calls, most of which fan out to
      // every server; awaiting them one after another made the home feed wait
      // for the slowest chain of round-trips.
      final results = await Future.wait([
        _musicRepository.getRecentlyPlayed(),
        _musicRepository.getRecentlyAdded(),
        _musicRepository.getMostPlayed(),
        _musicRepository.getRecentlyAddedAlbums(),
        _musicRepository.getRecentlyPlayedAlbums(),
        _musicRepository.getMostPlayedAlbums(),
        _musicRepository.getStarredAlbums(),
        _musicRepository.getStarredArtists(),
        _musicRepository.getStarredTracks(),
        _musicRepository.getGenres(),
      ]);

      void take<T>(int index, String label, void Function(T value) assign) {
        (results[index] as Result<T>).fold(
          (failure) => AppLog.warn('Failed to load $label: ${failure.message}'),
          assign,
        );
      }

      take<List<Track>>(0, 'recently played', (v) => _recentlyPlayed = v);
      take<List<Track>>(1, 'recently added', (v) => _recentlyAdded = v);
      take<List<Track>>(2, 'most played', (v) => _mostPlayed = v);
      take<List<Album>>(
        3,
        'recently added albums',
        (v) => _recentlyAddedAlbums = v,
      );
      take<List<Album>>(
        4,
        'recently played albums',
        (v) => _recentlyPlayedAlbums = v,
      );
      take<List<Album>>(5, 'most played albums', (v) => _mostPlayedAlbums = v);
      take<List<Album>>(6, 'starred albums', (v) {
        _starredAlbums = v;
        _invalidateAlbumsCache();
      });
      take<List<Artist>>(7, 'starred artists', (v) => _starredArtists = v);
      take<List<Track>>(8, 'starred tracks', (v) => _starredTracks = v);
      take<List<Genre>>(9, 'genres', (v) => _genres = v);

      notifyListeners();
    } catch (e) {
      AppLog.warn('Error loading smart collections: $e');
    }
  }

  /// Reloads just the starred albums, artists and tracks.
  ///
  /// All three come from a single `getStarred2` response per server, so this
  /// is one round-trip rather than the ten of [_loadSmartCollections].
  Future<void> _reloadStarredCollections() async {
    final results = await Future.wait([
      _musicRepository.getStarredAlbums(),
      _musicRepository.getStarredArtists(),
      _musicRepository.getStarredTracks(),
    ]);

    (results[0] as Result<List<Album>>).fold(
      (failure) =>
          AppLog.warn('Failed to load starred albums: ${failure.message}'),
      (albums) {
        // The server's list now reflects every completed star/unstar, so the
        // optimistic overrides are no longer needed.
        _starredAlbums = albums;
        _starredAlbumIds.clear();
        _unstarredAlbumIds.clear();
        _invalidateAlbumsCache();
      },
    );
    (results[1] as Result<List<Artist>>).fold(
      (failure) =>
          AppLog.warn('Failed to load starred artists: ${failure.message}'),
      (artists) => _starredArtists = artists,
    );
    (results[2] as Result<List<Track>>).fold(
      (failure) =>
          AppLog.warn('Failed to load starred tracks: ${failure.message}'),
      (tracks) => _starredTracks = tracks,
    );

    notifyListeners();
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

    return result.fold((failure) {
      _setError(describeFailure(failure, action: 'filter your library'));
      return <Track>[];
    }, (tracks) => tracks);
  }

  /// Gets tracks for a specific album
  Future<List<Track>> getAlbumTracks(String albumId) async {
    final result = await _musicRepository.getAlbumTracks(albumId);
    return result.fold((failure) {
      _setError(describeFailure(failure, action: 'load album tracks'));
      return <Track>[];
    }, (tracks) => tracks);
  }

  /// Gets albums for a specific artist
  ///
  /// Across every server's copy of the artist, with an album shared by two
  /// servers listed once.
  Future<List<Album>> getArtistAlbums(String artistId) async {
    final albums = <Album>[];
    for (final id in artistMemberIds(artistId)) {
      final result = await _musicRepository.getArtistAlbums(id);
      result.fold(
        (failure) =>
            _setError(describeFailure(failure, action: 'load artist albums')),
        albums.addAll,
      );
    }
    return dedupeAlbumsByServer(albums).albums;
  }

  /// Gets tracks for a specific artist.
  ///
  /// Falls back to walking the artist's albums for servers that do not tag
  /// songs with an artist ID.
  Future<List<Track>> getArtistTracks(String artistId) async {
    final tracks = <Track>[];
    for (final id in artistMemberIds(artistId)) {
      final result = await _musicRepository.getArtistTracks(id);
      result.fold(
        (failure) =>
            _setError(describeFailure(failure, action: 'load artist tracks')),
        tracks.addAll,
      );
    }

    if (tracks.isNotEmpty) return tracks;

    final albums = await getArtistAlbums(artistId);
    final fromAlbums = <Track>[];
    for (final album in albums) {
      fromAlbums.addAll(await getAlbumTracks(album.id));
    }
    return fromAlbums;
  }

  /// Gets duplicate groups for deduplication management
  Future<Map<String, List<Track>>> getDuplicateGroups() async {
    final result = await _musicRepository.getDuplicateGroups();
    return result.fold((failure) {
      _setError(describeFailure(failure, action: 'load duplicate groups'));
      return <String, List<Track>>{};
    }, (groups) => groups);
  }

  /// Marks tracks as duplicates manually
  Future<void> markAsDuplicates(List<String> trackIds) async {
    final result = await _musicRepository.markAsDuplicates(trackIds);
    result.fold(
      (failure) =>
          _setError(describeFailure(failure, action: 'mark as duplicates')),
      (_) => AppLog.info('Tracks marked as duplicates successfully'),
    );
  }

  /// Marks tracks as unique (not duplicates)
  Future<void> markAsUnique(List<String> trackIds) async {
    final result = await _musicRepository.markAsUnique(trackIds);
    result.fold(
      (failure) =>
          _setError(describeFailure(failure, action: 'mark as unique')),
      (_) => AppLog.info('Tracks marked as unique successfully'),
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

  /// Sets the selected genre filter
  void setGenreFilter(String? genre) {
    if (_selectedGenre != genre) {
      _selectedGenre = genre;
      _filteredAlbumsCache = null;
      notifyListeners();
    }
  }

  /// Toggles the starred-only filter
  void toggleStarredFilter() {
    _showStarredOnly = !_showStarredOnly;
    _filteredAlbumsCache = null;
    notifyListeners();
  }

  /// Sets the starred-only filter
  void setStarredFilter(bool value) {
    if (_showStarredOnly != value) {
      _showStarredOnly = value;
      _filteredAlbumsCache = null;
      notifyListeners();
    }
  }

  /// Clears all filters
  void clearFilters() {
    _selectedGenre = null;
    _showStarredOnly = false;
    _filteredAlbumsCache = null;
    notifyListeners();
  }

  /// Gets filtered albums based on current filter settings
  List<Album> get filteredAlbums {
    if (_filteredAlbumsCache != null) return _filteredAlbumsCache!;

    var result = albums;

    // Apply starred filter - check both local optimistic updates and server data
    if (_showStarredOnly) {
      result = result.where(isAlbumStarred).toList();
    }

    // Apply genre filter
    if (_selectedGenre != null) {
      result = result
          .where(
            (album) =>
                album.genre?.toLowerCase() == _selectedGenre?.toLowerCase(),
          )
          .toList();
    }

    return _filteredAlbumsCache = result;
  }

  /// Gets filtered artists based on current filter settings
  List<Artist> get filteredArtists {
    if (_showStarredOnly) {
      // Check both local optimistic updates and server data
      final starredIds = _starredArtists.map((a) => a.id).toSet();
      return artists
          .where(
            (artist) =>
                _starredAlbumIds.contains(artist.id) ||
                starredIds.contains(artist.id),
          )
          .toList();
    }

    return artists;
  }

  /// Gets filtered tracks based on current filter settings
  List<Track> get filteredTracks {
    var result = tracks;

    // Apply starred filter - check both local optimistic updates and server data
    if (_showStarredOnly) {
      final starredIds = _starredTracks.map((t) => t.id).toSet();
      result = result
          .where(
            (track) =>
                _starredAlbumIds.contains(track.id) ||
                starredIds.contains(track.id),
          )
          .toList();
    }

    // Apply genre filter
    if (_selectedGenre != null) {
      result = result
          .where(
            (track) =>
                track.genre?.toLowerCase() == _selectedGenre?.toLowerCase(),
          )
          .toList();
    }

    return result;
  }

  /// Checks if an album is starred (includes both optimistic updates and server data)
  bool isAlbumStarred(Album album) {
    if (_unstarredAlbumIds.contains(album.id)) return false;
    return _starredAlbumIds.contains(album.id) || album.isStarred;
  }

  /// Checks if an artist is starred (includes both optimistic updates and server data)
  bool isArtistStarred(Artist artist) {
    return _starredArtists.any((a) => a.id == artist.id);
  }

  /// Checks if a track is starred (includes both optimistic updates and server data)
  bool isTrackStarred(Track track) {
    return _starredTracks.any((t) => t.id == track.id);
  }

  /// Stars an album (adds to favorites)
  Future<void> starAlbum(Album album) async {
    try {
      // Optimistic update: add to starred immediately for instant UI feedback
      _starredAlbumIds.add(album.id);
      _unstarredAlbumIds.remove(album.id);
      _invalidateAlbumsCache();
      notifyListeners();

      final result = await _musicRepository.starAlbum(album.id);

      if (result.isRight()) {
        // Only the starred lists can have changed — reloading all ten smart
        // collections here meant one star tap re-ran the whole home feed.
        await _reloadStarredCollections();
        AppLog.info('Successfully starred album: ${album.title}');
      } else {
        // Revert optimistic update on failure
        _starredAlbumIds.remove(album.id);
        _invalidateAlbumsCache();
        final failure = result.fold((f) => f, (v) => null);
        _setError(
          failure != null
              ? describeFailure(failure, action: 'star the album')
              : describeUnexpected(action: 'star the album'),
        );
        AppLog.warn('Star album failure: ${failure?.message}');
      }
      notifyListeners();
    } catch (e) {
      // Revert optimistic update on error
      _starredAlbumIds.remove(album.id);
      _invalidateAlbumsCache();
      AppLog.error('Starring an album failed: $e');
      _setError(describeUnexpected(action: 'star the album'));
      AppLog.error('Error starring album: $e');
      notifyListeners();
    }
  }

  /// Unstars an album (removes from favorites)
  Future<void> unstarAlbum(Album album) async {
    try {
      // Optimistic update: remove from starred immediately for instant UI feedback
      _starredAlbumIds.remove(album.id);
      _unstarredAlbumIds.add(album.id);
      _invalidateAlbumsCache();
      notifyListeners();

      final result = await _musicRepository.unstarAlbum(album.id);

      if (result.isRight()) {
        await _reloadStarredCollections();
        AppLog.info('Successfully unstarred album: ${album.title}');
      } else {
        // Revert optimistic update on failure
        _unstarredAlbumIds.remove(album.id);
        _invalidateAlbumsCache();
        final failure = result.fold((f) => f, (v) => null);
        _setError(
          failure != null
              ? describeFailure(failure, action: 'unstar the album')
              : describeUnexpected(action: 'unstar the album'),
        );
        AppLog.warn('Unstar album failure: ${failure?.message}');
      }
      notifyListeners();
    } catch (e) {
      // Revert optimistic update on error
      _unstarredAlbumIds.remove(album.id);
      _invalidateAlbumsCache();
      AppLog.error('Unstarring an album failed: $e');
      _setError(describeUnexpected(action: 'unstar the album'));
      AppLog.error('Error unstarring album: $e');
      notifyListeners();
    }
  }

  /// DEBUG: Clear all data and resync (for testing unique IDs)
  Future<void> debugClearAndResync() async {
    if (!kDebugMode) {
      _setError('Debug operation not available in release builds');
      return;
    }

    try {
      _isSyncing = true;
      _errorMessage = null;
      notifyListeners();

      AppLog.debug('Starting debug clear and resync');

      final result = await _musicRepository.debugClearAndResync();

      result.fold(
        (failure) {
          _errorMessage = failure.message;
          AppLog.warn('Debug clear and resync failed: $_errorMessage');
        },
        (_) {
          AppLog.info('Debug clear and resync completed successfully');
        },
      );
    } catch (e) {
      _errorMessage = 'Debug clear and resync failed: $e';
      AppLog.warn('Debug clear and resync error: $e');
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
