import 'package:drift/drift.dart';

import '../entities/audio_quality.dart';
import '../entities/server_status.dart';

// Servers table
@DataClassName('ServerData')
class ServersTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get url => text()();
  TextColumn get username => text()();
  TextColumn get encryptedPassword => text()();
  TextColumn get status => textEnum<ServerStatus>()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastSync => dateTime().nullable()();
  TextColumn get apiVersion => text().nullable()();
  TextColumn get serverVersion => text().nullable()();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Tracks table
@DataClassName('TrackData')
class TracksTable extends Table {
  TextColumn get id => text()();
  TextColumn get serverId => text().references(ServersTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  TextColumn get album => text()();
  IntColumn get durationMs => integer()();
  TextColumn get streamUrl => text()();
  TextColumn get quality => textEnum<AudioQuality>()();
  DateTimeColumn get lastModified => dateTime()();
  TextColumn get albumId => text().nullable()();
  TextColumn get artistId => text().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get discNumber => integer().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get genre => text().nullable()();
  IntColumn get fileSize => integer().nullable()();
  TextColumn get coverArtUrl => text().nullable()();
  BoolColumn get isCached => boolean().withDefault(const Constant(false))();
  TextColumn get cachePath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Albums table
@DataClassName('AlbumData')
class AlbumsTable extends Table {
  TextColumn get id => text()();
  TextColumn get serverId => text().references(ServersTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  DateTimeColumn get lastModified => dateTime()();
  TextColumn get artistId => text().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get genre => text().nullable()();
  IntColumn get trackCount => integer().nullable()();
  IntColumn get durationMs => integer().nullable()();
  TextColumn get coverArtUrl => text().nullable()();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Artists table
@DataClassName('ArtistData')
class ArtistsTable extends Table {
  TextColumn get id => text()();
  TextColumn get serverId => text().references(ServersTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  DateTimeColumn get lastModified => dateTime()();
  IntColumn get albumCount => integer().nullable()();
  TextColumn get biography => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get musicBrainzId => text().nullable()();
  TextColumn get lastFmUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Playlists table
@DataClassName('PlaylistData')
class PlaylistsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get description => text().nullable()();
  IntColumn get durationMs => integer().nullable()();
  BoolColumn get isPublic => boolean().withDefault(const Constant(false))();
  TextColumn get coverArtUrl => text().nullable()();
  TextColumn get owner => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Playlist tracks junction table
@DataClassName('PlaylistTrackData')
class PlaylistTracksTable extends Table {
  TextColumn get playlistId => text().references(PlaylistsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get trackId => text().references(TracksTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {playlistId, trackId};
}

// Duplicate groups table
@DataClassName('DuplicateGroupData')
class DuplicateGroupsTable extends Table {
  TextColumn get id => text()();
  TextColumn get representativeTrackId => text().references(TracksTable, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Duplicate group members table
@DataClassName('DuplicateGroupMemberData')
class DuplicateGroupMembersTable extends Table {
  TextColumn get groupId => text().references(DuplicateGroupsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get trackId => text().references(TracksTable, #id, onDelete: KeyAction.cascade)();
  RealColumn get similarityScore => real()();

  @override
  Set<Column> get primaryKey => {groupId, trackId};
}

// Cache entries table for offline content
@DataClassName('CacheEntryData')
class CacheEntriesTable extends Table {
  TextColumn get trackId => text().references(TracksTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get filePath => text()();
  IntColumn get fileSize => integer()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get lastAccessed => dateTime()();
  BoolColumn get isComplete => boolean().withDefault(const Constant(false))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {trackId};
}