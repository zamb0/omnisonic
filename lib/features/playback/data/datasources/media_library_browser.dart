import 'package:audio_service/audio_service.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/repositories/music_repository.dart';
import '../../../../core/repositories/playlist_repository.dart';
import '../../../../core/usecases/play_track_use_case.dart';
import '../../../../core/utils/app_log.dart';

/// Builds the media browse tree exposed to Android Auto (and any other
/// `MediaBrowserService` client) and resolves media IDs back to playback.
///
/// Media IDs are `/`-joined segments, each URI-encoded, so entity IDs that
/// contain `/`, `_` or `|` round-trip safely:
///
/// * `root` — the browsable root ([AudioService.browsableRootId])
/// * `home`, `albums`, `artists`, `playlists` — root tabs (Android Auto shows
///   at most four)
/// * `favorites`, `recent_albums`, `new_albums` — children of `home`
/// * `album/<albumId>`, `artist/<artistId>`, `playlist/<playlistId>`
/// * `t/<context>/<contextId>/<trackId>` — a playable track; the context
///   (`album`, `playlist`, `favorites`, `search`) decides the play queue.
class MediaLibraryBrowser {
  MediaLibraryBrowser({
    required MusicRepository musicRepository,
    required PlaylistRepository playlistRepository,
    required PlayTrackUseCase playTrackUseCase,
  }) : _musicRepository = musicRepository,
       _playlistRepository = playlistRepository,
       _playTrackUseCase = playTrackUseCase;

  final MusicRepository _musicRepository;
  final PlaylistRepository _playlistRepository;
  final PlayTrackUseCase _playTrackUseCase;

  /// Upper bound on list sizes: car head units page poorly through huge lists.
  static const int maxItems = 500;

  static const String home = 'home';
  static const String albums = 'albums';
  static const String artists = 'artists';
  static const String playlists = 'playlists';
  static const String favorites = 'favorites';
  static const String recentAlbums = 'recent_albums';
  static const String newAlbums = 'new_albums';

  // Android Auto content-style hints (MediaConstants).
  static const String _browsableHint =
      'android.media.browse.CONTENT_STYLE_BROWSABLE_HINT';
  static const String _playableHint =
      'android.media.browse.CONTENT_STYLE_PLAYABLE_HINT';
  static const int _styleList = 1;
  static const int _styleGrid = 2;

  /// Extras for the browse root: enables voice/text search and content styles.
  static const Map<String, dynamic> rootExtras = {
    'android.media.browse.SEARCH_SUPPORTED': true,
    'android.media.browse.CONTENT_STYLE_SUPPORTED': true,
    _browsableHint: _styleGrid,
    _playableHint: _styleList,
  };

  static String encodeId(List<String> segments) =>
      segments.map(Uri.encodeComponent).join('/');

  static List<String> decodeId(String mediaId) =>
      mediaId.split('/').map(Uri.decodeComponent).toList();

  static String trackMediaId(
    String context,
    String contextId,
    String trackId,
  ) => encodeId(['t', context, contextId, trackId]);

  /// Returns the children of [parentMediaId], or an empty list when unknown.
  Future<List<MediaItem>> getChildren(String parentMediaId) async {
    try {
      final segments = decodeId(parentMediaId);
      switch (segments.first) {
        case AudioService.browsableRootId:
          return _rootChildren();
        case home:
          return _homeChildren();
        case albums:
          return _albumItems(await _musicRepository.getAllAlbums(), sort: true);
        case artists:
          return _artistItems(await _musicRepository.getAllArtists());
        case playlists:
          return _playlistItems(await _playlistRepository.getAllPlaylists());
        case favorites:
          return _trackItems(
            await _musicRepository.getStarredTracks(),
            favorites,
            '-',
          );
        case recentAlbums:
          return _albumItems(
            await _musicRepository.getRecentlyPlayedAlbums(limit: 30),
          );
        case newAlbums:
          return _albumItems(
            await _musicRepository.getRecentlyAddedAlbums(limit: 30),
          );
        case 'album' when segments.length == 2:
          return _trackItems(
            await _musicRepository.getAlbumTracks(segments[1]),
            'album',
            segments[1],
          );
        case 'artist' when segments.length == 2:
          return _albumItems(
            await _musicRepository.getArtistAlbums(segments[1]),
          );
        case 'playlist' when segments.length == 2:
          return _trackItems(
            await _playlistRepository.getPlaylistTracks(segments[1]),
            'playlist',
            segments[1],
          );
      }
    } catch (e) {
      AppLog.warn('Media browser: getChildren($parentMediaId) failed: $e');
    }
    return const [];
  }

  /// Searches tracks; results are playable with the search as their queue.
  Future<List<MediaItem>> search(String query) async {
    if (query.trim().isEmpty) return const [];
    return _trackItems(
      await _musicRepository.searchTracks(query),
      'search',
      query,
    );
  }

  /// Starts playback for a playable media ID. Returns false when the ID is
  /// not a track or its context could not be loaded.
  Future<bool> playFromMediaId(String mediaId) async {
    final segments = decodeId(mediaId);
    if (segments.length != 4 || segments.first != 't') return false;
    final context = segments[1];
    final contextId = segments[2];
    final trackId = segments[3];

    final queue = await _contextTracks(context, contextId);
    if (queue.isEmpty) return false;
    final index = queue.indexWhere((t) => t.id == trackId);
    if (index < 0) return false;
    return _play(queue, index);
  }

  /// Plays the best match for a voice query ("play X on Omnisonic"). An empty
  /// query plays favorites, as Android Auto's generic "play music" expects.
  Future<bool> playFromSearch(String query) async {
    final queue = query.trim().isEmpty
        ? await _contextTracks(favorites, '-')
        : await _contextTracks('search', query);
    if (queue.isEmpty) return false;
    return _play(queue, 0);
  }

  Future<bool> _play(List<Track> queue, int index) async {
    final result = await _playTrackUseCase(
      PlayTrackParams(track: queue[index], queue: queue, startIndex: index),
    );
    return result.fold((failure) {
      AppLog.warn('Media browser: playback failed: $failure');
      return false;
    }, (_) => true);
  }

  Future<List<Track>> _contextTracks(String context, String contextId) async {
    final Result<List<Track>> result;
    switch (context) {
      case 'album':
        result = await _musicRepository.getAlbumTracks(contextId);
      case 'playlist':
        result = await _playlistRepository.getPlaylistTracks(contextId);
      case favorites:
        result = await _musicRepository.getStarredTracks();
      case 'search':
        result = await _musicRepository.searchTracks(contextId);
      default:
        return const [];
    }
    return _cap(result.valueOrNull ?? const <Track>[]);
  }

  List<MediaItem> _rootChildren() => const [
    MediaItem(id: home, title: 'Home', playable: false),
    MediaItem(
      id: albums,
      title: 'Albums',
      playable: false,
      extras: {_browsableHint: _styleGrid},
    ),
    MediaItem(
      id: artists,
      title: 'Artists',
      playable: false,
      extras: {_browsableHint: _styleList},
    ),
    MediaItem(
      id: playlists,
      title: 'Playlists',
      playable: false,
      extras: {_browsableHint: _styleList},
    ),
  ];

  List<MediaItem> _homeChildren() => const [
    MediaItem(
      id: favorites,
      title: 'Favorite tracks',
      playable: false,
      extras: {_playableHint: _styleList},
    ),
    MediaItem(
      id: recentAlbums,
      title: 'Recently played',
      playable: false,
      extras: {_browsableHint: _styleGrid},
    ),
    MediaItem(
      id: newAlbums,
      title: 'Recently added',
      playable: false,
      extras: {_browsableHint: _styleGrid},
    ),
  ];

  List<MediaItem> _albumItems(Result<List<Album>> result, {bool sort = false}) {
    final list = [...?result.valueOrNull];
    if (sort) {
      list.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    }
    return _cap(list)
        .map(
          (a) => MediaItem(
            id: encodeId(['album', a.id]),
            title: a.title,
            artist: a.artist,
            playable: false,
            artUri: _uri(a.coverArtUrl),
          ),
        )
        .toList();
  }

  List<MediaItem> _artistItems(Result<List<Artist>> result) {
    final list = [...?result.valueOrNull]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return _cap(list)
        .map(
          (a) => MediaItem(
            id: encodeId(['artist', a.id]),
            title: a.name,
            playable: false,
            artUri: _uri(a.imageUrl),
            extras: const {_browsableHint: _styleGrid},
          ),
        )
        .toList();
  }

  List<MediaItem> _playlistItems(Result<List<Playlist>> result) {
    return _cap(result.valueOrNull ?? const <Playlist>[])
        .map(
          (p) => MediaItem(
            id: encodeId(['playlist', p.id]),
            title: p.name,
            playable: false,
            artUri: _uri(p.coverArtUrl),
          ),
        )
        .toList();
  }

  List<MediaItem> _trackItems(
    Result<List<Track>> result,
    String context,
    String contextId,
  ) {
    return _cap(result.valueOrNull ?? const <Track>[])
        .map(
          (t) => MediaItem(
            id: trackMediaId(context, contextId, t.id),
            title: t.title,
            artist: t.artist,
            album: t.album,
            duration: t.duration,
            playable: true,
            artUri: _uri(t.coverArtUrl),
          ),
        )
        .toList();
  }

  static List<T> _cap<T>(List<T> list) =>
      list.length > maxItems ? list.sublist(0, maxItems) : list;

  static Uri? _uri(String? url) =>
      url == null || url.isEmpty ? null : Uri.tryParse(url);
}
