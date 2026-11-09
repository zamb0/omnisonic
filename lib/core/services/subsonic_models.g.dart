// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subsonic_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubsonicResponse<T> _$SubsonicResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => SubsonicResponse<T>(
  subsonicResponse: SubsonicResponseData<T>.fromJson(
    json['subsonic-response'] as Map<String, dynamic>,
    (value) => fromJsonT(value),
  ),
);

Map<String, dynamic> _$SubsonicResponseToJson<T>(
  SubsonicResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'subsonic-response': instance.subsonicResponse.toJson(
    (value) => toJsonT(value),
  ),
};

Map<String, dynamic> _$SubsonicResponseDataToJson<T>(
  SubsonicResponseData<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'status': instance.status,
  'version': instance.version,
  'type': instance.type,
  'serverVersion': instance.serverVersion,
  'error': instance.error,
};

SubsonicError _$SubsonicErrorFromJson(Map<String, dynamic> json) =>
    SubsonicError(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String,
    );

Map<String, dynamic> _$SubsonicErrorToJson(SubsonicError instance) =>
    <String, dynamic>{'code': instance.code, 'message': instance.message};

PingResponse _$PingResponseFromJson(Map<String, dynamic> json) =>
    PingResponse();

Map<String, dynamic> _$PingResponseToJson(PingResponse instance) =>
    <String, dynamic>{};

AlbumsResponse _$AlbumsResponseFromJson(Map<String, dynamic> json) =>
    AlbumsResponse(
      album:
          (json['album'] as List<dynamic>?)
              ?.map((e) => SubsonicAlbum.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$AlbumsResponseToJson(AlbumsResponse instance) =>
    <String, dynamic>{'album': instance.album};

ArtistsResponse _$ArtistsResponseFromJson(Map<String, dynamic> json) =>
    ArtistsResponse(
      index: (json['index'] as List<dynamic>)
          .map((e) => SubsonicArtistIndex.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ArtistsResponseToJson(ArtistsResponse instance) =>
    <String, dynamic>{'index': instance.index};

AlbumResponse _$AlbumResponseFromJson(Map<String, dynamic> json) =>
    AlbumResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      artist: json['artist'] as String,
      artistId: json['artistId'] as String?,
      coverArt: _parseIntFromDynamic(json['coverArt']),
      songCount: _parseRequiredIntFromDynamic(json['songCount']),
      duration: _parseRequiredIntFromDynamic(json['duration']),
      playCount: _parseIntFromDynamic(json['playCount']),
      created: json['created'] == null
          ? null
          : DateTime.parse(json['created'] as String),
      starred: json['starred'] == null
          ? null
          : DateTime.parse(json['starred'] as String),
      year: _parseIntFromDynamic(json['year']),
      genre: json['genre'] as String?,
      song:
          (json['song'] as List<dynamic>?)
              ?.map((e) => SubsonicSong.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$AlbumResponseToJson(AlbumResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'artist': instance.artist,
      'artistId': instance.artistId,
      'coverArt': instance.coverArt,
      'songCount': instance.songCount,
      'duration': instance.duration,
      'playCount': instance.playCount,
      'created': instance.created?.toIso8601String(),
      'starred': instance.starred?.toIso8601String(),
      'year': instance.year,
      'genre': instance.genre,
      'song': instance.song,
    };

SubsonicAlbum _$SubsonicAlbumFromJson(Map<String, dynamic> json) =>
    SubsonicAlbum(
      id: json['id'] as String,
      name: json['name'] as String,
      artist: json['artist'] as String,
      artistId: json['artistId'] as String?,
      coverArt: json['coverArt'] as String?,
      songCount: _parseRequiredIntFromDynamic(json['songCount']),
      duration: _parseRequiredIntFromDynamic(json['duration']),
      playCount: _parseIntFromDynamic(json['playCount']),
      created: json['created'] == null
          ? null
          : DateTime.parse(json['created'] as String),
      starred: json['starred'] == null
          ? null
          : DateTime.parse(json['starred'] as String),
      year: _parseIntFromDynamic(json['year']),
      genre: json['genre'] as String?,
    );

Map<String, dynamic> _$SubsonicAlbumToJson(SubsonicAlbum instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'artist': instance.artist,
      'artistId': instance.artistId,
      'coverArt': instance.coverArt,
      'songCount': instance.songCount,
      'duration': instance.duration,
      'playCount': instance.playCount,
      'created': instance.created?.toIso8601String(),
      'starred': instance.starred?.toIso8601String(),
      'year': instance.year,
      'genre': instance.genre,
    };

SubsonicArtistIndex _$SubsonicArtistIndexFromJson(Map<String, dynamic> json) =>
    SubsonicArtistIndex(
      name: json['name'] as String,
      artist: (json['artist'] as List<dynamic>)
          .map((e) => SubsonicArtist.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SubsonicArtistIndexToJson(
  SubsonicArtistIndex instance,
) => <String, dynamic>{'name': instance.name, 'artist': instance.artist};

SubsonicArtist _$SubsonicArtistFromJson(Map<String, dynamic> json) =>
    SubsonicArtist(
      id: json['id'] as String,
      name: json['name'] as String,
      coverArt: json['coverArt'] as String?,
      albumCount: _parseIntFromDynamic(json['albumCount']),
      starred: json['starred'] == null
          ? null
          : DateTime.parse(json['starred'] as String),
    );

Map<String, dynamic> _$SubsonicArtistToJson(SubsonicArtist instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'coverArt': instance.coverArt,
      'albumCount': instance.albumCount,
      'starred': instance.starred?.toIso8601String(),
    };

SubsonicSong _$SubsonicSongFromJson(Map<String, dynamic> json) => SubsonicSong(
  id: json['id'] as String,
  parent: json['parent'] as String?,
  isDir: json['isDir'] as bool,
  title: json['title'] as String,
  album: json['album'] as String?,
  artist: json['artist'] as String?,
  track: _parseIntFromDynamic(json['track']),
  year: _parseIntFromDynamic(json['year']),
  genre: json['genre'] as String?,
  coverArt: json['coverArt'] as String?,
  size: _parseIntFromDynamic(json['size']),
  contentType: json['contentType'] as String?,
  suffix: json['suffix'] as String?,
  duration: _parseIntFromDynamic(json['duration']),
  bitRate: _parseIntFromDynamic(json['bitRate']),
  path: json['path'] as String?,
  playCount: _parseIntFromDynamic(json['playCount']),
  discNumber: _parseIntFromDynamic(json['discNumber']),
  created: json['created'] == null
      ? null
      : DateTime.parse(json['created'] as String),
  starred: json['starred'] == null
      ? null
      : DateTime.parse(json['starred'] as String),
  albumId: json['albumId'] as String?,
  artistId: json['artistId'] as String?,
  type: json['type'] as String?,
  bookmarkPosition: _parseIntFromDynamic(json['bookmarkPosition']),
  originalWidth: _parseIntFromDynamic(json['originalWidth']),
  originalHeight: _parseIntFromDynamic(json['originalHeight']),
  userRating: _parseIntFromDynamic(json['userRating']),
);

Map<String, dynamic> _$SubsonicSongToJson(SubsonicSong instance) =>
    <String, dynamic>{
      'id': instance.id,
      'parent': instance.parent,
      'isDir': instance.isDir,
      'title': instance.title,
      'album': instance.album,
      'artist': instance.artist,
      'track': instance.track,
      'year': instance.year,
      'genre': instance.genre,
      'coverArt': instance.coverArt,
      'size': instance.size,
      'contentType': instance.contentType,
      'suffix': instance.suffix,
      'duration': instance.duration,
      'bitRate': instance.bitRate,
      'path': instance.path,
      'playCount': instance.playCount,
      'discNumber': instance.discNumber,
      'created': instance.created?.toIso8601String(),
      'starred': instance.starred?.toIso8601String(),
      'albumId': instance.albumId,
      'artistId': instance.artistId,
      'type': instance.type,
      'bookmarkPosition': instance.bookmarkPosition,
      'originalWidth': instance.originalWidth,
      'originalHeight': instance.originalHeight,
      'userRating': instance.userRating,
    };

PlayQueueResponse _$PlayQueueResponseFromJson(Map<String, dynamic> json) =>
    PlayQueueResponse(
      current: json['current'] as String?,
      position: (json['position'] as num?)?.toInt(),
      username: json['username'] as String?,
      changed: json['changed'] == null
          ? null
          : DateTime.parse(json['changed'] as String),
      changedBy: json['changedBy'] as String?,
      entries: (json['entry'] as List<dynamic>?)
          ?.map((e) => SubsonicSong.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlayQueueResponseToJson(PlayQueueResponse instance) =>
    <String, dynamic>{
      'current': instance.current,
      'position': instance.position,
      'username': instance.username,
      'changed': instance.changed?.toIso8601String(),
      'changedBy': instance.changedBy,
      'entry': instance.entries,
    };

PlaylistsResponse _$PlaylistsResponseFromJson(Map<String, dynamic> json) =>
    PlaylistsResponse(
      playlist: (json['playlist'] as List<dynamic>?)
          ?.map((e) => SubsonicPlaylist.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlaylistsResponseToJson(PlaylistsResponse instance) =>
    <String, dynamic>{'playlist': instance.playlist};

SubsonicPlaylist _$SubsonicPlaylistFromJson(Map<String, dynamic> json) =>
    SubsonicPlaylist(
      id: json['id'] as String,
      name: json['name'] as String,
      comment: json['comment'] as String?,
      owner: json['owner'] as String?,
      public: json['public'] as bool?,
      songCount: _parseIntFromDynamic(json['songCount']),
      duration: _parseIntFromDynamic(json['duration']),
      created: json['created'] == null
          ? null
          : DateTime.parse(json['created'] as String),
      changed: json['changed'] == null
          ? null
          : DateTime.parse(json['changed'] as String),
      coverArt: json['coverArt'] as String?,
      readonly: json['readonly'] as bool?,
      entry: (json['entry'] as List<dynamic>?)
          ?.map((e) => SubsonicSong.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SubsonicPlaylistToJson(SubsonicPlaylist instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'comment': instance.comment,
      'owner': instance.owner,
      'public': instance.public,
      'songCount': instance.songCount,
      'duration': instance.duration,
      'created': instance.created?.toIso8601String(),
      'changed': instance.changed?.toIso8601String(),
      'coverArt': instance.coverArt,
      'readonly': instance.readonly,
      'entry': instance.entry,
    };

StarredResponse _$StarredResponseFromJson(Map<String, dynamic> json) =>
    StarredResponse(
      album: (json['album'] as List<dynamic>?)
          ?.map((e) => SubsonicAlbum.fromJson(e as Map<String, dynamic>))
          .toList(),
      artist: (json['artist'] as List<dynamic>?)
          ?.map((e) => SubsonicArtist.fromJson(e as Map<String, dynamic>))
          .toList(),
      song: (json['song'] as List<dynamic>?)
          ?.map((e) => SubsonicSong.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StarredResponseToJson(StarredResponse instance) =>
    <String, dynamic>{
      'album': instance.album,
      'artist': instance.artist,
      'song': instance.song,
    };

Genre _$GenreFromJson(Map<String, dynamic> json) => Genre(
  name: json['value'] as String,
  songCount: (json['songCount'] as num).toInt(),
  albumCount: (json['albumCount'] as num).toInt(),
);

Map<String, dynamic> _$GenreToJson(Genre instance) => <String, dynamic>{
  'value': instance.name,
  'songCount': instance.songCount,
  'albumCount': instance.albumCount,
};

GenresResponse _$GenresResponseFromJson(Map<String, dynamic> json) =>
    GenresResponse(
      genre: (json['genre'] as List<dynamic>)
          .map((e) => Genre.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GenresResponseToJson(GenresResponse instance) =>
    <String, dynamic>{'genre': instance.genre};
