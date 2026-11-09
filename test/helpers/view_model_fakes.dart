import 'package:flutter/foundation.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/repositories/music_repository.dart';
import 'package:omnisonic/core/repositories/playback_repository.dart';
import 'package:omnisonic/core/usecases/search_music_use_case.dart';
import 'package:omnisonic/features/music/presentation/viewmodels/music_library_view_model.dart';
import 'package:omnisonic/features/music/presentation/viewmodels/playlist_view_model.dart';
import 'package:omnisonic/features/playback/presentation/viewmodels/playback_view_model.dart';
import 'package:omnisonic/features/servers/presentation/viewmodels/server_management_view_model.dart';

/// Hand-written stand-ins for the four long-lived `ChangeNotifier` view
/// models the shell and its pages read.
///
/// These are not mocks. Every one extends a real [ChangeNotifier], so
/// `notifyListeners()` fires for real and a test can drive a widget through
/// loading -> error -> data the way the app does. A generated mock stubs
/// `notifyListeners()` into a no-op, which makes state-transition tests
/// silently pass without the widget ever rebuilding.
///
/// Only the getters the UI reads are implemented. Anything else falls
/// through to [noSuchMethod] and throws with the member name, so a page that
/// starts calling a new method fails loudly instead of rendering something
/// subtly wrong.

/// Base class for the fakes: implements the view model's interface but backs
/// only the members declared in the subclass.
mixin _UnimplementedMembers on ChangeNotifier {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = _symbolName(invocation.memberName);
    throw UnimplementedError(
      '$runtimeType.$name is not faked. Add it to test/helpers/'
      'view_model_fakes.dart if the widget under test needs it.',
    );
  }

  static String _symbolName(Symbol symbol) {
    final text = symbol.toString();
    // Symbol("foo") -> foo
    final match = RegExp(r'Symbol\("([^"]*)"\)').firstMatch(text);
    return match?.group(1) ?? text;
  }
}

class FakeMusicLibraryViewModel extends ChangeNotifier
    with _UnimplementedMembers
    implements MusicLibraryViewModel {
  UnifiedCollection? _collection;
  var _recentlyPlayed = <Track>[];
  var _recentlyAdded = <Track>[];
  var _mostPlayed = <Track>[];
  var _recentlyAddedAlbums = <Album>[];
  var _recentlyPlayedAlbums = <Album>[];
  var _mostPlayedAlbums = <Album>[];
  var _starredAlbums = <Album>[];
  var _starredArtists = <Artist>[];
  var _starredTracks = <Track>[];
  final _genres = <Genre>[];
  String? _selectedGenre;
  var _showStarredOnly = false;
  var _isLoading = false;
  var _isSyncing = false;
  String? _errorMessage;
  var _searchQuery = '';

  /// Replaces the whole collection and notifies, the way a finished sync does.
  void emitCollection({
    List<Track> tracks = const [],
    List<Album> albums = const [],
    List<Artist> artists = const [],
    Map<String, List<String>> duplicateGroups = const {},
  }) {
    _collection = UnifiedCollection(
      tracks: tracks,
      albums: albums,
      artists: artists,
      duplicateGroups: duplicateGroups,
      // Relative to now: the shell renders it as "N d ago", so a fixed date
      // made every golden that shows it fail a day after it was recorded.
      lastUpdated: DateTime.now().subtract(const Duration(days: 3)),
    );
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void emitLoading() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  void emitError(String message) {
    _isLoading = false;
    _errorMessage = message;
    notifyListeners();
  }

  void emitSmartCollections({
    List<Track> recentlyPlayed = const [],
    List<Track> recentlyAdded = const [],
    List<Track> mostPlayed = const [],
    List<Album> recentlyAddedAlbums = const [],
    List<Album> recentlyPlayedAlbums = const [],
    List<Album> mostPlayedAlbums = const [],
  }) {
    _recentlyPlayed = recentlyPlayed;
    _recentlyAdded = recentlyAdded;
    _mostPlayed = mostPlayed;
    _recentlyAddedAlbums = recentlyAddedAlbums;
    _recentlyPlayedAlbums = recentlyPlayedAlbums;
    _mostPlayedAlbums = mostPlayedAlbums;
    notifyListeners();
  }

  void emitStarred({
    List<Album> albums = const [],
    List<Artist> artists = const [],
    List<Track> tracks = const [],
  }) {
    _starredAlbums = albums;
    _starredArtists = artists;
    _starredTracks = tracks;
    _isLoading = false;
    notifyListeners();
  }

  void emitSyncing(bool value) {
    _isSyncing = value;
    notifyListeners();
  }

  @override
  UnifiedCollection? get collection => _collection;
  @override
  List<Track> get tracks => _collection?.tracks ?? const [];
  @override
  List<Album> get albums => _collection?.albums ?? const [];
  @override
  List<Artist> get artists => _collection?.artists ?? const [];
  @override
  List<Artist> get allArtists => artists;
  @override
  List<String> artistMemberIds(String artistId) => [artistId];
  @override
  Artist? artistById(String id) => artists.where((a) => a.id == id).firstOrNull;
  @override
  List<Album> get filteredAlbums => albums;
  @override
  List<Track> get recentlyPlayed => _recentlyPlayed;
  @override
  List<Track> get recentlyAdded => _recentlyAdded;
  @override
  List<Track> get mostPlayed => _mostPlayed;
  @override
  List<Album> get recentlyAddedAlbums => _recentlyAddedAlbums;
  @override
  List<Album> get recentlyPlayedAlbums => _recentlyPlayedAlbums;
  @override
  List<Album> get mostPlayedAlbums => _mostPlayedAlbums;
  @override
  List<Album> get starredAlbums => _starredAlbums;
  @override
  List<Artist> get starredArtists => _starredArtists;
  @override
  List<Track> get starredTracks => _starredTracks;
  @override
  List<Genre> get genres => _genres;
  @override
  String? get selectedGenre => _selectedGenre;
  @override
  bool get showStarredOnly => _showStarredOnly;
  @override
  SearchResults? get searchResults => null;
  @override
  bool get isLoading => _isLoading;
  @override
  bool get isSyncing => _isSyncing;
  @override
  String? get errorMessage => _errorMessage;
  @override
  String get searchQuery => _searchQuery;
  @override
  bool get hasCollection => _collection?.isNotEmpty ?? false;
  @override
  bool get isEmpty => _collection?.isEmpty ?? true;
  @override
  int get trackCount => _collection?.uniqueTrackCount ?? 0;
  @override
  int get albumCount => _collection?.albumCount ?? 0;
  @override
  int get artistCount => _collection?.artistCount ?? 0;
  @override
  int get duplicateGroupCount => _collection?.duplicateGroupCount ?? 0;
  @override
  DateTime? get lastUpdated => _collection?.lastUpdated;

  /// Records what the widget asked us to sync, so a test can assert on it
  /// without a repository in the picture.
  var syncCallCount = 0;

  @override
  Future<bool> syncCollection({
    String? serverId,
    bool forceRefresh = false,
  }) async {
    syncCallCount++;
    return true;
  }

  @override
  Future<void> refreshSmartCollections() async {}

  @override
  bool isAlbumStarred(Album album) =>
      album.isStarred || _starredAlbums.any((a) => a.id == album.id);

  @override
  bool isArtistStarred(Artist artist) =>
      _starredArtists.any((a) => a.id == artist.id);

  @override
  bool isTrackStarred(Track track) =>
      _starredTracks.any((t) => t.id == track.id);

  @override
  Future<void> starAlbum(Album album) async {
    _starredAlbums = [..._starredAlbums, album];
    notifyListeners();
  }

  @override
  Future<void> unstarAlbum(Album album) async {
    _starredAlbums = _starredAlbums.where((a) => a.id != album.id).toList();
    notifyListeners();
  }

  @override
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void setGenreFilter(String? genre) {
    _selectedGenre = genre;
    notifyListeners();
  }

  @override
  void setStarredFilter(bool value) {
    _showStarredOnly = value;
    notifyListeners();
  }

  @override
  void toggleStarredFilter() => setStarredFilter(!_showStarredOnly);

  @override
  void clearFilters() {
    _selectedGenre = null;
    _showStarredOnly = false;
    notifyListeners();
  }

  @override
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  @override
  Future<void> searchMusic(String query) async {
    _searchQuery = query;
    notifyListeners();
  }
}

class FakePlaybackViewModel extends ChangeNotifier
    with _UnimplementedMembers
    implements PlaybackViewModel {
  PlaybackState _state = const PlaybackState(
    isPlaying: false,
    currentTrack: null,
    position: Duration.zero,
    duration: Duration.zero,
    queue: [],
    currentIndex: 0,
    repeatMode: RepeatMode.none,
    shuffleEnabled: false,
    volume: 1.0,
  );

  /// Every `playTrack` call, in order, for assertions.
  final playTrackCalls = <({Track track, List<Track> queue, int startIndex})>[];

  void emitState(PlaybackState state) {
    _state = state;
    notifyListeners();
  }

  /// Puts a track on the deck without going through the playback stack.
  void emitPlaying(
    Track track, {
    List<Track> queue = const [],
    int currentIndex = 0,
    bool isPlaying = true,
    Duration position = Duration.zero,
  }) {
    emitState(
      PlaybackState(
        isPlaying: isPlaying,
        currentTrack: track,
        position: position,
        duration: track.duration,
        queue: queue.isEmpty ? [track] : queue,
        currentIndex: currentIndex,
        repeatMode: _state.repeatMode,
        shuffleEnabled: _state.shuffleEnabled,
        volume: _state.volume,
      ),
    );
  }

  @override
  PlaybackState get playbackState => _state;
  @override
  bool get isPlaying => _state.isPlaying;
  @override
  bool get isPaused => _state.isPaused;
  @override
  bool get isStopped => _state.isStopped;
  @override
  Track? get currentTrack => _state.currentTrack;
  @override
  Duration get position => _state.position;
  @override
  Duration get duration => _state.duration;
  @override
  List<Track> get queue => _state.queue;
  @override
  int get currentIndex => _state.currentIndex;
  @override
  RepeatMode get repeatMode => _state.repeatMode;
  @override
  bool get shuffleEnabled => _state.shuffleEnabled;
  @override
  double get volume => _state.volume;
  @override
  bool get hasCurrentTrack => _state.hasCurrentTrack;
  @override
  bool get hasNext => _state.hasNext;
  @override
  bool get hasPrevious => _state.hasPrevious;
  @override
  double get progress => _state.progress;
  @override
  bool get hasQueue => _state.queue.isNotEmpty;
  @override
  int get queueLength => _state.queue.length;
  @override
  bool get isLoading => false;
  @override
  bool get isRestoring => false;
  @override
  String? get errorMessage => null;
  @override
  AudioQuality get currentQuality => AudioQuality.high;
  @override
  AudioQuality get maxQuality => AudioQuality.lossless;
  @override
  double get streamingQualityRatio => 1.0;
  @override
  bool get hasScrobbledCurrentTrack => false;

  @override
  Future<void> playTrack(
    Track track, {
    List<Track>? queue,
    int? startIndex,
    bool useBestSource = true,
    bool allowFallback = true,
  }) async {
    playTrackCalls.add((
      track: track,
      queue: queue ?? [track],
      startIndex: startIndex ?? 0,
    ));
    emitPlaying(track, queue: queue ?? [track], currentIndex: startIndex ?? 0);
  }

  @override
  Future<void> togglePlayPause() async =>
      emitState(_state.copyWith(isPlaying: !_state.isPlaying));

  @override
  Future<void> pause() async => emitState(_state.copyWith(isPlaying: false));

  @override
  Future<void> resume() async => emitState(_state.copyWith(isPlaying: true));

  @override
  Future<void> skipToNext() async {}

  @override
  Future<void> skipToPrevious() async {}

  @override
  Future<void> seek(Duration position) async =>
      emitState(_state.copyWith(position: position));

  @override
  Future<void> setVolume(double volume) async =>
      emitState(_state.copyWith(volume: volume));

  @override
  Future<void> toggleFavorite(Track track) async {}

  @override
  bool isFavoritePending(String trackId) => false;

  @override
  void clearError() {}
}

class FakeServerManagementViewModel extends ChangeNotifier
    with _UnimplementedMembers
    implements ServerManagementViewModel {
  var _servers = <MusicServer>[];
  var _isLoading = false;
  String? _errorMessage;

  void emitServers(List<MusicServer> servers) {
    _servers = servers;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void emitLoading() {
    _isLoading = true;
    notifyListeners();
  }

  void emitError(String message) {
    _isLoading = false;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  List<MusicServer> get servers => _servers;
  @override
  List<MusicServer> get onlineServers =>
      _servers.where((s) => s.status == ServerStatus.online).toList();
  @override
  List<MusicServer> get offlineServers =>
      _servers.where((s) => s.status == ServerStatus.offline).toList();
  @override
  List<MusicServer> get connectingServers =>
      _servers.where((s) => s.status == ServerStatus.connecting).toList();
  @override
  List<MusicServer> get errorServers =>
      _servers.where((s) => s.status == ServerStatus.error).toList();
  @override
  bool get isLoading => _isLoading;
  @override
  bool get isTestingConnection => false;
  @override
  String? get errorMessage => _errorMessage;
  @override
  bool get hasServers => _servers.isNotEmpty;
  @override
  bool get hasOnlineServers => onlineServers.isNotEmpty;
  @override
  int get serverCount => _servers.length;
  @override
  int get onlineServerCount => onlineServers.length;
  @override
  int get offlineServerCount => offlineServers.length;

  @override
  bool isServerLoading(String serverId) => false;

  @override
  MusicServer? getServerById(String serverId) {
    for (final server in _servers) {
      if (server.id == serverId) return server;
    }
    return null;
  }

  @override
  String serverNameFor(String serverId) =>
      getServerById(serverId)?.name ?? serverId;

  @override
  Future<bool> refreshServers() async => true;

  @override
  Future<bool> syncAllServers() async => true;

  @override
  Map<String, int> getServerStatistics() => {
    'total': serverCount,
    'online': onlineServerCount,
    'offline': offlineServerCount,
    'connecting': connectingServers.length,
    'error': errorServers.length,
  };

  @override
  bool get isSyncingAll => false;

  @override
  bool get isSaving => false;

  @override
  String? get actionError => null;

  @override
  void clearActionError() {}

  @override
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

class FakePlaylistViewModel extends ChangeNotifier
    with _UnimplementedMembers
    implements PlaylistViewModel {
  var _playlists = <Playlist>[];
  Playlist? _selectedPlaylist;
  var _selectedPlaylistTracks = <Track>[];
  var _isLoading = false;
  String? _errorMessage;

  void emitPlaylists(List<Playlist> playlists) {
    _playlists = playlists;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void emitSelected(Playlist playlist, {List<Track> tracks = const []}) {
    _selectedPlaylist = playlist;
    _selectedPlaylistTracks = tracks;
    _isLoading = false;
    notifyListeners();
  }

  void emitLoading() {
    _isLoading = true;
    notifyListeners();
  }

  void emitError(String message) {
    _isLoading = false;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  List<Playlist> get playlists => _playlists;
  @override
  List<Playlist> get publicPlaylists =>
      _playlists.where((p) => p.isPublic).toList();
  @override
  List<Playlist> get privatePlaylists =>
      _playlists.where((p) => !p.isPublic).toList();
  @override
  Playlist? get selectedPlaylist => _selectedPlaylist;
  @override
  List<Track> get selectedPlaylistTracks => _selectedPlaylistTracks;
  @override
  List<Playlist> get searchResults => const [];
  @override
  bool get isLoading => _isLoading;

  /// Every `moveTrackInPlaylist` call, for assertions.
  final moveCalls = <(int, int)>[];

  /// Every `createPlaylist` / `updatePlaylist` name, for assertions.
  final savedNames = <String>[];

  @override
  Future<void> selectPlaylist(String playlistId) async {}

  @override
  Future<bool> moveTrackInPlaylist(
    String playlistId,
    int fromIndex,
    int toIndex,
  ) async {
    moveCalls.add((fromIndex, toIndex));
    return true;
  }

  /// The server each `createPlaylist` asked for (null: this device only).
  final createdOnServers = <String?>[];

  @override
  Future<bool> createPlaylist({
    required String name,
    String? description,
    bool isPublic = false,
    String? serverId,
  }) async {
    savedNames.add(name);
    createdOnServers.add(serverId);
    return true;
  }

  @override
  Future<bool> updatePlaylist(Playlist playlist) async {
    savedNames.add(playlist.name);
    return true;
  }

  @override
  void clearSelectedPlaylist() {}

  @override
  bool get isLoadingTracks => false;
  @override
  String? get actionError => null;
  @override
  void clearActionError() {}
  @override
  bool get isOperating => false;
  @override
  String? get errorMessage => _errorMessage;
  @override
  String get searchQuery => '';
  @override
  bool get hasPlaylists => _playlists.isNotEmpty;
  @override
  bool get hasSelectedPlaylist => _selectedPlaylist != null;
  @override
  int get playlistCount => _playlists.length;
  @override
  int get publicPlaylistCount => publicPlaylists.length;
  @override
  int get privatePlaylistCount => privatePlaylists.length;

  @override
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
