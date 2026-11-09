import 'package:json_annotation/json_annotation.dart';
import '../entities/track.dart';
import '../entities/album.dart';
import '../entities/artist.dart';
import '../entities/audio_quality.dart';
import '../entities/music_server.dart';
import '../entities/genre.dart' as domain;
import '../utils/id_generator.dart';
import 'subsonic_api_client.dart';

part 'subsonic_models.g.dart';

/// Base Subsonic API response wrapper
@JsonSerializable(genericArgumentFactories: true)
class SubsonicResponse<T> {
  @JsonKey(name: 'subsonic-response')
  final SubsonicResponseData<T> subsonicResponse;

  const SubsonicResponse({required this.subsonicResponse});

  factory SubsonicResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$SubsonicResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$SubsonicResponseToJson(this, toJsonT);

  /// Returns true if the response indicates success
  bool get isSuccess => subsonicResponse.status == 'ok';

  /// Returns the error if the response failed
  SubsonicError? get error => subsonicResponse.error;

  /// Returns the data if successful, null otherwise
  T? get data => isSuccess ? subsonicResponse.data : null;
}

/// Subsonic response data container
@JsonSerializable(genericArgumentFactories: true, createFactory: false)
class SubsonicResponseData<T> {
  final String status;
  final String version;
  final String? type;
  final String? serverVersion;
  final SubsonicError? error;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final T? data;

  const SubsonicResponseData({
    required this.status,
    required this.version,
    this.type,
    this.serverVersion,
    this.error,
    this.data,
  });

  factory SubsonicResponseData.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    // Extract the data from the response based on the endpoint
    T? data;
    if (json.containsKey('albumList2')) {
      data = fromJsonT(json['albumList2']);
    } else if (json.containsKey('artists')) {
      data = fromJsonT(json['artists']);
    } else if (json.containsKey('album')) {
      data = fromJsonT(json['album']);
    } else if (json.containsKey('playQueue')) {
      data = fromJsonT(json['playQueue']);
    } else if (json.containsKey('starred2')) {
      data = fromJsonT(json['starred2']);
    } else if (json.containsKey('genres')) {
      data = fromJsonT(json['genres']);
    } else if (json.containsKey('playlists')) {
      data = fromJsonT(json['playlists']);
    } else if (json.containsKey('playlist')) {
      data = fromJsonT(json['playlist']);
    } else if (json['status'] == 'ok') {
      // For ping and other simple responses
      data = fromJsonT(<String, dynamic>{});
    }

    return SubsonicResponseData(
      status: json['status'] as String,
      version: json['version'] as String,
      type: json['type'] as String?,
      serverVersion: json['serverVersion'] as String?,
      error: json['error'] != null
          ? SubsonicError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
      data: data,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$SubsonicResponseDataToJson(this, toJsonT);
}

/// Subsonic API error
@JsonSerializable()
class SubsonicError {
  final int code;
  final String message;

  const SubsonicError({required this.code, required this.message});

  factory SubsonicError.fromJson(Map<String, dynamic> json) =>
      _$SubsonicErrorFromJson(json);

  Map<String, dynamic> toJson() => _$SubsonicErrorToJson(this);
}

/// Ping response (empty response for successful ping)
@JsonSerializable()
class PingResponse {
  const PingResponse();

  factory PingResponse.fromJson(Map<String, dynamic> json) =>
      _$PingResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PingResponseToJson(this);
}

/// Albums list response
@JsonSerializable()
class AlbumsResponse {
  /// Servers omit this key entirely when a page has no albums — which is how
  /// the paging loop finds the end of the list — so it defaults to empty
  /// rather than failing the cast.
  @JsonKey(defaultValue: <SubsonicAlbum>[])
  final List<SubsonicAlbum> album;

  const AlbumsResponse({required this.album});

  factory AlbumsResponse.fromJson(Map<String, dynamic> json) =>
      _$AlbumsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AlbumsResponseToJson(this);
}

/// Artists list response
@JsonSerializable()
class ArtistsResponse {
  final List<SubsonicArtistIndex> index;

  const ArtistsResponse({required this.index});

  factory ArtistsResponse.fromJson(Map<String, dynamic> json) =>
      _$ArtistsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ArtistsResponseToJson(this);
}

/// Album details response
@JsonSerializable()
class AlbumResponse {
  final String id;
  final String name;
  final String artist;
  final String? artistId;
  @JsonKey(fromJson: _parseIntFromDynamic)
  final int? coverArt;
  @JsonKey(fromJson: _parseRequiredIntFromDynamic)
  final int songCount;
  @JsonKey(fromJson: _parseRequiredIntFromDynamic)
  final int duration;
  @JsonKey(fromJson: _parseIntFromDynamic)
  final int? playCount;
  final DateTime? created;
  final DateTime? starred;
  @JsonKey(fromJson: _parseIntFromDynamic)
  final int? year;
  final String? genre;

  /// Albums with no songs come back without this key.
  @JsonKey(defaultValue: <SubsonicSong>[])
  final List<SubsonicSong> song;

  const AlbumResponse({
    required this.id,
    required this.name,
    required this.artist,
    this.artistId,
    this.coverArt,
    required this.songCount,
    required this.duration,
    this.playCount,
    this.created,
    this.starred,
    this.year,
    this.genre,
    required this.song,
  });

  factory AlbumResponse.fromJson(Map<String, dynamic> json) =>
      _$AlbumResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AlbumResponseToJson(this);
}

/// Subsonic album model
@JsonSerializable()
class SubsonicAlbum {
  final String id;
  final String name;
  final String artist;
  final String? artistId;
  final String? coverArt;
  @JsonKey(fromJson: _parseRequiredIntFromDynamic)
  final int songCount;
  @JsonKey(fromJson: _parseRequiredIntFromDynamic)
  final int duration;
  @JsonKey(fromJson: _parseIntFromDynamic)
  final int? playCount;
  final DateTime? created;
  final DateTime? starred;
  @JsonKey(fromJson: _parseIntFromDynamic)
  final int? year;
  final String? genre;

  const SubsonicAlbum({
    required this.id,
    required this.name,
    required this.artist,
    this.artistId,
    this.coverArt,
    required this.songCount,
    required this.duration,
    this.playCount,
    this.created,
    this.starred,
    this.year,
    this.genre,
  });

  factory SubsonicAlbum.fromJson(Map<String, dynamic> json) =>
      _$SubsonicAlbumFromJson(json);

  Map<String, dynamic> toJson() => _$SubsonicAlbumToJson(this);

  /// Converts to domain Album entity
  Album toDomainAlbum(
    String serverId,
    MusicServer server,
    String password,
    SubsonicApiClient apiClient,
  ) {
    String? coverArtUrl;
    if (coverArt != null && coverArt!.isNotEmpty) {
      coverArtUrl = apiClient.getCoverArtUrl(server, password, coverArt!);
    }

    return Album(
      id: IdGenerator.generateUniqueId(serverId, id), // Generate unique ID
      title: name,
      artist: artist,
      serverId: serverId,
      lastModified: created ?? DateTime.now(),
      artistId: artistId != null
          ? IdGenerator.generateUniqueId(serverId, artistId!)
          : null, // Generate unique artist ID
      year: year,
      genre: genre,
      trackCount: songCount,
      duration: Duration(seconds: duration),
      coverArtUrl: coverArtUrl,
      isStarred: starred != null,
    );
  }
}

/// Subsonic artist index (for grouped artists)
@JsonSerializable()
class SubsonicArtistIndex {
  final String name;
  final List<SubsonicArtist> artist;

  const SubsonicArtistIndex({required this.name, required this.artist});

  factory SubsonicArtistIndex.fromJson(Map<String, dynamic> json) =>
      _$SubsonicArtistIndexFromJson(json);

  Map<String, dynamic> toJson() => _$SubsonicArtistIndexToJson(this);
}

/// Subsonic artist model
@JsonSerializable()
class SubsonicArtist {
  final String id;
  final String name;
  final String? coverArt;
  @JsonKey(fromJson: _parseIntFromDynamic)
  final int? albumCount;
  final DateTime? starred;

  const SubsonicArtist({
    required this.id,
    required this.name,
    this.coverArt,
    this.albumCount,
    this.starred,
  });

  factory SubsonicArtist.fromJson(Map<String, dynamic> json) =>
      _$SubsonicArtistFromJson(json);

  Map<String, dynamic> toJson() => _$SubsonicArtistToJson(this);

  /// Converts to domain Artist entity
  Artist toDomainArtist(
    String serverId,
    MusicServer server,
    String password,
    SubsonicApiClient apiClient,
  ) {
    String? imageUrl;
    if (coverArt != null && coverArt!.isNotEmpty) {
      imageUrl = apiClient.getCoverArtUrl(server, password, coverArt!);
    }

    return Artist(
      id: IdGenerator.generateUniqueId(serverId, id), // Generate unique ID
      name: name,
      serverId: serverId,
      lastModified: DateTime.now(),
      albumCount: albumCount,
      imageUrl: imageUrl,
    );
  }
}

/// Subsonic song/track model
@JsonSerializable()
class SubsonicSong {
  final String id;
  final String? parent;
  final bool isDir;
  final String title;
  final String? album;
  final String? artist;
  @JsonKey(fromJson: _parseIntFromDynamic)
  final int? track;
  @JsonKey(fromJson: _parseIntFromDynamic)
  final int? year;
  final String? genre;
  final String? coverArt;
  @JsonKey(fromJson: _parseIntFromDynamic)
  final int? size;
  final String? contentType;
  final String? suffix;
  @JsonKey(fromJson: _parseIntFromDynamic)
  final int? duration;
  @JsonKey(fromJson: _parseIntFromDynamic)
  final int? bitRate;
  final String? path;
  @JsonKey(fromJson: _parseIntFromDynamic)
  final int? playCount;
  @JsonKey(fromJson: _parseIntFromDynamic)
  final int? discNumber;
  final DateTime? created;
  final DateTime? starred;
  final String? albumId;
  final String? artistId;
  final String? type;
  @JsonKey(fromJson: _parseIntFromDynamic)
  final int? bookmarkPosition;
  @JsonKey(fromJson: _parseIntFromDynamic)
  final int? originalWidth;
  @JsonKey(fromJson: _parseIntFromDynamic)
  final int? originalHeight;

  /// The user's 1-5 star rating, absent when unrated.
  @JsonKey(fromJson: _parseIntFromDynamic)
  final int? userRating;

  const SubsonicSong({
    required this.id,
    this.parent,
    required this.isDir,
    required this.title,
    this.album,
    this.artist,
    this.track,
    this.year,
    this.genre,
    this.coverArt,
    this.size,
    this.contentType,
    this.suffix,
    this.duration,
    this.bitRate,
    this.path,
    this.playCount,
    this.discNumber,
    this.created,
    this.starred,
    this.albumId,
    this.artistId,
    this.type,
    this.bookmarkPosition,
    this.originalWidth,
    this.originalHeight,
    this.userRating,
  });

  factory SubsonicSong.fromJson(Map<String, dynamic> json) =>
      _$SubsonicSongFromJson(json);

  Map<String, dynamic> toJson() => _$SubsonicSongToJson(this);

  /// Converts to domain Track entity
  Track toDomainTrack(
    String serverId,
    String streamUrl,
    MusicServer server,
    String password,
    SubsonicApiClient apiClient,
  ) {
    // Determine audio quality based on bitrate and format
    AudioQuality quality = AudioQuality.medium;
    if (bitRate != null) {
      if (bitRate! >= 320) {
        quality = AudioQuality.high;
      } else if (bitRate! >= 192) {
        quality = AudioQuality.medium;
      } else {
        quality = AudioQuality.low;
      }
    }

    // Override quality for lossless formats
    if (suffix?.toLowerCase() == 'flac' ||
        contentType?.contains('flac') == true) {
      quality = AudioQuality.lossless;
    }

    // Generate cover art URL if available
    String? coverArtUrl;
    if (coverArt != null && coverArt!.isNotEmpty) {
      coverArtUrl = apiClient.getCoverArtUrl(server, password, coverArt!);
    }

    return Track(
      id: IdGenerator.generateUniqueId(serverId, id), // Generate unique ID
      title: title,
      artist: artist ?? 'Unknown Artist',
      album: album ?? 'Unknown Album',
      duration: Duration(seconds: duration ?? 0),
      serverId: serverId,
      streamUrl: streamUrl,
      quality: quality,
      lastModified: created ?? DateTime.now(),
      albumId: albumId != null
          ? IdGenerator.generateUniqueId(serverId, albumId!)
          : null, // Generate unique album ID
      artistId: artistId != null
          ? IdGenerator.generateUniqueId(serverId, artistId!)
          : null, // Generate unique artist ID
      trackNumber: track,
      discNumber: discNumber,
      year: year,
      genre: genre,
      fileSize: size,
      coverArtUrl: coverArtUrl,
      isStarred: starred != null,
    );
  }
}

/// Helper function to parse integers from dynamic values (handles both int and string)
int? _parseIntFromDynamic(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

/// Helper function to parse required integers from dynamic values (handles both int and string)
int _parseRequiredIntFromDynamic(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

/// Play queue response from getPlayQueue endpoint
@JsonSerializable()
class PlayQueueResponse {
  final String? current;
  final int? position;
  final String? username;
  final DateTime? changed;
  final String? changedBy;
  @JsonKey(name: 'entry')
  final List<SubsonicSong>? entries;

  const PlayQueueResponse({
    this.current,
    this.position,
    this.username,
    this.changed,
    this.changedBy,
    this.entries,
  });

  factory PlayQueueResponse.fromJson(Map<String, dynamic> json) =>
      _$PlayQueueResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PlayQueueResponseToJson(this);
}

/// `getPlaylists` response.
@JsonSerializable()
class PlaylistsResponse {
  final List<SubsonicPlaylist>? playlist;

  const PlaylistsResponse({this.playlist});

  factory PlaylistsResponse.fromJson(Map<String, dynamic> json) =>
      _$PlaylistsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistsResponseToJson(this);
}

/// A server playlist, as returned by `getPlaylists` (without [entry]) and
/// `getPlaylist` / `createPlaylist` (with it).
@JsonSerializable()
class SubsonicPlaylist {
  final String id;
  final String name;
  final String? comment;
  final String? owner;
  final bool? public;
  @JsonKey(fromJson: _parseIntFromDynamic)
  final int? songCount;

  /// Total length in seconds.
  @JsonKey(fromJson: _parseIntFromDynamic)
  final int? duration;
  final DateTime? created;
  final DateTime? changed;
  final String? coverArt;

  /// OpenSubsonic: smart playlists and other server-managed ones.
  final bool? readonly;
  final List<SubsonicSong>? entry;

  const SubsonicPlaylist({
    required this.id,
    required this.name,
    this.comment,
    this.owner,
    this.public,
    this.songCount,
    this.duration,
    this.created,
    this.changed,
    this.coverArt,
    this.readonly,
    this.entry,
  });

  factory SubsonicPlaylist.fromJson(Map<String, dynamic> json) =>
      _$SubsonicPlaylistFromJson(json);

  Map<String, dynamic> toJson() => _$SubsonicPlaylistToJson(this);
}

/// Starred content response (albums, artists, songs)
@JsonSerializable()
class StarredResponse {
  final List<SubsonicAlbum>? album;
  final List<SubsonicArtist>? artist;
  final List<SubsonicSong>? song;

  const StarredResponse({this.album, this.artist, this.song});

  factory StarredResponse.fromJson(Map<String, dynamic> json) =>
      _$StarredResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StarredResponseToJson(this);
}

/// Genre information
@JsonSerializable()
class Genre {
  @JsonKey(name: 'value')
  final String name;
  final int songCount;
  final int albumCount;

  const Genre({
    required this.name,
    required this.songCount,
    required this.albumCount,
  });

  factory Genre.fromJson(Map<String, dynamic> json) => _$GenreFromJson(json);

  Map<String, dynamic> toJson() => _$GenreToJson(this);

  /// Converts to domain Genre entity
  domain.Genre toDomain() {
    return domain.Genre(
      name: name,
      songCount: songCount,
      albumCount: albumCount,
    );
  }
}

/// Genres list response
@JsonSerializable()
class GenresResponse {
  final List<Genre> genre;

  const GenresResponse({required this.genre});

  factory GenresResponse.fromJson(Map<String, dynamic> json) =>
      _$GenresResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GenresResponseToJson(this);
}
