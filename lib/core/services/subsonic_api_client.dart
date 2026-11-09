import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../utils/app_log.dart';
import '../entities/music_server.dart';
import '../errors/exceptions.dart';
import 'subsonic_models.dart';

/// Subsonic API client for communicating with Subsonic-compatible servers
class SubsonicApiClient {
  final Dio _dio;

  /// The Subsonic client name (`c`). Each device sets its own (see
  /// DeviceIdentity), which servers record with a saved play queue.
  String clientName = 'Omnisonic';
  final String _apiVersion = '1.16.1';

  SubsonicApiClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
  }

  /// Tests connection to a Subsonic server
  Future<SubsonicResponse<PingResponse>> ping(
    MusicServer server,
    String password,
  ) async {
    try {
      AppLog.info('Testing connection to server');

      final response = await _makeRequest(
        server: server,
        password: password,
        endpoint: 'ping',
      );

      AppLog.info('Connection successful');
      return SubsonicResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => PingResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      AppLog.warn('Connection failed: $e');
      throw _handleException(e);
    }
  }

  /// Gets all albums from the server
  Future<SubsonicResponse<AlbumsResponse>> getAlbums(
    MusicServer server,
    String password, {
    String? type,
    int? size,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;
      if (size != null) queryParams['size'] = size;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _makeRequest(
        server: server,
        password: password,
        endpoint: 'getAlbumList2',
        queryParams: queryParams,
      );

      return SubsonicResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => AlbumsResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Gets all artists from the server
  Future<SubsonicResponse<ArtistsResponse>> getArtists(
    MusicServer server,
    String password,
  ) async {
    try {
      final response = await _makeRequest(
        server: server,
        password: password,
        endpoint: 'getArtists',
      );

      return SubsonicResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ArtistsResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Gets album details including tracks
  Future<SubsonicResponse<AlbumResponse>> getAlbum(
    MusicServer server,
    String password,
    String albumId,
  ) async {
    try {
      final response = await _makeRequest(
        server: server,
        password: password,
        endpoint: 'getAlbum',
        queryParams: {'id': albumId},
      );

      return SubsonicResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => AlbumResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Gets stream URL for a track
  String getStreamUrl(
    MusicServer server,
    String password,
    String trackId, {
    int? maxBitRate,
    String? format,
  }) {
    final salt = _generateSalt();
    final token = _generateToken(password, salt);

    final queryParams = <String, String>{
      'id': trackId,
      'u': server.username,
      't': token,
      's': salt,
      'v': _apiVersion,
      'c': clientName,
      'f': 'json',
    };

    if (maxBitRate != null) queryParams['maxBitRate'] = maxBitRate.toString();
    if (format != null) queryParams['format'] = format;

    final query = queryParams.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    return '${server.apiUrl}/stream?$query';
  }

  /// Gets cover art URL
  String getCoverArtUrl(
    MusicServer server,
    String password,
    String coverArtId, {
    int? size,
  }) {
    final salt = _generateSalt();
    final token = _generateToken(password, salt);

    final queryParams = <String, String>{
      'id': coverArtId,
      'u': server.username,
      't': token,
      's': salt,
      'v': _apiVersion,
      'c': clientName,
    };

    if (size != null) queryParams['size'] = size.toString();

    final query = queryParams.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    return '${server.apiUrl}/getCoverArt?$query';
  }

  /// Scrobbles a track (registers playback at Last.fm or similar service)
  ///
  /// Parameters:
  /// - [trackId]: The ID of the track being played
  /// - [time]: The time (in milliseconds since epoch) at which the song was listened to
  /// - [submission]: Whether this is a "submission" or "now playing" notification
  Future<SubsonicResponse<PingResponse>> scrobble(
    MusicServer server,
    String password,
    String trackId, {
    DateTime? time,
    bool submission = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'id': trackId,
        'submission': submission.toString(),
      };

      if (time != null) {
        queryParams['time'] = time.millisecondsSinceEpoch.toString();
      }

      final response = await _makeRequest(
        server: server,
        password: password,
        endpoint: 'scrobble',
        queryParams: queryParams,
      );

      return SubsonicResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => PingResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Saves the state of the play queue for this user
  ///
  /// Parameters:
  /// - [trackIds]: ID of all tracks in the play queue
  /// - [current]: ID of the currently playing track
  /// - [position]: Current playback position (in milliseconds) of the current track
  Future<SubsonicResponse<PingResponse>> savePlayQueue(
    MusicServer server,
    String password,
    List<String> trackIds, {
    String? current,
    int? position,
  }) async {
    try {
      // Build query params without the trackIds first
      final Map<String, dynamic> baseParams = {};
      if (current != null) baseParams['current'] = current;
      if (position != null) baseParams['position'] = position.toString();

      // Make request with custom handling for multiple 'id' params
      final response = await _makeRequestWithMultipleIds(
        server: server,
        password: password,
        endpoint: 'savePlayQueue',
        ids: trackIds,
        additionalParams: baseParams,
      );

      return SubsonicResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => PingResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Returns the state of the play queue for this user
  Future<SubsonicResponse<PlayQueueResponse>> getPlayQueue(
    MusicServer server,
    String password,
  ) async {
    try {
      final response = await _makeRequest(
        server: server,
        password: password,
        endpoint: 'getPlayQueue',
      );

      return SubsonicResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => PlayQueueResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Stars (favorites) an item
  ///
  /// Parameters:
  /// - [id]: The ID of the track, album, or artist to star
  /// - [albumId]: The ID of the album to star (optional)
  /// - [artistId]: The ID of the artist to star (optional)
  Future<SubsonicResponse<PingResponse>> star(
    MusicServer server,
    String password, {
    String? id,
    String? albumId,
    String? artistId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (id != null) queryParams['id'] = id;
      if (albumId != null) queryParams['albumId'] = albumId;
      if (artistId != null) queryParams['artistId'] = artistId;

      AppLog.info('⭐ Calling star API - server: ${server.name}, id: $id');

      final response = await _makeRequest(
        server: server,
        password: password,
        endpoint: 'star',
        queryParams: queryParams,
      );

      AppLog.debug('Star API response status: ${response.statusCode}');

      return SubsonicResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => PingResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      AppLog.error('Star API error: $e');
      throw _handleException(e);
    }
  }

  /// Unstars (removes from favorites) an item
  ///
  /// Parameters:
  /// - [id]: The ID of the track, album, or artist to unstar
  /// - [albumId]: The ID of the album to unstar (optional)
  /// - [artistId]: The ID of the artist to unstar (optional)
  Future<SubsonicResponse<PingResponse>> unstar(
    MusicServer server,
    String password, {
    String? id,
    String? albumId,
    String? artistId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (id != null) queryParams['id'] = id;
      if (albumId != null) queryParams['albumId'] = albumId;
      if (artistId != null) queryParams['artistId'] = artistId;

      AppLog.info('⭐ Calling unstar API - server: ${server.name}, id: $id');

      final response = await _makeRequest(
        server: server,
        password: password,
        endpoint: 'unstar',
        queryParams: queryParams,
      );

      AppLog.debug('Unstar API response status: ${response.statusCode}');

      return SubsonicResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => PingResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      AppLog.error('Unstar API error: $e');
      throw _handleException(e);
    }
  }

  /// Gets all starred albums, artists, and songs
  /// Returns a [StarredResponse] containing lists of starred items
  Future<SubsonicResponse<StarredResponse>> getStarred2(
    MusicServer server,
    String password,
  ) async {
    try {
      AppLog.info('⭐ Calling getStarred2 API - server: ${server.name}');

      final response = await _makeRequest(
        server: server,
        password: password,
        endpoint: 'getStarred2',
      );

      AppLog.debug('getStarred2 API response status: ${response.statusCode}');

      return SubsonicResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => StarredResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      AppLog.error('getStarred2 API error: $e');
      throw _handleException(e);
    }
  }

  /// Lists the playlists the user can see: their own and other users'
  /// public ones. Entries are not included; see [getPlaylist].
  Future<SubsonicResponse<PlaylistsResponse>> getPlaylists(
    MusicServer server,
    String password,
  ) async {
    try {
      final response = await _makeRequest(
        server: server,
        password: password,
        endpoint: 'getPlaylists',
      );
      return SubsonicResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => PlaylistsResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// One playlist with its entries, in order.
  Future<SubsonicResponse<SubsonicPlaylist>> getPlaylist(
    MusicServer server,
    String password,
    String playlistId,
  ) async {
    try {
      final response = await _makeRequest(
        server: server,
        password: password,
        endpoint: 'getPlaylist',
        queryParams: {'id': playlistId},
      );
      return SubsonicResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => SubsonicPlaylist.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Creates a playlist named [name] holding [songIds], or — with
  /// [playlistId] — replaces that playlist's entries with [songIds].
  ///
  /// Since API 1.14 the server answers with the playlist; older servers send
  /// an empty response, in which case [SubsonicResponse.data] has no entries.
  Future<SubsonicResponse<SubsonicPlaylist?>> createPlaylist(
    MusicServer server,
    String password, {
    String? name,
    String? playlistId,
    List<String> songIds = const [],
  }) async {
    assert(name != null || playlistId != null);
    try {
      final response = await _makeRequestWithRepeatedParams(
        server: server,
        password: password,
        endpoint: 'createPlaylist',
        repeated: {'songId': songIds},
        additionalParams: {'name': ?name, 'playlistId': ?playlistId},
      );
      return SubsonicResponse.fromJson(response.data as Map<String, dynamic>, (
        json,
      ) {
        final map = json as Map<String, dynamic>;
        return map.containsKey('id') ? SubsonicPlaylist.fromJson(map) : null;
      });
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Changes a playlist's details and/or adds and removes entries.
  ///
  /// [songIndexesToRemove] are positions in the playlist as the server has
  /// it, before this call.
  Future<SubsonicResponse<PingResponse>> updatePlaylist(
    MusicServer server,
    String password,
    String playlistId, {
    String? name,
    String? comment,
    bool? isPublic,
    List<String> songIdsToAdd = const [],
    List<int> songIndexesToRemove = const [],
  }) async {
    try {
      final response = await _makeRequestWithRepeatedParams(
        server: server,
        password: password,
        endpoint: 'updatePlaylist',
        repeated: {
          'songIdToAdd': songIdsToAdd,
          'songIndexToRemove': [for (final i in songIndexesToRemove) '$i'],
        },
        additionalParams: {
          'playlistId': playlistId,
          'name': ?name,
          'comment': ?comment,
          if (isPublic != null) 'public': '$isPublic',
        },
      );
      return SubsonicResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => const PingResponse(),
      );
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Deletes a playlist the user owns.
  Future<SubsonicResponse<PingResponse>> deletePlaylist(
    MusicServer server,
    String password,
    String playlistId,
  ) async {
    try {
      final response = await _makeRequest(
        server: server,
        password: password,
        endpoint: 'deletePlaylist',
        queryParams: {'id': playlistId},
      );
      return SubsonicResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => const PingResponse(),
      );
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Sets the user's rating of a song, album or artist: 1-5 stars, or 0 to
  /// remove the rating.
  Future<SubsonicResponse<PingResponse>> setRating(
    MusicServer server,
    String password,
    String id,
    int rating,
  ) async {
    assert(rating >= 0 && rating <= 5);
    try {
      final response = await _makeRequest(
        server: server,
        password: password,
        endpoint: 'setRating',
        queryParams: {'id': id, 'rating': '$rating'},
      );
      return SubsonicResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => const PingResponse(),
      );
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Gets all music genres available on the server
  /// Returns a [GenresResponse] containing a list of genres with their statistics
  Future<SubsonicResponse<GenresResponse>> getGenres(
    MusicServer server,
    String password,
  ) async {
    try {
      AppLog.info('🎵 Calling getGenres API - server: ${server.name}');

      final response = await _makeRequest(
        server: server,
        password: password,
        endpoint: 'getGenres',
      );

      AppLog.debug('getGenres API response status: ${response.statusCode}');

      return SubsonicResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => GenresResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      AppLog.error('getGenres API error: $e');
      throw _handleException(e);
    }
  }

  /// Makes a request to the Subsonic API
  Future<Response> _makeRequest({
    required MusicServer server,
    required String password,
    required String endpoint,
    Map<String, dynamic>? queryParams,
  }) async {
    final salt = _generateSalt();
    final token = _generateToken(password, salt);

    final params = <String, dynamic>{
      'u': server.username,
      't': token,
      's': salt,
      'v': _apiVersion,
      'c': clientName,
      'f': 'json',
      ...?queryParams,
    };

    AppLog.debug('Making request to endpoint: $endpoint');

    try {
      final response = await _dio.get(
        '${server.apiUrl}/$endpoint',
        queryParameters: params,
      );

      AppLog.debug('Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw SubsonicApiException(
          'HTTP ${response.statusCode}: ${response.statusMessage}',
          response.statusCode.toString(),
        );
      }

      // Check if response contains Subsonic error
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final subsonicResponse = data['subsonic-response'];
        if (subsonicResponse is Map<String, dynamic>) {
          final status = subsonicResponse['status'];
          if (status == 'failed') {
            final error = subsonicResponse['error'];
            if (error is Map<String, dynamic>) {
              throw SubsonicApiException(
                error['message'] as String? ?? 'Unknown server error',
                (error['code'] as int?)?.toString(),
              );
            }
          }
        }
      }

      return response;
    } catch (e) {
      AppLog.warn('Request failed: $e');
      rethrow;
    }
  }

  /// Makes a request with multiple values for the same parameter (e.g., multiple 'id' params)
  Future<Response> _makeRequestWithMultipleIds({
    required MusicServer server,
    required String password,
    required String endpoint,
    required List<String> ids,
    Map<String, dynamic>? additionalParams,
  }) => _makeRequestWithRepeatedParams(
    server: server,
    password: password,
    endpoint: endpoint,
    repeated: {'id': ids},
    additionalParams: additionalParams,
  );

  /// Makes a request where each key of [repeated] is sent once per value
  /// (`songId=a&songId=b`), which Dio's query map cannot express.
  Future<Response> _makeRequestWithRepeatedParams({
    required MusicServer server,
    required String password,
    required String endpoint,
    required Map<String, List<String>> repeated,
    Map<String, dynamic>? additionalParams,
  }) async {
    final ids = [for (final values in repeated.values) ...values];
    final salt = _generateSalt();
    final token = _generateToken(password, salt);

    // Build query string manually to support multiple 'id' parameters
    final queryParts = <String>[
      'u=${Uri.encodeComponent(server.username)}',
      't=${Uri.encodeComponent(token)}',
      's=${Uri.encodeComponent(salt)}',
      'v=$_apiVersion',
      'c=${Uri.encodeComponent(clientName)}',
      'f=json',
    ];

    // Repeated parameters, one entry per value
    for (final entry in repeated.entries) {
      for (final value in entry.value) {
        queryParts.add(
          '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(value)}',
        );
      }
    }

    // Add additional parameters
    if (additionalParams != null) {
      for (final entry in additionalParams.entries) {
        queryParts.add(
          '${entry.key}=${Uri.encodeComponent(entry.value.toString())}',
        );
      }
    }

    final queryString = queryParts.join('&');
    final url = '${server.apiUrl}/$endpoint?$queryString';

    AppLog.debug(
      'Making request to endpoint: $endpoint with ${ids.length} IDs',
    );

    try {
      final response = await _dio.get(url);

      AppLog.debug('Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw SubsonicApiException(
          'HTTP ${response.statusCode}: ${response.statusMessage}',
          response.statusCode.toString(),
        );
      }

      // Check if response contains Subsonic error
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final subsonicResponse = data['subsonic-response'];
        if (subsonicResponse is Map<String, dynamic>) {
          final status = subsonicResponse['status'];
          if (status == 'failed') {
            final error = subsonicResponse['error'];
            if (error is Map<String, dynamic>) {
              throw SubsonicApiException(
                error['message'] as String? ?? 'Unknown server error',
                (error['code'] as int?)?.toString(),
              );
            }
          }
        }
      }

      return response;
    } catch (e) {
      AppLog.warn('Request failed: $e');
      rethrow;
    }
  }

  /// Generates a random salt for authentication
  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Generates authentication token using MD5 hash
  String _generateToken(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Handles exceptions and converts them to appropriate types
  Exception _handleException(dynamic error) {
    AppLog.debug('Handling exception: $error');

    if (error is DioException) {
      AppLog.debug('DioException type: ${error.type}');
      AppLog.debug('Status code: ${error.response?.statusCode}');
      AppLog.debug('Message: ${error.message}');

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return NetworkException(
            'Connection timeout - check server URL and network',
          );
        case DioExceptionType.sendTimeout:
          return NetworkException('Send timeout - server may be slow');
        case DioExceptionType.receiveTimeout:
          return NetworkException('Receive timeout - server may be overloaded');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final responseData = error.response?.data;

          if (statusCode == 401) {
            return AuthenticationException('Invalid username or password');
          } else if (statusCode == 404) {
            return NetworkException(
              'Server not found - check URL (should not include /rest)',
            );
          } else if (statusCode == 403) {
            return AuthenticationException(
              'Access forbidden - check user permissions',
            );
          } else if (statusCode != null && statusCode >= 500) {
            return ServerException(
              'Server error ($statusCode) - server may be down',
            );
          } else {
            String message = 'API error';
            if (responseData is String && responseData.isNotEmpty) {
              message += ': $responseData';
            } else if (error.response?.statusMessage != null) {
              message += ': ${error.response!.statusMessage}';
            }
            return SubsonicApiException(message, statusCode?.toString());
          }
        case DioExceptionType.cancel:
          return NetworkException('Request cancelled');
        case DioExceptionType.connectionError:
          String message = 'Connection error';
          if (error.message?.contains('Failed host lookup') == true) {
            message = 'Cannot resolve server address - check URL';
          } else if (error.message?.contains('Connection refused') == true) {
            message = 'Connection refused - server may be down or wrong port';
          } else if (error.message?.contains('Certificate') == true) {
            message = 'SSL certificate error - try HTTP instead of HTTPS';
          } else if (error.message != null) {
            message += ': ${error.message}';
          }
          return NetworkException(message);
        case DioExceptionType.badCertificate:
          return NetworkException(
            'SSL certificate error - server certificate invalid',
          );
        case DioExceptionType.unknown:
          return NetworkException(
            'Network error: ${error.message ?? 'Unknown error'}',
          );
      }
    } else if (error is SubsonicApiException) {
      return error;
    } else {
      return UnknownException('Unexpected error: $error');
    }
  }
}
