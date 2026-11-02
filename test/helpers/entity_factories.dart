import 'package:omnisonic/core/entities/entities.dart';

/// Builders for the domain entities the UI renders.
///
/// Every field a widget reads has a plausible default so a test only has to
/// name the one or two values it actually cares about. IDs follow the
/// `{serverId}_{subsonicId}` convention `IdGenerator` produces, since some
/// widgets split on it.

Track testTrack({
  String id = 'server1_t1',
  String title = 'Test Track',
  String artist = 'Test Artist',
  String album = 'Test Album',
  String serverId = 'server1',
  Duration duration = const Duration(minutes: 3, seconds: 24),
  AudioQuality quality = AudioQuality.high,
  String? albumId = 'server1_a1',
  String? artistId = 'server1_ar1',
  int? trackNumber = 1,
  String? coverArtUrl,
  bool isStarred = false,
  bool isCached = false,
}) => Track(
  id: id,
  title: title,
  artist: artist,
  album: album,
  duration: duration,
  serverId: serverId,
  streamUrl: 'https://example.test/stream/$id',
  quality: quality,
  lastModified: DateTime(2026, 1, 1),
  albumId: albumId,
  artistId: artistId,
  trackNumber: trackNumber,
  coverArtUrl: coverArtUrl,
  isStarred: isStarred,
  isCached: isCached,
);

Album testAlbum({
  String id = 'server1_a1',
  String title = 'Test Album',
  String artist = 'Test Artist',
  String serverId = 'server1',
  String? artistId = 'server1_ar1',
  int? year = 2024,
  int? trackCount = 10,
  Duration? duration = const Duration(minutes: 42),
  String? coverArtUrl,
  bool isStarred = false,
}) => Album(
  id: id,
  title: title,
  artist: artist,
  serverId: serverId,
  lastModified: DateTime(2026, 1, 1),
  artistId: artistId,
  year: year,
  trackCount: trackCount,
  duration: duration,
  coverArtUrl: coverArtUrl,
  isStarred: isStarred,
);

Artist testArtist({
  String id = 'server1_ar1',
  String name = 'Test Artist',
  String serverId = 'server1',
  int? albumCount = 3,
  String? imageUrl,
}) => Artist(
  id: id,
  name: name,
  serverId: serverId,
  lastModified: DateTime(2026, 1, 1),
  albumCount: albumCount,
  imageUrl: imageUrl,
);

MusicServer testServer({
  String id = 'server1',
  String name = 'Test Server',
  String url = 'https://music.example.test',
  String username = 'tester',
  ServerStatus status = ServerStatus.online,
  DateTime? lastSync,
}) => MusicServer(
  id: id,
  name: name,
  url: url,
  username: username,
  status: status,
  createdAt: DateTime(2026, 1, 1),
  lastSync: lastSync,
);

Playlist testPlaylist({
  String id = 'server1_p1',
  String name = 'Test Playlist',
  List<String> trackIds = const ['server1_t1', 'server1_t2'],
  Duration? duration = const Duration(minutes: 12),
  bool isPublic = false,
  String? coverArtUrl,
}) => Playlist(
  id: id,
  name: name,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  trackIds: trackIds,
  duration: duration,
  isPublic: isPublic,
  coverArtUrl: coverArtUrl,
);

/// [count] tracks with distinct ids and titles, for list/virtualization tests.
List<Track> testTracks(int count, {String serverId = 'server1'}) => [
  for (var i = 1; i <= count; i++)
    testTrack(
      id: '${serverId}_t$i',
      title: 'Track $i',
      serverId: serverId,
      trackNumber: i,
    ),
];

/// [count] albums with distinct ids and titles.
List<Album> testAlbums(int count, {String serverId = 'server1'}) => [
  for (var i = 1; i <= count; i++)
    testAlbum(id: '${serverId}_a$i', title: 'Album $i', serverId: serverId),
];

/// [count] artists with distinct ids and names.
List<Artist> testArtists(int count, {String serverId = 'server1'}) => [
  for (var i = 1; i <= count; i++)
    testArtist(id: '${serverId}_ar$i', name: 'Artist $i', serverId: serverId),
];
