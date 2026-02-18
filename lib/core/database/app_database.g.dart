// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ServersTableTable extends ServersTable
    with TableInfo<$ServersTableTable, ServerData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServersTableTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> encryptedPassword =
      GeneratedColumn<String>(
        'encrypted_password',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  late final GeneratedColumnWithTypeConverter<ServerStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ServerStatus>($ServersTableTable.$converterstatus);
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<DateTime> lastSync = GeneratedColumn<DateTime>(
    'last_sync',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> apiVersion = GeneratedColumn<String>(
    'api_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> serverVersion = GeneratedColumn<String>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    url,
    username,
    encryptedPassword,
    status,
    createdAt,
    lastSync,
    apiVersion,
    serverVersion,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'servers_table';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ServerData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ServerData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      encryptedPassword: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encrypted_password'],
      )!,
      status: $ServersTableTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastSync: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync'],
      ),
      apiVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}api_version'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_version'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $ServersTableTable createAlias(String alias) {
    return $ServersTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ServerStatus, String, String> $converterstatus =
      const EnumNameConverter<ServerStatus>(ServerStatus.values);
}

class ServerData extends DataClass implements Insertable<ServerData> {
  final String id;
  final String name;
  final String url;
  final String username;
  final String encryptedPassword;
  final ServerStatus status;
  final DateTime createdAt;
  final DateTime? lastSync;
  final String? apiVersion;
  final String? serverVersion;
  final String? errorMessage;
  const ServerData({
    required this.id,
    required this.name,
    required this.url,
    required this.username,
    required this.encryptedPassword,
    required this.status,
    required this.createdAt,
    this.lastSync,
    this.apiVersion,
    this.serverVersion,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['url'] = Variable<String>(url);
    map['username'] = Variable<String>(username);
    map['encrypted_password'] = Variable<String>(encryptedPassword);
    {
      map['status'] = Variable<String>(
        $ServersTableTable.$converterstatus.toSql(status),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastSync != null) {
      map['last_sync'] = Variable<DateTime>(lastSync);
    }
    if (!nullToAbsent || apiVersion != null) {
      map['api_version'] = Variable<String>(apiVersion);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<String>(serverVersion);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  ServersTableCompanion toCompanion(bool nullToAbsent) {
    return ServersTableCompanion(
      id: Value(id),
      name: Value(name),
      url: Value(url),
      username: Value(username),
      encryptedPassword: Value(encryptedPassword),
      status: Value(status),
      createdAt: Value(createdAt),
      lastSync: lastSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSync),
      apiVersion: apiVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(apiVersion),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory ServerData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ServerData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      url: serializer.fromJson<String>(json['url']),
      username: serializer.fromJson<String>(json['username']),
      encryptedPassword: serializer.fromJson<String>(json['encryptedPassword']),
      status: $ServersTableTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastSync: serializer.fromJson<DateTime?>(json['lastSync']),
      apiVersion: serializer.fromJson<String?>(json['apiVersion']),
      serverVersion: serializer.fromJson<String?>(json['serverVersion']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'url': serializer.toJson<String>(url),
      'username': serializer.toJson<String>(username),
      'encryptedPassword': serializer.toJson<String>(encryptedPassword),
      'status': serializer.toJson<String>(
        $ServersTableTable.$converterstatus.toJson(status),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastSync': serializer.toJson<DateTime?>(lastSync),
      'apiVersion': serializer.toJson<String?>(apiVersion),
      'serverVersion': serializer.toJson<String?>(serverVersion),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  ServerData copyWith({
    String? id,
    String? name,
    String? url,
    String? username,
    String? encryptedPassword,
    ServerStatus? status,
    DateTime? createdAt,
    Value<DateTime?> lastSync = const Value.absent(),
    Value<String?> apiVersion = const Value.absent(),
    Value<String?> serverVersion = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
  }) => ServerData(
    id: id ?? this.id,
    name: name ?? this.name,
    url: url ?? this.url,
    username: username ?? this.username,
    encryptedPassword: encryptedPassword ?? this.encryptedPassword,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    lastSync: lastSync.present ? lastSync.value : this.lastSync,
    apiVersion: apiVersion.present ? apiVersion.value : this.apiVersion,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  ServerData copyWithCompanion(ServersTableCompanion data) {
    return ServerData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      url: data.url.present ? data.url.value : this.url,
      username: data.username.present ? data.username.value : this.username,
      encryptedPassword: data.encryptedPassword.present
          ? data.encryptedPassword.value
          : this.encryptedPassword,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastSync: data.lastSync.present ? data.lastSync.value : this.lastSync,
      apiVersion: data.apiVersion.present
          ? data.apiVersion.value
          : this.apiVersion,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ServerData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('username: $username, ')
          ..write('encryptedPassword: $encryptedPassword, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSync: $lastSync, ')
          ..write('apiVersion: $apiVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    url,
    username,
    encryptedPassword,
    status,
    createdAt,
    lastSync,
    apiVersion,
    serverVersion,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServerData &&
          other.id == this.id &&
          other.name == this.name &&
          other.url == this.url &&
          other.username == this.username &&
          other.encryptedPassword == this.encryptedPassword &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.lastSync == this.lastSync &&
          other.apiVersion == this.apiVersion &&
          other.serverVersion == this.serverVersion &&
          other.errorMessage == this.errorMessage);
}

class ServersTableCompanion extends UpdateCompanion<ServerData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> url;
  final Value<String> username;
  final Value<String> encryptedPassword;
  final Value<ServerStatus> status;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastSync;
  final Value<String?> apiVersion;
  final Value<String?> serverVersion;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const ServersTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.url = const Value.absent(),
    this.username = const Value.absent(),
    this.encryptedPassword = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastSync = const Value.absent(),
    this.apiVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ServersTableCompanion.insert({
    required String id,
    required String name,
    required String url,
    required String username,
    required String encryptedPassword,
    required ServerStatus status,
    required DateTime createdAt,
    this.lastSync = const Value.absent(),
    this.apiVersion = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       url = Value(url),
       username = Value(username),
       encryptedPassword = Value(encryptedPassword),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<ServerData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? url,
    Expression<String>? username,
    Expression<String>? encryptedPassword,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastSync,
    Expression<String>? apiVersion,
    Expression<String>? serverVersion,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (username != null) 'username': username,
      if (encryptedPassword != null) 'encrypted_password': encryptedPassword,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (lastSync != null) 'last_sync': lastSync,
      if (apiVersion != null) 'api_version': apiVersion,
      if (serverVersion != null) 'server_version': serverVersion,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ServersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? url,
    Value<String>? username,
    Value<String>? encryptedPassword,
    Value<ServerStatus>? status,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastSync,
    Value<String?>? apiVersion,
    Value<String?>? serverVersion,
    Value<String?>? errorMessage,
    Value<int>? rowid,
  }) {
    return ServersTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      username: username ?? this.username,
      encryptedPassword: encryptedPassword ?? this.encryptedPassword,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastSync: lastSync ?? this.lastSync,
      apiVersion: apiVersion ?? this.apiVersion,
      serverVersion: serverVersion ?? this.serverVersion,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (encryptedPassword.present) {
      map['encrypted_password'] = Variable<String>(encryptedPassword.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ServersTableTable.$converterstatus.toSql(status.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastSync.present) {
      map['last_sync'] = Variable<DateTime>(lastSync.value);
    }
    if (apiVersion.present) {
      map['api_version'] = Variable<String>(apiVersion.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<String>(serverVersion.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServersTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('username: $username, ')
          ..write('encryptedPassword: $encryptedPassword, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSync: $lastSync, ')
          ..write('apiVersion: $apiVersion, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TracksTableTable extends TracksTable
    with TableInfo<$TracksTableTable, TrackData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTableTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES servers_table (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
    'album',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> streamUrl = GeneratedColumn<String>(
    'stream_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AudioQuality, String> quality =
      GeneratedColumn<String>(
        'quality',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AudioQuality>($TracksTableTable.$converterquality);
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
    'album_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> artistId = GeneratedColumn<String>(
    'artist_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> trackNumber = GeneratedColumn<int>(
    'track_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> discNumber = GeneratedColumn<int>(
    'disc_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> coverArtUrl = GeneratedColumn<String>(
    'cover_art_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<bool> isCached = GeneratedColumn<bool>(
    'is_cached',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_cached" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumn<String> cachePath = GeneratedColumn<String>(
    'cache_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<bool> isStarred = GeneratedColumn<bool>(
    'is_starred',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_starred" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    title,
    artist,
    album,
    durationMs,
    streamUrl,
    quality,
    lastModified,
    albumId,
    artistId,
    trackNumber,
    discNumber,
    year,
    genre,
    fileSize,
    coverArtUrl,
    isCached,
    cachePath,
    isStarred,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks_table';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      album: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      streamUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_url'],
      )!,
      quality: $TracksTableTable.$converterquality.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}quality'],
        )!,
      ),
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_id'],
      ),
      artistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_id'],
      ),
      trackNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_number'],
      ),
      discNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disc_number'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      ),
      coverArtUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_art_url'],
      ),
      isCached: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_cached'],
      )!,
      cachePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_path'],
      ),
      isStarred: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_starred'],
      )!,
    );
  }

  @override
  $TracksTableTable createAlias(String alias) {
    return $TracksTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AudioQuality, String, String> $converterquality =
      const EnumNameConverter<AudioQuality>(AudioQuality.values);
}

class TrackData extends DataClass implements Insertable<TrackData> {
  final String id;
  final String serverId;
  final String title;
  final String artist;
  final String album;
  final int durationMs;
  final String streamUrl;
  final AudioQuality quality;
  final DateTime lastModified;
  final String? albumId;
  final String? artistId;
  final int? trackNumber;
  final int? discNumber;
  final int? year;
  final String? genre;
  final int? fileSize;
  final String? coverArtUrl;
  final bool isCached;
  final String? cachePath;
  final bool isStarred;
  const TrackData({
    required this.id,
    required this.serverId,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
    required this.streamUrl,
    required this.quality,
    required this.lastModified,
    this.albumId,
    this.artistId,
    this.trackNumber,
    this.discNumber,
    this.year,
    this.genre,
    this.fileSize,
    this.coverArtUrl,
    required this.isCached,
    this.cachePath,
    required this.isStarred,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['server_id'] = Variable<String>(serverId);
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    map['album'] = Variable<String>(album);
    map['duration_ms'] = Variable<int>(durationMs);
    map['stream_url'] = Variable<String>(streamUrl);
    {
      map['quality'] = Variable<String>(
        $TracksTableTable.$converterquality.toSql(quality),
      );
    }
    map['last_modified'] = Variable<DateTime>(lastModified);
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<String>(albumId);
    }
    if (!nullToAbsent || artistId != null) {
      map['artist_id'] = Variable<String>(artistId);
    }
    if (!nullToAbsent || trackNumber != null) {
      map['track_number'] = Variable<int>(trackNumber);
    }
    if (!nullToAbsent || discNumber != null) {
      map['disc_number'] = Variable<int>(discNumber);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || fileSize != null) {
      map['file_size'] = Variable<int>(fileSize);
    }
    if (!nullToAbsent || coverArtUrl != null) {
      map['cover_art_url'] = Variable<String>(coverArtUrl);
    }
    map['is_cached'] = Variable<bool>(isCached);
    if (!nullToAbsent || cachePath != null) {
      map['cache_path'] = Variable<String>(cachePath);
    }
    map['is_starred'] = Variable<bool>(isStarred);
    return map;
  }

  TracksTableCompanion toCompanion(bool nullToAbsent) {
    return TracksTableCompanion(
      id: Value(id),
      serverId: Value(serverId),
      title: Value(title),
      artist: Value(artist),
      album: Value(album),
      durationMs: Value(durationMs),
      streamUrl: Value(streamUrl),
      quality: Value(quality),
      lastModified: Value(lastModified),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      artistId: artistId == null && nullToAbsent
          ? const Value.absent()
          : Value(artistId),
      trackNumber: trackNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(trackNumber),
      discNumber: discNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(discNumber),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      fileSize: fileSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSize),
      coverArtUrl: coverArtUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverArtUrl),
      isCached: Value(isCached),
      cachePath: cachePath == null && nullToAbsent
          ? const Value.absent()
          : Value(cachePath),
      isStarred: Value(isStarred),
    );
  }

  factory TrackData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackData(
      id: serializer.fromJson<String>(json['id']),
      serverId: serializer.fromJson<String>(json['serverId']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      album: serializer.fromJson<String>(json['album']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      streamUrl: serializer.fromJson<String>(json['streamUrl']),
      quality: $TracksTableTable.$converterquality.fromJson(
        serializer.fromJson<String>(json['quality']),
      ),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      albumId: serializer.fromJson<String?>(json['albumId']),
      artistId: serializer.fromJson<String?>(json['artistId']),
      trackNumber: serializer.fromJson<int?>(json['trackNumber']),
      discNumber: serializer.fromJson<int?>(json['discNumber']),
      year: serializer.fromJson<int?>(json['year']),
      genre: serializer.fromJson<String?>(json['genre']),
      fileSize: serializer.fromJson<int?>(json['fileSize']),
      coverArtUrl: serializer.fromJson<String?>(json['coverArtUrl']),
      isCached: serializer.fromJson<bool>(json['isCached']),
      cachePath: serializer.fromJson<String?>(json['cachePath']),
      isStarred: serializer.fromJson<bool>(json['isStarred']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverId': serializer.toJson<String>(serverId),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'album': serializer.toJson<String>(album),
      'durationMs': serializer.toJson<int>(durationMs),
      'streamUrl': serializer.toJson<String>(streamUrl),
      'quality': serializer.toJson<String>(
        $TracksTableTable.$converterquality.toJson(quality),
      ),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'albumId': serializer.toJson<String?>(albumId),
      'artistId': serializer.toJson<String?>(artistId),
      'trackNumber': serializer.toJson<int?>(trackNumber),
      'discNumber': serializer.toJson<int?>(discNumber),
      'year': serializer.toJson<int?>(year),
      'genre': serializer.toJson<String?>(genre),
      'fileSize': serializer.toJson<int?>(fileSize),
      'coverArtUrl': serializer.toJson<String?>(coverArtUrl),
      'isCached': serializer.toJson<bool>(isCached),
      'cachePath': serializer.toJson<String?>(cachePath),
      'isStarred': serializer.toJson<bool>(isStarred),
    };
  }

  TrackData copyWith({
    String? id,
    String? serverId,
    String? title,
    String? artist,
    String? album,
    int? durationMs,
    String? streamUrl,
    AudioQuality? quality,
    DateTime? lastModified,
    Value<String?> albumId = const Value.absent(),
    Value<String?> artistId = const Value.absent(),
    Value<int?> trackNumber = const Value.absent(),
    Value<int?> discNumber = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<String?> genre = const Value.absent(),
    Value<int?> fileSize = const Value.absent(),
    Value<String?> coverArtUrl = const Value.absent(),
    bool? isCached,
    Value<String?> cachePath = const Value.absent(),
    bool? isStarred,
  }) => TrackData(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    album: album ?? this.album,
    durationMs: durationMs ?? this.durationMs,
    streamUrl: streamUrl ?? this.streamUrl,
    quality: quality ?? this.quality,
    lastModified: lastModified ?? this.lastModified,
    albumId: albumId.present ? albumId.value : this.albumId,
    artistId: artistId.present ? artistId.value : this.artistId,
    trackNumber: trackNumber.present ? trackNumber.value : this.trackNumber,
    discNumber: discNumber.present ? discNumber.value : this.discNumber,
    year: year.present ? year.value : this.year,
    genre: genre.present ? genre.value : this.genre,
    fileSize: fileSize.present ? fileSize.value : this.fileSize,
    coverArtUrl: coverArtUrl.present ? coverArtUrl.value : this.coverArtUrl,
    isCached: isCached ?? this.isCached,
    cachePath: cachePath.present ? cachePath.value : this.cachePath,
    isStarred: isStarred ?? this.isStarred,
  );
  TrackData copyWithCompanion(TracksTableCompanion data) {
    return TrackData(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      streamUrl: data.streamUrl.present ? data.streamUrl.value : this.streamUrl,
      quality: data.quality.present ? data.quality.value : this.quality,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
      trackNumber: data.trackNumber.present
          ? data.trackNumber.value
          : this.trackNumber,
      discNumber: data.discNumber.present
          ? data.discNumber.value
          : this.discNumber,
      year: data.year.present ? data.year.value : this.year,
      genre: data.genre.present ? data.genre.value : this.genre,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      coverArtUrl: data.coverArtUrl.present
          ? data.coverArtUrl.value
          : this.coverArtUrl,
      isCached: data.isCached.present ? data.isCached.value : this.isCached,
      cachePath: data.cachePath.present ? data.cachePath.value : this.cachePath,
      isStarred: data.isStarred.present ? data.isStarred.value : this.isStarred,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackData(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('durationMs: $durationMs, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('quality: $quality, ')
          ..write('lastModified: $lastModified, ')
          ..write('albumId: $albumId, ')
          ..write('artistId: $artistId, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('discNumber: $discNumber, ')
          ..write('year: $year, ')
          ..write('genre: $genre, ')
          ..write('fileSize: $fileSize, ')
          ..write('coverArtUrl: $coverArtUrl, ')
          ..write('isCached: $isCached, ')
          ..write('cachePath: $cachePath, ')
          ..write('isStarred: $isStarred')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    title,
    artist,
    album,
    durationMs,
    streamUrl,
    quality,
    lastModified,
    albumId,
    artistId,
    trackNumber,
    discNumber,
    year,
    genre,
    fileSize,
    coverArtUrl,
    isCached,
    cachePath,
    isStarred,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackData &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.durationMs == this.durationMs &&
          other.streamUrl == this.streamUrl &&
          other.quality == this.quality &&
          other.lastModified == this.lastModified &&
          other.albumId == this.albumId &&
          other.artistId == this.artistId &&
          other.trackNumber == this.trackNumber &&
          other.discNumber == this.discNumber &&
          other.year == this.year &&
          other.genre == this.genre &&
          other.fileSize == this.fileSize &&
          other.coverArtUrl == this.coverArtUrl &&
          other.isCached == this.isCached &&
          other.cachePath == this.cachePath &&
          other.isStarred == this.isStarred);
}

class TracksTableCompanion extends UpdateCompanion<TrackData> {
  final Value<String> id;
  final Value<String> serverId;
  final Value<String> title;
  final Value<String> artist;
  final Value<String> album;
  final Value<int> durationMs;
  final Value<String> streamUrl;
  final Value<AudioQuality> quality;
  final Value<DateTime> lastModified;
  final Value<String?> albumId;
  final Value<String?> artistId;
  final Value<int?> trackNumber;
  final Value<int?> discNumber;
  final Value<int?> year;
  final Value<String?> genre;
  final Value<int?> fileSize;
  final Value<String?> coverArtUrl;
  final Value<bool> isCached;
  final Value<String?> cachePath;
  final Value<bool> isStarred;
  final Value<int> rowid;
  const TracksTableCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.quality = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.albumId = const Value.absent(),
    this.artistId = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.year = const Value.absent(),
    this.genre = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.coverArtUrl = const Value.absent(),
    this.isCached = const Value.absent(),
    this.cachePath = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TracksTableCompanion.insert({
    required String id,
    required String serverId,
    required String title,
    required String artist,
    required String album,
    required int durationMs,
    required String streamUrl,
    required AudioQuality quality,
    required DateTime lastModified,
    this.albumId = const Value.absent(),
    this.artistId = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.year = const Value.absent(),
    this.genre = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.coverArtUrl = const Value.absent(),
    this.isCached = const Value.absent(),
    this.cachePath = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       serverId = Value(serverId),
       title = Value(title),
       artist = Value(artist),
       album = Value(album),
       durationMs = Value(durationMs),
       streamUrl = Value(streamUrl),
       quality = Value(quality),
       lastModified = Value(lastModified);
  static Insertable<TrackData> custom({
    Expression<String>? id,
    Expression<String>? serverId,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<int>? durationMs,
    Expression<String>? streamUrl,
    Expression<String>? quality,
    Expression<DateTime>? lastModified,
    Expression<String>? albumId,
    Expression<String>? artistId,
    Expression<int>? trackNumber,
    Expression<int>? discNumber,
    Expression<int>? year,
    Expression<String>? genre,
    Expression<int>? fileSize,
    Expression<String>? coverArtUrl,
    Expression<bool>? isCached,
    Expression<String>? cachePath,
    Expression<bool>? isStarred,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (durationMs != null) 'duration_ms': durationMs,
      if (streamUrl != null) 'stream_url': streamUrl,
      if (quality != null) 'quality': quality,
      if (lastModified != null) 'last_modified': lastModified,
      if (albumId != null) 'album_id': albumId,
      if (artistId != null) 'artist_id': artistId,
      if (trackNumber != null) 'track_number': trackNumber,
      if (discNumber != null) 'disc_number': discNumber,
      if (year != null) 'year': year,
      if (genre != null) 'genre': genre,
      if (fileSize != null) 'file_size': fileSize,
      if (coverArtUrl != null) 'cover_art_url': coverArtUrl,
      if (isCached != null) 'is_cached': isCached,
      if (cachePath != null) 'cache_path': cachePath,
      if (isStarred != null) 'is_starred': isStarred,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TracksTableCompanion copyWith({
    Value<String>? id,
    Value<String>? serverId,
    Value<String>? title,
    Value<String>? artist,
    Value<String>? album,
    Value<int>? durationMs,
    Value<String>? streamUrl,
    Value<AudioQuality>? quality,
    Value<DateTime>? lastModified,
    Value<String?>? albumId,
    Value<String?>? artistId,
    Value<int?>? trackNumber,
    Value<int?>? discNumber,
    Value<int?>? year,
    Value<String?>? genre,
    Value<int?>? fileSize,
    Value<String?>? coverArtUrl,
    Value<bool>? isCached,
    Value<String?>? cachePath,
    Value<bool>? isStarred,
    Value<int>? rowid,
  }) {
    return TracksTableCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      durationMs: durationMs ?? this.durationMs,
      streamUrl: streamUrl ?? this.streamUrl,
      quality: quality ?? this.quality,
      lastModified: lastModified ?? this.lastModified,
      albumId: albumId ?? this.albumId,
      artistId: artistId ?? this.artistId,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      fileSize: fileSize ?? this.fileSize,
      coverArtUrl: coverArtUrl ?? this.coverArtUrl,
      isCached: isCached ?? this.isCached,
      cachePath: cachePath ?? this.cachePath,
      isStarred: isStarred ?? this.isStarred,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (streamUrl.present) {
      map['stream_url'] = Variable<String>(streamUrl.value);
    }
    if (quality.present) {
      map['quality'] = Variable<String>(
        $TracksTableTable.$converterquality.toSql(quality.value),
      );
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (artistId.present) {
      map['artist_id'] = Variable<String>(artistId.value);
    }
    if (trackNumber.present) {
      map['track_number'] = Variable<int>(trackNumber.value);
    }
    if (discNumber.present) {
      map['disc_number'] = Variable<int>(discNumber.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (coverArtUrl.present) {
      map['cover_art_url'] = Variable<String>(coverArtUrl.value);
    }
    if (isCached.present) {
      map['is_cached'] = Variable<bool>(isCached.value);
    }
    if (cachePath.present) {
      map['cache_path'] = Variable<String>(cachePath.value);
    }
    if (isStarred.present) {
      map['is_starred'] = Variable<bool>(isStarred.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksTableCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('durationMs: $durationMs, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('quality: $quality, ')
          ..write('lastModified: $lastModified, ')
          ..write('albumId: $albumId, ')
          ..write('artistId: $artistId, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('discNumber: $discNumber, ')
          ..write('year: $year, ')
          ..write('genre: $genre, ')
          ..write('fileSize: $fileSize, ')
          ..write('coverArtUrl: $coverArtUrl, ')
          ..write('isCached: $isCached, ')
          ..write('cachePath: $cachePath, ')
          ..write('isStarred: $isStarred, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlbumsTableTable extends AlbumsTable
    with TableInfo<$AlbumsTableTable, AlbumData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlbumsTableTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES servers_table (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> artistId = GeneratedColumn<String>(
    'artist_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> trackCount = GeneratedColumn<int>(
    'track_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> coverArtUrl = GeneratedColumn<String>(
    'cover_art_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    title,
    artist,
    lastModified,
    artistId,
    year,
    genre,
    trackCount,
    durationMs,
    coverArtUrl,
    description,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'albums_table';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AlbumData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlbumData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
      artistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_id'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      trackCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_count'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      coverArtUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_art_url'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
    );
  }

  @override
  $AlbumsTableTable createAlias(String alias) {
    return $AlbumsTableTable(attachedDatabase, alias);
  }
}

class AlbumData extends DataClass implements Insertable<AlbumData> {
  final String id;
  final String serverId;
  final String title;
  final String artist;
  final DateTime lastModified;
  final String? artistId;
  final int? year;
  final String? genre;
  final int? trackCount;
  final int? durationMs;
  final String? coverArtUrl;
  final String? description;
  const AlbumData({
    required this.id,
    required this.serverId,
    required this.title,
    required this.artist,
    required this.lastModified,
    this.artistId,
    this.year,
    this.genre,
    this.trackCount,
    this.durationMs,
    this.coverArtUrl,
    this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['server_id'] = Variable<String>(serverId);
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    map['last_modified'] = Variable<DateTime>(lastModified);
    if (!nullToAbsent || artistId != null) {
      map['artist_id'] = Variable<String>(artistId);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || trackCount != null) {
      map['track_count'] = Variable<int>(trackCount);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || coverArtUrl != null) {
      map['cover_art_url'] = Variable<String>(coverArtUrl);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  AlbumsTableCompanion toCompanion(bool nullToAbsent) {
    return AlbumsTableCompanion(
      id: Value(id),
      serverId: Value(serverId),
      title: Value(title),
      artist: Value(artist),
      lastModified: Value(lastModified),
      artistId: artistId == null && nullToAbsent
          ? const Value.absent()
          : Value(artistId),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      trackCount: trackCount == null && nullToAbsent
          ? const Value.absent()
          : Value(trackCount),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      coverArtUrl: coverArtUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverArtUrl),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory AlbumData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlbumData(
      id: serializer.fromJson<String>(json['id']),
      serverId: serializer.fromJson<String>(json['serverId']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      artistId: serializer.fromJson<String?>(json['artistId']),
      year: serializer.fromJson<int?>(json['year']),
      genre: serializer.fromJson<String?>(json['genre']),
      trackCount: serializer.fromJson<int?>(json['trackCount']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      coverArtUrl: serializer.fromJson<String?>(json['coverArtUrl']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverId': serializer.toJson<String>(serverId),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'artistId': serializer.toJson<String?>(artistId),
      'year': serializer.toJson<int?>(year),
      'genre': serializer.toJson<String?>(genre),
      'trackCount': serializer.toJson<int?>(trackCount),
      'durationMs': serializer.toJson<int?>(durationMs),
      'coverArtUrl': serializer.toJson<String?>(coverArtUrl),
      'description': serializer.toJson<String?>(description),
    };
  }

  AlbumData copyWith({
    String? id,
    String? serverId,
    String? title,
    String? artist,
    DateTime? lastModified,
    Value<String?> artistId = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<String?> genre = const Value.absent(),
    Value<int?> trackCount = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    Value<String?> coverArtUrl = const Value.absent(),
    Value<String?> description = const Value.absent(),
  }) => AlbumData(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    lastModified: lastModified ?? this.lastModified,
    artistId: artistId.present ? artistId.value : this.artistId,
    year: year.present ? year.value : this.year,
    genre: genre.present ? genre.value : this.genre,
    trackCount: trackCount.present ? trackCount.value : this.trackCount,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    coverArtUrl: coverArtUrl.present ? coverArtUrl.value : this.coverArtUrl,
    description: description.present ? description.value : this.description,
  );
  AlbumData copyWithCompanion(AlbumsTableCompanion data) {
    return AlbumData(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
      year: data.year.present ? data.year.value : this.year,
      genre: data.genre.present ? data.genre.value : this.genre,
      trackCount: data.trackCount.present
          ? data.trackCount.value
          : this.trackCount,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      coverArtUrl: data.coverArtUrl.present
          ? data.coverArtUrl.value
          : this.coverArtUrl,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlbumData(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('lastModified: $lastModified, ')
          ..write('artistId: $artistId, ')
          ..write('year: $year, ')
          ..write('genre: $genre, ')
          ..write('trackCount: $trackCount, ')
          ..write('durationMs: $durationMs, ')
          ..write('coverArtUrl: $coverArtUrl, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    title,
    artist,
    lastModified,
    artistId,
    year,
    genre,
    trackCount,
    durationMs,
    coverArtUrl,
    description,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlbumData &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.lastModified == this.lastModified &&
          other.artistId == this.artistId &&
          other.year == this.year &&
          other.genre == this.genre &&
          other.trackCount == this.trackCount &&
          other.durationMs == this.durationMs &&
          other.coverArtUrl == this.coverArtUrl &&
          other.description == this.description);
}

class AlbumsTableCompanion extends UpdateCompanion<AlbumData> {
  final Value<String> id;
  final Value<String> serverId;
  final Value<String> title;
  final Value<String> artist;
  final Value<DateTime> lastModified;
  final Value<String?> artistId;
  final Value<int?> year;
  final Value<String?> genre;
  final Value<int?> trackCount;
  final Value<int?> durationMs;
  final Value<String?> coverArtUrl;
  final Value<String?> description;
  final Value<int> rowid;
  const AlbumsTableCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.artistId = const Value.absent(),
    this.year = const Value.absent(),
    this.genre = const Value.absent(),
    this.trackCount = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.coverArtUrl = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlbumsTableCompanion.insert({
    required String id,
    required String serverId,
    required String title,
    required String artist,
    required DateTime lastModified,
    this.artistId = const Value.absent(),
    this.year = const Value.absent(),
    this.genre = const Value.absent(),
    this.trackCount = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.coverArtUrl = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       serverId = Value(serverId),
       title = Value(title),
       artist = Value(artist),
       lastModified = Value(lastModified);
  static Insertable<AlbumData> custom({
    Expression<String>? id,
    Expression<String>? serverId,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<DateTime>? lastModified,
    Expression<String>? artistId,
    Expression<int>? year,
    Expression<String>? genre,
    Expression<int>? trackCount,
    Expression<int>? durationMs,
    Expression<String>? coverArtUrl,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (lastModified != null) 'last_modified': lastModified,
      if (artistId != null) 'artist_id': artistId,
      if (year != null) 'year': year,
      if (genre != null) 'genre': genre,
      if (trackCount != null) 'track_count': trackCount,
      if (durationMs != null) 'duration_ms': durationMs,
      if (coverArtUrl != null) 'cover_art_url': coverArtUrl,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlbumsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? serverId,
    Value<String>? title,
    Value<String>? artist,
    Value<DateTime>? lastModified,
    Value<String?>? artistId,
    Value<int?>? year,
    Value<String?>? genre,
    Value<int?>? trackCount,
    Value<int?>? durationMs,
    Value<String?>? coverArtUrl,
    Value<String?>? description,
    Value<int>? rowid,
  }) {
    return AlbumsTableCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      lastModified: lastModified ?? this.lastModified,
      artistId: artistId ?? this.artistId,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      trackCount: trackCount ?? this.trackCount,
      durationMs: durationMs ?? this.durationMs,
      coverArtUrl: coverArtUrl ?? this.coverArtUrl,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (artistId.present) {
      map['artist_id'] = Variable<String>(artistId.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (trackCount.present) {
      map['track_count'] = Variable<int>(trackCount.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (coverArtUrl.present) {
      map['cover_art_url'] = Variable<String>(coverArtUrl.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlbumsTableCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('lastModified: $lastModified, ')
          ..write('artistId: $artistId, ')
          ..write('year: $year, ')
          ..write('genre: $genre, ')
          ..write('trackCount: $trackCount, ')
          ..write('durationMs: $durationMs, ')
          ..write('coverArtUrl: $coverArtUrl, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ArtistsTableTable extends ArtistsTable
    with TableInfo<$ArtistsTableTable, ArtistData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArtistsTableTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES servers_table (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<int> albumCount = GeneratedColumn<int>(
    'album_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> biography = GeneratedColumn<String>(
    'biography',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> musicBrainzId = GeneratedColumn<String>(
    'music_brainz_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> lastFmUrl = GeneratedColumn<String>(
    'last_fm_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    name,
    lastModified,
    albumCount,
    biography,
    imageUrl,
    musicBrainzId,
    lastFmUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'artists_table';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ArtistData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArtistData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      )!,
      albumCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}album_count'],
      ),
      biography: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}biography'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      musicBrainzId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}music_brainz_id'],
      ),
      lastFmUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_fm_url'],
      ),
    );
  }

  @override
  $ArtistsTableTable createAlias(String alias) {
    return $ArtistsTableTable(attachedDatabase, alias);
  }
}

class ArtistData extends DataClass implements Insertable<ArtistData> {
  final String id;
  final String serverId;
  final String name;
  final DateTime lastModified;
  final int? albumCount;
  final String? biography;
  final String? imageUrl;
  final String? musicBrainzId;
  final String? lastFmUrl;
  const ArtistData({
    required this.id,
    required this.serverId,
    required this.name,
    required this.lastModified,
    this.albumCount,
    this.biography,
    this.imageUrl,
    this.musicBrainzId,
    this.lastFmUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['server_id'] = Variable<String>(serverId);
    map['name'] = Variable<String>(name);
    map['last_modified'] = Variable<DateTime>(lastModified);
    if (!nullToAbsent || albumCount != null) {
      map['album_count'] = Variable<int>(albumCount);
    }
    if (!nullToAbsent || biography != null) {
      map['biography'] = Variable<String>(biography);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || musicBrainzId != null) {
      map['music_brainz_id'] = Variable<String>(musicBrainzId);
    }
    if (!nullToAbsent || lastFmUrl != null) {
      map['last_fm_url'] = Variable<String>(lastFmUrl);
    }
    return map;
  }

  ArtistsTableCompanion toCompanion(bool nullToAbsent) {
    return ArtistsTableCompanion(
      id: Value(id),
      serverId: Value(serverId),
      name: Value(name),
      lastModified: Value(lastModified),
      albumCount: albumCount == null && nullToAbsent
          ? const Value.absent()
          : Value(albumCount),
      biography: biography == null && nullToAbsent
          ? const Value.absent()
          : Value(biography),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      musicBrainzId: musicBrainzId == null && nullToAbsent
          ? const Value.absent()
          : Value(musicBrainzId),
      lastFmUrl: lastFmUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFmUrl),
    );
  }

  factory ArtistData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArtistData(
      id: serializer.fromJson<String>(json['id']),
      serverId: serializer.fromJson<String>(json['serverId']),
      name: serializer.fromJson<String>(json['name']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      albumCount: serializer.fromJson<int?>(json['albumCount']),
      biography: serializer.fromJson<String?>(json['biography']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      musicBrainzId: serializer.fromJson<String?>(json['musicBrainzId']),
      lastFmUrl: serializer.fromJson<String?>(json['lastFmUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'serverId': serializer.toJson<String>(serverId),
      'name': serializer.toJson<String>(name),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'albumCount': serializer.toJson<int?>(albumCount),
      'biography': serializer.toJson<String?>(biography),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'musicBrainzId': serializer.toJson<String?>(musicBrainzId),
      'lastFmUrl': serializer.toJson<String?>(lastFmUrl),
    };
  }

  ArtistData copyWith({
    String? id,
    String? serverId,
    String? name,
    DateTime? lastModified,
    Value<int?> albumCount = const Value.absent(),
    Value<String?> biography = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> musicBrainzId = const Value.absent(),
    Value<String?> lastFmUrl = const Value.absent(),
  }) => ArtistData(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    name: name ?? this.name,
    lastModified: lastModified ?? this.lastModified,
    albumCount: albumCount.present ? albumCount.value : this.albumCount,
    biography: biography.present ? biography.value : this.biography,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    musicBrainzId: musicBrainzId.present
        ? musicBrainzId.value
        : this.musicBrainzId,
    lastFmUrl: lastFmUrl.present ? lastFmUrl.value : this.lastFmUrl,
  );
  ArtistData copyWithCompanion(ArtistsTableCompanion data) {
    return ArtistData(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      name: data.name.present ? data.name.value : this.name,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      albumCount: data.albumCount.present
          ? data.albumCount.value
          : this.albumCount,
      biography: data.biography.present ? data.biography.value : this.biography,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      musicBrainzId: data.musicBrainzId.present
          ? data.musicBrainzId.value
          : this.musicBrainzId,
      lastFmUrl: data.lastFmUrl.present ? data.lastFmUrl.value : this.lastFmUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArtistData(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('lastModified: $lastModified, ')
          ..write('albumCount: $albumCount, ')
          ..write('biography: $biography, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('musicBrainzId: $musicBrainzId, ')
          ..write('lastFmUrl: $lastFmUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    name,
    lastModified,
    albumCount,
    biography,
    imageUrl,
    musicBrainzId,
    lastFmUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArtistData &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.name == this.name &&
          other.lastModified == this.lastModified &&
          other.albumCount == this.albumCount &&
          other.biography == this.biography &&
          other.imageUrl == this.imageUrl &&
          other.musicBrainzId == this.musicBrainzId &&
          other.lastFmUrl == this.lastFmUrl);
}

class ArtistsTableCompanion extends UpdateCompanion<ArtistData> {
  final Value<String> id;
  final Value<String> serverId;
  final Value<String> name;
  final Value<DateTime> lastModified;
  final Value<int?> albumCount;
  final Value<String?> biography;
  final Value<String?> imageUrl;
  final Value<String?> musicBrainzId;
  final Value<String?> lastFmUrl;
  final Value<int> rowid;
  const ArtistsTableCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.name = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.albumCount = const Value.absent(),
    this.biography = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.musicBrainzId = const Value.absent(),
    this.lastFmUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArtistsTableCompanion.insert({
    required String id,
    required String serverId,
    required String name,
    required DateTime lastModified,
    this.albumCount = const Value.absent(),
    this.biography = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.musicBrainzId = const Value.absent(),
    this.lastFmUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       serverId = Value(serverId),
       name = Value(name),
       lastModified = Value(lastModified);
  static Insertable<ArtistData> custom({
    Expression<String>? id,
    Expression<String>? serverId,
    Expression<String>? name,
    Expression<DateTime>? lastModified,
    Expression<int>? albumCount,
    Expression<String>? biography,
    Expression<String>? imageUrl,
    Expression<String>? musicBrainzId,
    Expression<String>? lastFmUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (name != null) 'name': name,
      if (lastModified != null) 'last_modified': lastModified,
      if (albumCount != null) 'album_count': albumCount,
      if (biography != null) 'biography': biography,
      if (imageUrl != null) 'image_url': imageUrl,
      if (musicBrainzId != null) 'music_brainz_id': musicBrainzId,
      if (lastFmUrl != null) 'last_fm_url': lastFmUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArtistsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? serverId,
    Value<String>? name,
    Value<DateTime>? lastModified,
    Value<int?>? albumCount,
    Value<String?>? biography,
    Value<String?>? imageUrl,
    Value<String?>? musicBrainzId,
    Value<String?>? lastFmUrl,
    Value<int>? rowid,
  }) {
    return ArtistsTableCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      lastModified: lastModified ?? this.lastModified,
      albumCount: albumCount ?? this.albumCount,
      biography: biography ?? this.biography,
      imageUrl: imageUrl ?? this.imageUrl,
      musicBrainzId: musicBrainzId ?? this.musicBrainzId,
      lastFmUrl: lastFmUrl ?? this.lastFmUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (albumCount.present) {
      map['album_count'] = Variable<int>(albumCount.value);
    }
    if (biography.present) {
      map['biography'] = Variable<String>(biography.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (musicBrainzId.present) {
      map['music_brainz_id'] = Variable<String>(musicBrainzId.value);
    }
    if (lastFmUrl.present) {
      map['last_fm_url'] = Variable<String>(lastFmUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArtistsTableCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('lastModified: $lastModified, ')
          ..write('albumCount: $albumCount, ')
          ..write('biography: $biography, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('musicBrainzId: $musicBrainzId, ')
          ..write('lastFmUrl: $lastFmUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistsTableTable extends PlaylistsTable
    with TableInfo<$PlaylistsTableTable, PlaylistData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTableTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<bool> isPublic = GeneratedColumn<bool>(
    'is_public',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_public" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumn<String> coverArtUrl = GeneratedColumn<String>(
    'cover_art_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> owner = GeneratedColumn<String>(
    'owner',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    createdAt,
    updatedAt,
    description,
    durationMs,
    isPublic,
    coverArtUrl,
    owner,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists_table';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      isPublic: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_public'],
      )!,
      coverArtUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_art_url'],
      ),
      owner: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner'],
      ),
    );
  }

  @override
  $PlaylistsTableTable createAlias(String alias) {
    return $PlaylistsTableTable(attachedDatabase, alias);
  }
}

class PlaylistData extends DataClass implements Insertable<PlaylistData> {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final int? durationMs;
  final bool isPublic;
  final String? coverArtUrl;
  final String? owner;
  const PlaylistData({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.durationMs,
    required this.isPublic,
    this.coverArtUrl,
    this.owner,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['is_public'] = Variable<bool>(isPublic);
    if (!nullToAbsent || coverArtUrl != null) {
      map['cover_art_url'] = Variable<String>(coverArtUrl);
    }
    if (!nullToAbsent || owner != null) {
      map['owner'] = Variable<String>(owner);
    }
    return map;
  }

  PlaylistsTableCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsTableCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      isPublic: Value(isPublic),
      coverArtUrl: coverArtUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverArtUrl),
      owner: owner == null && nullToAbsent
          ? const Value.absent()
          : Value(owner),
    );
  }

  factory PlaylistData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      description: serializer.fromJson<String?>(json['description']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      isPublic: serializer.fromJson<bool>(json['isPublic']),
      coverArtUrl: serializer.fromJson<String?>(json['coverArtUrl']),
      owner: serializer.fromJson<String?>(json['owner']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'description': serializer.toJson<String?>(description),
      'durationMs': serializer.toJson<int?>(durationMs),
      'isPublic': serializer.toJson<bool>(isPublic),
      'coverArtUrl': serializer.toJson<String?>(coverArtUrl),
      'owner': serializer.toJson<String?>(owner),
    };
  }

  PlaylistData copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> description = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    bool? isPublic,
    Value<String?> coverArtUrl = const Value.absent(),
    Value<String?> owner = const Value.absent(),
  }) => PlaylistData(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    description: description.present ? description.value : this.description,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    isPublic: isPublic ?? this.isPublic,
    coverArtUrl: coverArtUrl.present ? coverArtUrl.value : this.coverArtUrl,
    owner: owner.present ? owner.value : this.owner,
  );
  PlaylistData copyWithCompanion(PlaylistsTableCompanion data) {
    return PlaylistData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      description: data.description.present
          ? data.description.value
          : this.description,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      isPublic: data.isPublic.present ? data.isPublic.value : this.isPublic,
      coverArtUrl: data.coverArtUrl.present
          ? data.coverArtUrl.value
          : this.coverArtUrl,
      owner: data.owner.present ? data.owner.value : this.owner,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('description: $description, ')
          ..write('durationMs: $durationMs, ')
          ..write('isPublic: $isPublic, ')
          ..write('coverArtUrl: $coverArtUrl, ')
          ..write('owner: $owner')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    createdAt,
    updatedAt,
    description,
    durationMs,
    isPublic,
    coverArtUrl,
    owner,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistData &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.description == this.description &&
          other.durationMs == this.durationMs &&
          other.isPublic == this.isPublic &&
          other.coverArtUrl == this.coverArtUrl &&
          other.owner == this.owner);
}

class PlaylistsTableCompanion extends UpdateCompanion<PlaylistData> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> description;
  final Value<int?> durationMs;
  final Value<bool> isPublic;
  final Value<String?> coverArtUrl;
  final Value<String?> owner;
  final Value<int> rowid;
  const PlaylistsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.description = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.isPublic = const Value.absent(),
    this.coverArtUrl = const Value.absent(),
    this.owner = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistsTableCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.description = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.isPublic = const Value.absent(),
    this.coverArtUrl = const Value.absent(),
    this.owner = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PlaylistData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? description,
    Expression<int>? durationMs,
    Expression<bool>? isPublic,
    Expression<String>? coverArtUrl,
    Expression<String>? owner,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (description != null) 'description': description,
      if (durationMs != null) 'duration_ms': durationMs,
      if (isPublic != null) 'is_public': isPublic,
      if (coverArtUrl != null) 'cover_art_url': coverArtUrl,
      if (owner != null) 'owner': owner,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? description,
    Value<int?>? durationMs,
    Value<bool>? isPublic,
    Value<String?>? coverArtUrl,
    Value<String?>? owner,
    Value<int>? rowid,
  }) {
    return PlaylistsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      durationMs: durationMs ?? this.durationMs,
      isPublic: isPublic ?? this.isPublic,
      coverArtUrl: coverArtUrl ?? this.coverArtUrl,
      owner: owner ?? this.owner,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (isPublic.present) {
      map['is_public'] = Variable<bool>(isPublic.value);
    }
    if (coverArtUrl.present) {
      map['cover_art_url'] = Variable<String>(coverArtUrl.value);
    }
    if (owner.present) {
      map['owner'] = Variable<String>(owner.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('description: $description, ')
          ..write('durationMs: $durationMs, ')
          ..write('isPublic: $isPublic, ')
          ..write('coverArtUrl: $coverArtUrl, ')
          ..write('owner: $owner, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistTracksTableTable extends PlaylistTracksTable
    with TableInfo<$PlaylistTracksTableTable, PlaylistTrackData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistTracksTableTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES playlists_table (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks_table (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [playlistId, trackId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_tracks_table';
  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId, trackId};
  @override
  PlaylistTrackData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistTrackData(
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $PlaylistTracksTableTable createAlias(String alias) {
    return $PlaylistTracksTableTable(attachedDatabase, alias);
  }
}

class PlaylistTrackData extends DataClass
    implements Insertable<PlaylistTrackData> {
  final String playlistId;
  final String trackId;
  final int position;
  const PlaylistTrackData({
    required this.playlistId,
    required this.trackId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<String>(playlistId);
    map['track_id'] = Variable<String>(trackId);
    map['position'] = Variable<int>(position);
    return map;
  }

  PlaylistTracksTableCompanion toCompanion(bool nullToAbsent) {
    return PlaylistTracksTableCompanion(
      playlistId: Value(playlistId),
      trackId: Value(trackId),
      position: Value(position),
    );
  }

  factory PlaylistTrackData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistTrackData(
      playlistId: serializer.fromJson<String>(json['playlistId']),
      trackId: serializer.fromJson<String>(json['trackId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<String>(playlistId),
      'trackId': serializer.toJson<String>(trackId),
      'position': serializer.toJson<int>(position),
    };
  }

  PlaylistTrackData copyWith({
    String? playlistId,
    String? trackId,
    int? position,
  }) => PlaylistTrackData(
    playlistId: playlistId ?? this.playlistId,
    trackId: trackId ?? this.trackId,
    position: position ?? this.position,
  );
  PlaylistTrackData copyWithCompanion(PlaylistTracksTableCompanion data) {
    return PlaylistTrackData(
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistTrackData(')
          ..write('playlistId: $playlistId, ')
          ..write('trackId: $trackId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playlistId, trackId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistTrackData &&
          other.playlistId == this.playlistId &&
          other.trackId == this.trackId &&
          other.position == this.position);
}

class PlaylistTracksTableCompanion extends UpdateCompanion<PlaylistTrackData> {
  final Value<String> playlistId;
  final Value<String> trackId;
  final Value<int> position;
  final Value<int> rowid;
  const PlaylistTracksTableCompanion({
    this.playlistId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistTracksTableCompanion.insert({
    required String playlistId,
    required String trackId,
    required int position,
    this.rowid = const Value.absent(),
  }) : playlistId = Value(playlistId),
       trackId = Value(trackId),
       position = Value(position);
  static Insertable<PlaylistTrackData> custom({
    Expression<String>? playlistId,
    Expression<String>? trackId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (trackId != null) 'track_id': trackId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistTracksTableCompanion copyWith({
    Value<String>? playlistId,
    Value<String>? trackId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return PlaylistTracksTableCompanion(
      playlistId: playlistId ?? this.playlistId,
      trackId: trackId ?? this.trackId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistTracksTableCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('trackId: $trackId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DuplicateGroupsTableTable extends DuplicateGroupsTable
    with TableInfo<$DuplicateGroupsTableTable, DuplicateGroupData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DuplicateGroupsTableTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> representativeTrackId =
      GeneratedColumn<String>(
        'representative_track_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES tracks_table (id) ON DELETE CASCADE',
        ),
      );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, representativeTrackId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'duplicate_groups_table';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DuplicateGroupData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DuplicateGroupData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      representativeTrackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}representative_track_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DuplicateGroupsTableTable createAlias(String alias) {
    return $DuplicateGroupsTableTable(attachedDatabase, alias);
  }
}

class DuplicateGroupData extends DataClass
    implements Insertable<DuplicateGroupData> {
  final String id;
  final String representativeTrackId;
  final DateTime createdAt;
  const DuplicateGroupData({
    required this.id,
    required this.representativeTrackId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['representative_track_id'] = Variable<String>(representativeTrackId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DuplicateGroupsTableCompanion toCompanion(bool nullToAbsent) {
    return DuplicateGroupsTableCompanion(
      id: Value(id),
      representativeTrackId: Value(representativeTrackId),
      createdAt: Value(createdAt),
    );
  }

  factory DuplicateGroupData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DuplicateGroupData(
      id: serializer.fromJson<String>(json['id']),
      representativeTrackId: serializer.fromJson<String>(
        json['representativeTrackId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'representativeTrackId': serializer.toJson<String>(representativeTrackId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DuplicateGroupData copyWith({
    String? id,
    String? representativeTrackId,
    DateTime? createdAt,
  }) => DuplicateGroupData(
    id: id ?? this.id,
    representativeTrackId: representativeTrackId ?? this.representativeTrackId,
    createdAt: createdAt ?? this.createdAt,
  );
  DuplicateGroupData copyWithCompanion(DuplicateGroupsTableCompanion data) {
    return DuplicateGroupData(
      id: data.id.present ? data.id.value : this.id,
      representativeTrackId: data.representativeTrackId.present
          ? data.representativeTrackId.value
          : this.representativeTrackId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DuplicateGroupData(')
          ..write('id: $id, ')
          ..write('representativeTrackId: $representativeTrackId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, representativeTrackId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DuplicateGroupData &&
          other.id == this.id &&
          other.representativeTrackId == this.representativeTrackId &&
          other.createdAt == this.createdAt);
}

class DuplicateGroupsTableCompanion
    extends UpdateCompanion<DuplicateGroupData> {
  final Value<String> id;
  final Value<String> representativeTrackId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DuplicateGroupsTableCompanion({
    this.id = const Value.absent(),
    this.representativeTrackId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DuplicateGroupsTableCompanion.insert({
    required String id,
    required String representativeTrackId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       representativeTrackId = Value(representativeTrackId),
       createdAt = Value(createdAt);
  static Insertable<DuplicateGroupData> custom({
    Expression<String>? id,
    Expression<String>? representativeTrackId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (representativeTrackId != null)
        'representative_track_id': representativeTrackId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DuplicateGroupsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? representativeTrackId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DuplicateGroupsTableCompanion(
      id: id ?? this.id,
      representativeTrackId:
          representativeTrackId ?? this.representativeTrackId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (representativeTrackId.present) {
      map['representative_track_id'] = Variable<String>(
        representativeTrackId.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DuplicateGroupsTableCompanion(')
          ..write('id: $id, ')
          ..write('representativeTrackId: $representativeTrackId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DuplicateGroupMembersTableTable extends DuplicateGroupMembersTable
    with TableInfo<$DuplicateGroupMembersTableTable, DuplicateGroupMemberData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DuplicateGroupMembersTableTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES duplicate_groups_table (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks_table (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumn<double> similarityScore = GeneratedColumn<double>(
    'similarity_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [groupId, trackId, similarityScore];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'duplicate_group_members_table';
  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, trackId};
  @override
  DuplicateGroupMemberData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DuplicateGroupMemberData(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      similarityScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}similarity_score'],
      )!,
    );
  }

  @override
  $DuplicateGroupMembersTableTable createAlias(String alias) {
    return $DuplicateGroupMembersTableTable(attachedDatabase, alias);
  }
}

class DuplicateGroupMemberData extends DataClass
    implements Insertable<DuplicateGroupMemberData> {
  final String groupId;
  final String trackId;
  final double similarityScore;
  const DuplicateGroupMemberData({
    required this.groupId,
    required this.trackId,
    required this.similarityScore,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['track_id'] = Variable<String>(trackId);
    map['similarity_score'] = Variable<double>(similarityScore);
    return map;
  }

  DuplicateGroupMembersTableCompanion toCompanion(bool nullToAbsent) {
    return DuplicateGroupMembersTableCompanion(
      groupId: Value(groupId),
      trackId: Value(trackId),
      similarityScore: Value(similarityScore),
    );
  }

  factory DuplicateGroupMemberData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DuplicateGroupMemberData(
      groupId: serializer.fromJson<String>(json['groupId']),
      trackId: serializer.fromJson<String>(json['trackId']),
      similarityScore: serializer.fromJson<double>(json['similarityScore']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'trackId': serializer.toJson<String>(trackId),
      'similarityScore': serializer.toJson<double>(similarityScore),
    };
  }

  DuplicateGroupMemberData copyWith({
    String? groupId,
    String? trackId,
    double? similarityScore,
  }) => DuplicateGroupMemberData(
    groupId: groupId ?? this.groupId,
    trackId: trackId ?? this.trackId,
    similarityScore: similarityScore ?? this.similarityScore,
  );
  DuplicateGroupMemberData copyWithCompanion(
    DuplicateGroupMembersTableCompanion data,
  ) {
    return DuplicateGroupMemberData(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      similarityScore: data.similarityScore.present
          ? data.similarityScore.value
          : this.similarityScore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DuplicateGroupMemberData(')
          ..write('groupId: $groupId, ')
          ..write('trackId: $trackId, ')
          ..write('similarityScore: $similarityScore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(groupId, trackId, similarityScore);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DuplicateGroupMemberData &&
          other.groupId == this.groupId &&
          other.trackId == this.trackId &&
          other.similarityScore == this.similarityScore);
}

class DuplicateGroupMembersTableCompanion
    extends UpdateCompanion<DuplicateGroupMemberData> {
  final Value<String> groupId;
  final Value<String> trackId;
  final Value<double> similarityScore;
  final Value<int> rowid;
  const DuplicateGroupMembersTableCompanion({
    this.groupId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.similarityScore = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DuplicateGroupMembersTableCompanion.insert({
    required String groupId,
    required String trackId,
    required double similarityScore,
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       trackId = Value(trackId),
       similarityScore = Value(similarityScore);
  static Insertable<DuplicateGroupMemberData> custom({
    Expression<String>? groupId,
    Expression<String>? trackId,
    Expression<double>? similarityScore,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (trackId != null) 'track_id': trackId,
      if (similarityScore != null) 'similarity_score': similarityScore,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DuplicateGroupMembersTableCompanion copyWith({
    Value<String>? groupId,
    Value<String>? trackId,
    Value<double>? similarityScore,
    Value<int>? rowid,
  }) {
    return DuplicateGroupMembersTableCompanion(
      groupId: groupId ?? this.groupId,
      trackId: trackId ?? this.trackId,
      similarityScore: similarityScore ?? this.similarityScore,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (similarityScore.present) {
      map['similarity_score'] = Variable<double>(similarityScore.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DuplicateGroupMembersTableCompanion(')
          ..write('groupId: $groupId, ')
          ..write('trackId: $trackId, ')
          ..write('similarityScore: $similarityScore, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CacheEntriesTableTable extends CacheEntriesTable
    with TableInfo<$CacheEntriesTableTable, CacheEntryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheEntriesTableTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks_table (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<DateTime> lastAccessed = GeneratedColumn<DateTime>(
    'last_accessed',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<bool> isComplete = GeneratedColumn<bool>(
    'is_complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    trackId,
    filePath,
    fileSize,
    cachedAt,
    lastAccessed,
    isComplete,
    isPinned,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_entries_table';
  @override
  Set<GeneratedColumn> get $primaryKey => {trackId};
  @override
  CacheEntryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheEntryData(
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
      lastAccessed: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_accessed'],
      )!,
      isComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_complete'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
    );
  }

  @override
  $CacheEntriesTableTable createAlias(String alias) {
    return $CacheEntriesTableTable(attachedDatabase, alias);
  }
}

class CacheEntryData extends DataClass implements Insertable<CacheEntryData> {
  final String trackId;
  final String filePath;
  final int fileSize;
  final DateTime cachedAt;
  final DateTime lastAccessed;
  final bool isComplete;
  final bool isPinned;
  const CacheEntryData({
    required this.trackId,
    required this.filePath,
    required this.fileSize,
    required this.cachedAt,
    required this.lastAccessed,
    required this.isComplete,
    required this.isPinned,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<String>(trackId);
    map['file_path'] = Variable<String>(filePath);
    map['file_size'] = Variable<int>(fileSize);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    map['last_accessed'] = Variable<DateTime>(lastAccessed);
    map['is_complete'] = Variable<bool>(isComplete);
    map['is_pinned'] = Variable<bool>(isPinned);
    return map;
  }

  CacheEntriesTableCompanion toCompanion(bool nullToAbsent) {
    return CacheEntriesTableCompanion(
      trackId: Value(trackId),
      filePath: Value(filePath),
      fileSize: Value(fileSize),
      cachedAt: Value(cachedAt),
      lastAccessed: Value(lastAccessed),
      isComplete: Value(isComplete),
      isPinned: Value(isPinned),
    );
  }

  factory CacheEntryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheEntryData(
      trackId: serializer.fromJson<String>(json['trackId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      lastAccessed: serializer.fromJson<DateTime>(json['lastAccessed']),
      isComplete: serializer.fromJson<bool>(json['isComplete']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<String>(trackId),
      'filePath': serializer.toJson<String>(filePath),
      'fileSize': serializer.toJson<int>(fileSize),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'lastAccessed': serializer.toJson<DateTime>(lastAccessed),
      'isComplete': serializer.toJson<bool>(isComplete),
      'isPinned': serializer.toJson<bool>(isPinned),
    };
  }

  CacheEntryData copyWith({
    String? trackId,
    String? filePath,
    int? fileSize,
    DateTime? cachedAt,
    DateTime? lastAccessed,
    bool? isComplete,
    bool? isPinned,
  }) => CacheEntryData(
    trackId: trackId ?? this.trackId,
    filePath: filePath ?? this.filePath,
    fileSize: fileSize ?? this.fileSize,
    cachedAt: cachedAt ?? this.cachedAt,
    lastAccessed: lastAccessed ?? this.lastAccessed,
    isComplete: isComplete ?? this.isComplete,
    isPinned: isPinned ?? this.isPinned,
  );
  CacheEntryData copyWithCompanion(CacheEntriesTableCompanion data) {
    return CacheEntryData(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      lastAccessed: data.lastAccessed.present
          ? data.lastAccessed.value
          : this.lastAccessed,
      isComplete: data.isComplete.present
          ? data.isComplete.value
          : this.isComplete,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheEntryData(')
          ..write('trackId: $trackId, ')
          ..write('filePath: $filePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastAccessed: $lastAccessed, ')
          ..write('isComplete: $isComplete, ')
          ..write('isPinned: $isPinned')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    trackId,
    filePath,
    fileSize,
    cachedAt,
    lastAccessed,
    isComplete,
    isPinned,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheEntryData &&
          other.trackId == this.trackId &&
          other.filePath == this.filePath &&
          other.fileSize == this.fileSize &&
          other.cachedAt == this.cachedAt &&
          other.lastAccessed == this.lastAccessed &&
          other.isComplete == this.isComplete &&
          other.isPinned == this.isPinned);
}

class CacheEntriesTableCompanion extends UpdateCompanion<CacheEntryData> {
  final Value<String> trackId;
  final Value<String> filePath;
  final Value<int> fileSize;
  final Value<DateTime> cachedAt;
  final Value<DateTime> lastAccessed;
  final Value<bool> isComplete;
  final Value<bool> isPinned;
  final Value<int> rowid;
  const CacheEntriesTableCompanion({
    this.trackId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.lastAccessed = const Value.absent(),
    this.isComplete = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheEntriesTableCompanion.insert({
    required String trackId,
    required String filePath,
    required int fileSize,
    required DateTime cachedAt,
    required DateTime lastAccessed,
    this.isComplete = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : trackId = Value(trackId),
       filePath = Value(filePath),
       fileSize = Value(fileSize),
       cachedAt = Value(cachedAt),
       lastAccessed = Value(lastAccessed);
  static Insertable<CacheEntryData> custom({
    Expression<String>? trackId,
    Expression<String>? filePath,
    Expression<int>? fileSize,
    Expression<DateTime>? cachedAt,
    Expression<DateTime>? lastAccessed,
    Expression<bool>? isComplete,
    Expression<bool>? isPinned,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (filePath != null) 'file_path': filePath,
      if (fileSize != null) 'file_size': fileSize,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (lastAccessed != null) 'last_accessed': lastAccessed,
      if (isComplete != null) 'is_complete': isComplete,
      if (isPinned != null) 'is_pinned': isPinned,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheEntriesTableCompanion copyWith({
    Value<String>? trackId,
    Value<String>? filePath,
    Value<int>? fileSize,
    Value<DateTime>? cachedAt,
    Value<DateTime>? lastAccessed,
    Value<bool>? isComplete,
    Value<bool>? isPinned,
    Value<int>? rowid,
  }) {
    return CacheEntriesTableCompanion(
      trackId: trackId ?? this.trackId,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      cachedAt: cachedAt ?? this.cachedAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      isComplete: isComplete ?? this.isComplete,
      isPinned: isPinned ?? this.isPinned,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (lastAccessed.present) {
      map['last_accessed'] = Variable<DateTime>(lastAccessed.value);
    }
    if (isComplete.present) {
      map['is_complete'] = Variable<bool>(isComplete.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheEntriesTableCompanion(')
          ..write('trackId: $trackId, ')
          ..write('filePath: $filePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastAccessed: $lastAccessed, ')
          ..write('isComplete: $isComplete, ')
          ..write('isPinned: $isPinned, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ServersTableTable serversTable = $ServersTableTable(this);
  late final $TracksTableTable tracksTable = $TracksTableTable(this);
  late final $AlbumsTableTable albumsTable = $AlbumsTableTable(this);
  late final $ArtistsTableTable artistsTable = $ArtistsTableTable(this);
  late final $PlaylistsTableTable playlistsTable = $PlaylistsTableTable(this);
  late final $PlaylistTracksTableTable playlistTracksTable =
      $PlaylistTracksTableTable(this);
  late final $DuplicateGroupsTableTable duplicateGroupsTable =
      $DuplicateGroupsTableTable(this);
  late final $DuplicateGroupMembersTableTable duplicateGroupMembersTable =
      $DuplicateGroupMembersTableTable(this);
  late final $CacheEntriesTableTable cacheEntriesTable =
      $CacheEntriesTableTable(this);
  late final ServerDao serverDao = ServerDao(this as AppDatabase);
  late final MusicDao musicDao = MusicDao(this as AppDatabase);
  late final PlaylistDao playlistDao = PlaylistDao(this as AppDatabase);
  late final CacheDao cacheDao = CacheDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    serversTable,
    tracksTable,
    albumsTable,
    artistsTable,
    playlistsTable,
    playlistTracksTable,
    duplicateGroupsTable,
    duplicateGroupMembersTable,
    cacheEntriesTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'servers_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tracks_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'servers_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('albums_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'servers_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('artists_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_tracks_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_tracks_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('duplicate_groups_table', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'duplicate_groups_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('duplicate_group_members_table', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('duplicate_group_members_table', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks_table',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cache_entries_table', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ServersTableTableCreateCompanionBuilder =
    ServersTableCompanion Function({
      required String id,
      required String name,
      required String url,
      required String username,
      required String encryptedPassword,
      required ServerStatus status,
      required DateTime createdAt,
      Value<DateTime?> lastSync,
      Value<String?> apiVersion,
      Value<String?> serverVersion,
      Value<String?> errorMessage,
      Value<int> rowid,
    });
typedef $$ServersTableTableUpdateCompanionBuilder =
    ServersTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> url,
      Value<String> username,
      Value<String> encryptedPassword,
      Value<ServerStatus> status,
      Value<DateTime> createdAt,
      Value<DateTime?> lastSync,
      Value<String?> apiVersion,
      Value<String?> serverVersion,
      Value<String?> errorMessage,
      Value<int> rowid,
    });

final class $$ServersTableTableReferences
    extends BaseReferences<_$AppDatabase, $ServersTableTable, ServerData> {
  $$ServersTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TracksTableTable, List<TrackData>>
  _tracksTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.tracksTable,
    aliasName: $_aliasNameGenerator(
      db.serversTable.id,
      db.tracksTable.serverId,
    ),
  );

  $$TracksTableTableProcessedTableManager get tracksTableRefs {
    final manager = $$TracksTableTableTableManager(
      $_db,
      $_db.tracksTable,
    ).filter((f) => f.serverId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tracksTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AlbumsTableTable, List<AlbumData>>
  _albumsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.albumsTable,
    aliasName: $_aliasNameGenerator(
      db.serversTable.id,
      db.albumsTable.serverId,
    ),
  );

  $$AlbumsTableTableProcessedTableManager get albumsTableRefs {
    final manager = $$AlbumsTableTableTableManager(
      $_db,
      $_db.albumsTable,
    ).filter((f) => f.serverId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_albumsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ArtistsTableTable, List<ArtistData>>
  _artistsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.artistsTable,
    aliasName: $_aliasNameGenerator(
      db.serversTable.id,
      db.artistsTable.serverId,
    ),
  );

  $$ArtistsTableTableProcessedTableManager get artistsTableRefs {
    final manager = $$ArtistsTableTableTableManager(
      $_db,
      $_db.artistsTable,
    ).filter((f) => f.serverId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_artistsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ServersTableTableFilterComposer
    extends Composer<_$AppDatabase, $ServersTableTable> {
  $$ServersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptedPassword => $composableBuilder(
    column: $table.encryptedPassword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ServerStatus, ServerStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSync => $composableBuilder(
    column: $table.lastSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apiVersion => $composableBuilder(
    column: $table.apiVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> tracksTableRefs(
    Expression<bool> Function($$TracksTableTableFilterComposer f) f,
  ) {
    final $$TracksTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tracksTable,
      getReferencedColumn: (t) => t.serverId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableTableFilterComposer(
            $db: $db,
            $table: $db.tracksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> albumsTableRefs(
    Expression<bool> Function($$AlbumsTableTableFilterComposer f) f,
  ) {
    final $$AlbumsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.albumsTable,
      getReferencedColumn: (t) => t.serverId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableTableFilterComposer(
            $db: $db,
            $table: $db.albumsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> artistsTableRefs(
    Expression<bool> Function($$ArtistsTableTableFilterComposer f) f,
  ) {
    final $$ArtistsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.artistsTable,
      getReferencedColumn: (t) => t.serverId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableTableFilterComposer(
            $db: $db,
            $table: $db.artistsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ServersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ServersTableTable> {
  $$ServersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptedPassword => $composableBuilder(
    column: $table.encryptedPassword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSync => $composableBuilder(
    column: $table.lastSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apiVersion => $composableBuilder(
    column: $table.apiVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ServersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ServersTableTable> {
  $$ServersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get encryptedPassword => $composableBuilder(
    column: $table.encryptedPassword,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ServerStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSync =>
      $composableBuilder(column: $table.lastSync, builder: (column) => column);

  GeneratedColumn<String> get apiVersion => $composableBuilder(
    column: $table.apiVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  Expression<T> tracksTableRefs<T extends Object>(
    Expression<T> Function($$TracksTableTableAnnotationComposer a) f,
  ) {
    final $$TracksTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tracksTable,
      getReferencedColumn: (t) => t.serverId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableTableAnnotationComposer(
            $db: $db,
            $table: $db.tracksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> albumsTableRefs<T extends Object>(
    Expression<T> Function($$AlbumsTableTableAnnotationComposer a) f,
  ) {
    final $$AlbumsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.albumsTable,
      getReferencedColumn: (t) => t.serverId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.albumsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> artistsTableRefs<T extends Object>(
    Expression<T> Function($$ArtistsTableTableAnnotationComposer a) f,
  ) {
    final $$ArtistsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.artistsTable,
      getReferencedColumn: (t) => t.serverId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArtistsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.artistsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ServersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ServersTableTable,
          ServerData,
          $$ServersTableTableFilterComposer,
          $$ServersTableTableOrderingComposer,
          $$ServersTableTableAnnotationComposer,
          $$ServersTableTableCreateCompanionBuilder,
          $$ServersTableTableUpdateCompanionBuilder,
          (ServerData, $$ServersTableTableReferences),
          ServerData,
          PrefetchHooks Function({
            bool tracksTableRefs,
            bool albumsTableRefs,
            bool artistsTableRefs,
          })
        > {
  $$ServersTableTableTableManager(_$AppDatabase db, $ServersTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ServersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ServersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ServersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> encryptedPassword = const Value.absent(),
                Value<ServerStatus> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastSync = const Value.absent(),
                Value<String?> apiVersion = const Value.absent(),
                Value<String?> serverVersion = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServersTableCompanion(
                id: id,
                name: name,
                url: url,
                username: username,
                encryptedPassword: encryptedPassword,
                status: status,
                createdAt: createdAt,
                lastSync: lastSync,
                apiVersion: apiVersion,
                serverVersion: serverVersion,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String url,
                required String username,
                required String encryptedPassword,
                required ServerStatus status,
                required DateTime createdAt,
                Value<DateTime?> lastSync = const Value.absent(),
                Value<String?> apiVersion = const Value.absent(),
                Value<String?> serverVersion = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ServersTableCompanion.insert(
                id: id,
                name: name,
                url: url,
                username: username,
                encryptedPassword: encryptedPassword,
                status: status,
                createdAt: createdAt,
                lastSync: lastSync,
                apiVersion: apiVersion,
                serverVersion: serverVersion,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ServersTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                tracksTableRefs = false,
                albumsTableRefs = false,
                artistsTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (tracksTableRefs) db.tracksTable,
                    if (albumsTableRefs) db.albumsTable,
                    if (artistsTableRefs) db.artistsTable,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (tracksTableRefs)
                        await $_getPrefetchedData<
                          ServerData,
                          $ServersTableTable,
                          TrackData
                        >(
                          currentTable: table,
                          referencedTable: $$ServersTableTableReferences
                              ._tracksTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ServersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).tracksTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.serverId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (albumsTableRefs)
                        await $_getPrefetchedData<
                          ServerData,
                          $ServersTableTable,
                          AlbumData
                        >(
                          currentTable: table,
                          referencedTable: $$ServersTableTableReferences
                              ._albumsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ServersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).albumsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.serverId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (artistsTableRefs)
                        await $_getPrefetchedData<
                          ServerData,
                          $ServersTableTable,
                          ArtistData
                        >(
                          currentTable: table,
                          referencedTable: $$ServersTableTableReferences
                              ._artistsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ServersTableTableReferences(
                                db,
                                table,
                                p0,
                              ).artistsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.serverId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ServersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ServersTableTable,
      ServerData,
      $$ServersTableTableFilterComposer,
      $$ServersTableTableOrderingComposer,
      $$ServersTableTableAnnotationComposer,
      $$ServersTableTableCreateCompanionBuilder,
      $$ServersTableTableUpdateCompanionBuilder,
      (ServerData, $$ServersTableTableReferences),
      ServerData,
      PrefetchHooks Function({
        bool tracksTableRefs,
        bool albumsTableRefs,
        bool artistsTableRefs,
      })
    >;
typedef $$TracksTableTableCreateCompanionBuilder =
    TracksTableCompanion Function({
      required String id,
      required String serverId,
      required String title,
      required String artist,
      required String album,
      required int durationMs,
      required String streamUrl,
      required AudioQuality quality,
      required DateTime lastModified,
      Value<String?> albumId,
      Value<String?> artistId,
      Value<int?> trackNumber,
      Value<int?> discNumber,
      Value<int?> year,
      Value<String?> genre,
      Value<int?> fileSize,
      Value<String?> coverArtUrl,
      Value<bool> isCached,
      Value<String?> cachePath,
      Value<bool> isStarred,
      Value<int> rowid,
    });
typedef $$TracksTableTableUpdateCompanionBuilder =
    TracksTableCompanion Function({
      Value<String> id,
      Value<String> serverId,
      Value<String> title,
      Value<String> artist,
      Value<String> album,
      Value<int> durationMs,
      Value<String> streamUrl,
      Value<AudioQuality> quality,
      Value<DateTime> lastModified,
      Value<String?> albumId,
      Value<String?> artistId,
      Value<int?> trackNumber,
      Value<int?> discNumber,
      Value<int?> year,
      Value<String?> genre,
      Value<int?> fileSize,
      Value<String?> coverArtUrl,
      Value<bool> isCached,
      Value<String?> cachePath,
      Value<bool> isStarred,
      Value<int> rowid,
    });

final class $$TracksTableTableReferences
    extends BaseReferences<_$AppDatabase, $TracksTableTable, TrackData> {
  $$TracksTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ServersTableTable _serverIdTable(_$AppDatabase db) =>
      db.serversTable.createAlias(
        $_aliasNameGenerator(db.tracksTable.serverId, db.serversTable.id),
      );

  $$ServersTableTableProcessedTableManager get serverId {
    final $_column = $_itemColumn<String>('server_id')!;

    final manager = $$ServersTableTableTableManager(
      $_db,
      $_db.serversTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_serverIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PlaylistTracksTableTable, List<PlaylistTrackData>>
  _playlistTracksTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.playlistTracksTable,
        aliasName: $_aliasNameGenerator(
          db.tracksTable.id,
          db.playlistTracksTable.trackId,
        ),
      );

  $$PlaylistTracksTableTableProcessedTableManager get playlistTracksTableRefs {
    final manager = $$PlaylistTracksTableTableTableManager(
      $_db,
      $_db.playlistTracksTable,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playlistTracksTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $DuplicateGroupsTableTable,
    List<DuplicateGroupData>
  >
  _duplicateGroupsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.duplicateGroupsTable,
        aliasName: $_aliasNameGenerator(
          db.tracksTable.id,
          db.duplicateGroupsTable.representativeTrackId,
        ),
      );

  $$DuplicateGroupsTableTableProcessedTableManager
  get duplicateGroupsTableRefs {
    final manager =
        $$DuplicateGroupsTableTableTableManager(
          $_db,
          $_db.duplicateGroupsTable,
        ).filter(
          (f) =>
              f.representativeTrackId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _duplicateGroupsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $DuplicateGroupMembersTableTable,
    List<DuplicateGroupMemberData>
  >
  _duplicateGroupMembersTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.duplicateGroupMembersTable,
        aliasName: $_aliasNameGenerator(
          db.tracksTable.id,
          db.duplicateGroupMembersTable.trackId,
        ),
      );

  $$DuplicateGroupMembersTableTableProcessedTableManager
  get duplicateGroupMembersTableRefs {
    final manager = $$DuplicateGroupMembersTableTableTableManager(
      $_db,
      $_db.duplicateGroupMembersTable,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _duplicateGroupMembersTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CacheEntriesTableTable, List<CacheEntryData>>
  _cacheEntriesTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cacheEntriesTable,
        aliasName: $_aliasNameGenerator(
          db.tracksTable.id,
          db.cacheEntriesTable.trackId,
        ),
      );

  $$CacheEntriesTableTableProcessedTableManager get cacheEntriesTableRefs {
    final manager = $$CacheEntriesTableTableTableManager(
      $_db,
      $_db.cacheEntriesTable,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cacheEntriesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TracksTableTableFilterComposer
    extends Composer<_$AppDatabase, $TracksTableTable> {
  $$TracksTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streamUrl => $composableBuilder(
    column: $table.streamUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AudioQuality, AudioQuality, String>
  get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistId => $composableBuilder(
    column: $table.artistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverArtUrl => $composableBuilder(
    column: $table.coverArtUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCached => $composableBuilder(
    column: $table.isCached,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cachePath => $composableBuilder(
    column: $table.cachePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isStarred => $composableBuilder(
    column: $table.isStarred,
    builder: (column) => ColumnFilters(column),
  );

  $$ServersTableTableFilterComposer get serverId {
    final $$ServersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serverId,
      referencedTable: $db.serversTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServersTableTableFilterComposer(
            $db: $db,
            $table: $db.serversTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> playlistTracksTableRefs(
    Expression<bool> Function($$PlaylistTracksTableTableFilterComposer f) f,
  ) {
    final $$PlaylistTracksTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistTracksTable,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistTracksTableTableFilterComposer(
            $db: $db,
            $table: $db.playlistTracksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> duplicateGroupsTableRefs(
    Expression<bool> Function($$DuplicateGroupsTableTableFilterComposer f) f,
  ) {
    final $$DuplicateGroupsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.duplicateGroupsTable,
      getReferencedColumn: (t) => t.representativeTrackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DuplicateGroupsTableTableFilterComposer(
            $db: $db,
            $table: $db.duplicateGroupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> duplicateGroupMembersTableRefs(
    Expression<bool> Function($$DuplicateGroupMembersTableTableFilterComposer f)
    f,
  ) {
    final $$DuplicateGroupMembersTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.duplicateGroupMembersTable,
          getReferencedColumn: (t) => t.trackId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DuplicateGroupMembersTableTableFilterComposer(
                $db: $db,
                $table: $db.duplicateGroupMembersTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> cacheEntriesTableRefs(
    Expression<bool> Function($$CacheEntriesTableTableFilterComposer f) f,
  ) {
    final $$CacheEntriesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cacheEntriesTable,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CacheEntriesTableTableFilterComposer(
            $db: $db,
            $table: $db.cacheEntriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TracksTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TracksTableTable> {
  $$TracksTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streamUrl => $composableBuilder(
    column: $table.streamUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistId => $composableBuilder(
    column: $table.artistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverArtUrl => $composableBuilder(
    column: $table.coverArtUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCached => $composableBuilder(
    column: $table.isCached,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cachePath => $composableBuilder(
    column: $table.cachePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isStarred => $composableBuilder(
    column: $table.isStarred,
    builder: (column) => ColumnOrderings(column),
  );

  $$ServersTableTableOrderingComposer get serverId {
    final $$ServersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serverId,
      referencedTable: $db.serversTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServersTableTableOrderingComposer(
            $db: $db,
            $table: $db.serversTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TracksTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TracksTableTable> {
  $$TracksTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get streamUrl =>
      $composableBuilder(column: $table.streamUrl, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AudioQuality, String> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => column);

  GeneratedColumn<String> get artistId =>
      $composableBuilder(column: $table.artistId, builder: (column) => column);

  GeneratedColumn<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get coverArtUrl => $composableBuilder(
    column: $table.coverArtUrl,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCached =>
      $composableBuilder(column: $table.isCached, builder: (column) => column);

  GeneratedColumn<String> get cachePath =>
      $composableBuilder(column: $table.cachePath, builder: (column) => column);

  GeneratedColumn<bool> get isStarred =>
      $composableBuilder(column: $table.isStarred, builder: (column) => column);

  $$ServersTableTableAnnotationComposer get serverId {
    final $$ServersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serverId,
      referencedTable: $db.serversTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.serversTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> playlistTracksTableRefs<T extends Object>(
    Expression<T> Function($$PlaylistTracksTableTableAnnotationComposer a) f,
  ) {
    final $$PlaylistTracksTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.playlistTracksTable,
          getReferencedColumn: (t) => t.trackId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlaylistTracksTableTableAnnotationComposer(
                $db: $db,
                $table: $db.playlistTracksTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> duplicateGroupsTableRefs<T extends Object>(
    Expression<T> Function($$DuplicateGroupsTableTableAnnotationComposer a) f,
  ) {
    final $$DuplicateGroupsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.duplicateGroupsTable,
          getReferencedColumn: (t) => t.representativeTrackId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DuplicateGroupsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.duplicateGroupsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> duplicateGroupMembersTableRefs<T extends Object>(
    Expression<T> Function(
      $$DuplicateGroupMembersTableTableAnnotationComposer a,
    )
    f,
  ) {
    final $$DuplicateGroupMembersTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.duplicateGroupMembersTable,
          getReferencedColumn: (t) => t.trackId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DuplicateGroupMembersTableTableAnnotationComposer(
                $db: $db,
                $table: $db.duplicateGroupMembersTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> cacheEntriesTableRefs<T extends Object>(
    Expression<T> Function($$CacheEntriesTableTableAnnotationComposer a) f,
  ) {
    final $$CacheEntriesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.cacheEntriesTable,
          getReferencedColumn: (t) => t.trackId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CacheEntriesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.cacheEntriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TracksTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TracksTableTable,
          TrackData,
          $$TracksTableTableFilterComposer,
          $$TracksTableTableOrderingComposer,
          $$TracksTableTableAnnotationComposer,
          $$TracksTableTableCreateCompanionBuilder,
          $$TracksTableTableUpdateCompanionBuilder,
          (TrackData, $$TracksTableTableReferences),
          TrackData,
          PrefetchHooks Function({
            bool serverId,
            bool playlistTracksTableRefs,
            bool duplicateGroupsTableRefs,
            bool duplicateGroupMembersTableRefs,
            bool cacheEntriesTableRefs,
          })
        > {
  $$TracksTableTableTableManager(_$AppDatabase db, $TracksTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracksTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TracksTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TracksTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> serverId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<String> album = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String> streamUrl = const Value.absent(),
                Value<AudioQuality> quality = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<String?> albumId = const Value.absent(),
                Value<String?> artistId = const Value.absent(),
                Value<int?> trackNumber = const Value.absent(),
                Value<int?> discNumber = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<String?> coverArtUrl = const Value.absent(),
                Value<bool> isCached = const Value.absent(),
                Value<String?> cachePath = const Value.absent(),
                Value<bool> isStarred = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TracksTableCompanion(
                id: id,
                serverId: serverId,
                title: title,
                artist: artist,
                album: album,
                durationMs: durationMs,
                streamUrl: streamUrl,
                quality: quality,
                lastModified: lastModified,
                albumId: albumId,
                artistId: artistId,
                trackNumber: trackNumber,
                discNumber: discNumber,
                year: year,
                genre: genre,
                fileSize: fileSize,
                coverArtUrl: coverArtUrl,
                isCached: isCached,
                cachePath: cachePath,
                isStarred: isStarred,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String serverId,
                required String title,
                required String artist,
                required String album,
                required int durationMs,
                required String streamUrl,
                required AudioQuality quality,
                required DateTime lastModified,
                Value<String?> albumId = const Value.absent(),
                Value<String?> artistId = const Value.absent(),
                Value<int?> trackNumber = const Value.absent(),
                Value<int?> discNumber = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<String?> coverArtUrl = const Value.absent(),
                Value<bool> isCached = const Value.absent(),
                Value<String?> cachePath = const Value.absent(),
                Value<bool> isStarred = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TracksTableCompanion.insert(
                id: id,
                serverId: serverId,
                title: title,
                artist: artist,
                album: album,
                durationMs: durationMs,
                streamUrl: streamUrl,
                quality: quality,
                lastModified: lastModified,
                albumId: albumId,
                artistId: artistId,
                trackNumber: trackNumber,
                discNumber: discNumber,
                year: year,
                genre: genre,
                fileSize: fileSize,
                coverArtUrl: coverArtUrl,
                isCached: isCached,
                cachePath: cachePath,
                isStarred: isStarred,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TracksTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                serverId = false,
                playlistTracksTableRefs = false,
                duplicateGroupsTableRefs = false,
                duplicateGroupMembersTableRefs = false,
                cacheEntriesTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (playlistTracksTableRefs) db.playlistTracksTable,
                    if (duplicateGroupsTableRefs) db.duplicateGroupsTable,
                    if (duplicateGroupMembersTableRefs)
                      db.duplicateGroupMembersTable,
                    if (cacheEntriesTableRefs) db.cacheEntriesTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (serverId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.serverId,
                                    referencedTable:
                                        $$TracksTableTableReferences
                                            ._serverIdTable(db),
                                    referencedColumn:
                                        $$TracksTableTableReferences
                                            ._serverIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (playlistTracksTableRefs)
                        await $_getPrefetchedData<
                          TrackData,
                          $TracksTableTable,
                          PlaylistTrackData
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableTableReferences
                              ._playlistTracksTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableTableReferences(
                                db,
                                table,
                                p0,
                              ).playlistTracksTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (duplicateGroupsTableRefs)
                        await $_getPrefetchedData<
                          TrackData,
                          $TracksTableTable,
                          DuplicateGroupData
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableTableReferences
                              ._duplicateGroupsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableTableReferences(
                                db,
                                table,
                                p0,
                              ).duplicateGroupsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.representativeTrackId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (duplicateGroupMembersTableRefs)
                        await $_getPrefetchedData<
                          TrackData,
                          $TracksTableTable,
                          DuplicateGroupMemberData
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableTableReferences
                              ._duplicateGroupMembersTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableTableReferences(
                                db,
                                table,
                                p0,
                              ).duplicateGroupMembersTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cacheEntriesTableRefs)
                        await $_getPrefetchedData<
                          TrackData,
                          $TracksTableTable,
                          CacheEntryData
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableTableReferences
                              ._cacheEntriesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableTableReferences(
                                db,
                                table,
                                p0,
                              ).cacheEntriesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TracksTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TracksTableTable,
      TrackData,
      $$TracksTableTableFilterComposer,
      $$TracksTableTableOrderingComposer,
      $$TracksTableTableAnnotationComposer,
      $$TracksTableTableCreateCompanionBuilder,
      $$TracksTableTableUpdateCompanionBuilder,
      (TrackData, $$TracksTableTableReferences),
      TrackData,
      PrefetchHooks Function({
        bool serverId,
        bool playlistTracksTableRefs,
        bool duplicateGroupsTableRefs,
        bool duplicateGroupMembersTableRefs,
        bool cacheEntriesTableRefs,
      })
    >;
typedef $$AlbumsTableTableCreateCompanionBuilder =
    AlbumsTableCompanion Function({
      required String id,
      required String serverId,
      required String title,
      required String artist,
      required DateTime lastModified,
      Value<String?> artistId,
      Value<int?> year,
      Value<String?> genre,
      Value<int?> trackCount,
      Value<int?> durationMs,
      Value<String?> coverArtUrl,
      Value<String?> description,
      Value<int> rowid,
    });
typedef $$AlbumsTableTableUpdateCompanionBuilder =
    AlbumsTableCompanion Function({
      Value<String> id,
      Value<String> serverId,
      Value<String> title,
      Value<String> artist,
      Value<DateTime> lastModified,
      Value<String?> artistId,
      Value<int?> year,
      Value<String?> genre,
      Value<int?> trackCount,
      Value<int?> durationMs,
      Value<String?> coverArtUrl,
      Value<String?> description,
      Value<int> rowid,
    });

final class $$AlbumsTableTableReferences
    extends BaseReferences<_$AppDatabase, $AlbumsTableTable, AlbumData> {
  $$AlbumsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ServersTableTable _serverIdTable(_$AppDatabase db) =>
      db.serversTable.createAlias(
        $_aliasNameGenerator(db.albumsTable.serverId, db.serversTable.id),
      );

  $$ServersTableTableProcessedTableManager get serverId {
    final $_column = $_itemColumn<String>('server_id')!;

    final manager = $$ServersTableTableTableManager(
      $_db,
      $_db.serversTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_serverIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AlbumsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AlbumsTableTable> {
  $$AlbumsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistId => $composableBuilder(
    column: $table.artistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackCount => $composableBuilder(
    column: $table.trackCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverArtUrl => $composableBuilder(
    column: $table.coverArtUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  $$ServersTableTableFilterComposer get serverId {
    final $$ServersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serverId,
      referencedTable: $db.serversTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServersTableTableFilterComposer(
            $db: $db,
            $table: $db.serversTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlbumsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AlbumsTableTable> {
  $$AlbumsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistId => $composableBuilder(
    column: $table.artistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackCount => $composableBuilder(
    column: $table.trackCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverArtUrl => $composableBuilder(
    column: $table.coverArtUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  $$ServersTableTableOrderingComposer get serverId {
    final $$ServersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serverId,
      referencedTable: $db.serversTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServersTableTableOrderingComposer(
            $db: $db,
            $table: $db.serversTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlbumsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlbumsTableTable> {
  $$AlbumsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artistId =>
      $composableBuilder(column: $table.artistId, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<int> get trackCount => $composableBuilder(
    column: $table.trackCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverArtUrl => $composableBuilder(
    column: $table.coverArtUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  $$ServersTableTableAnnotationComposer get serverId {
    final $$ServersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serverId,
      referencedTable: $db.serversTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.serversTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlbumsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlbumsTableTable,
          AlbumData,
          $$AlbumsTableTableFilterComposer,
          $$AlbumsTableTableOrderingComposer,
          $$AlbumsTableTableAnnotationComposer,
          $$AlbumsTableTableCreateCompanionBuilder,
          $$AlbumsTableTableUpdateCompanionBuilder,
          (AlbumData, $$AlbumsTableTableReferences),
          AlbumData,
          PrefetchHooks Function({bool serverId})
        > {
  $$AlbumsTableTableTableManager(_$AppDatabase db, $AlbumsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlbumsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlbumsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlbumsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> serverId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<String?> artistId = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<int?> trackCount = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<String?> coverArtUrl = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlbumsTableCompanion(
                id: id,
                serverId: serverId,
                title: title,
                artist: artist,
                lastModified: lastModified,
                artistId: artistId,
                year: year,
                genre: genre,
                trackCount: trackCount,
                durationMs: durationMs,
                coverArtUrl: coverArtUrl,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String serverId,
                required String title,
                required String artist,
                required DateTime lastModified,
                Value<String?> artistId = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<int?> trackCount = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<String?> coverArtUrl = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlbumsTableCompanion.insert(
                id: id,
                serverId: serverId,
                title: title,
                artist: artist,
                lastModified: lastModified,
                artistId: artistId,
                year: year,
                genre: genre,
                trackCount: trackCount,
                durationMs: durationMs,
                coverArtUrl: coverArtUrl,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AlbumsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({serverId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (serverId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.serverId,
                                referencedTable: $$AlbumsTableTableReferences
                                    ._serverIdTable(db),
                                referencedColumn: $$AlbumsTableTableReferences
                                    ._serverIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AlbumsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlbumsTableTable,
      AlbumData,
      $$AlbumsTableTableFilterComposer,
      $$AlbumsTableTableOrderingComposer,
      $$AlbumsTableTableAnnotationComposer,
      $$AlbumsTableTableCreateCompanionBuilder,
      $$AlbumsTableTableUpdateCompanionBuilder,
      (AlbumData, $$AlbumsTableTableReferences),
      AlbumData,
      PrefetchHooks Function({bool serverId})
    >;
typedef $$ArtistsTableTableCreateCompanionBuilder =
    ArtistsTableCompanion Function({
      required String id,
      required String serverId,
      required String name,
      required DateTime lastModified,
      Value<int?> albumCount,
      Value<String?> biography,
      Value<String?> imageUrl,
      Value<String?> musicBrainzId,
      Value<String?> lastFmUrl,
      Value<int> rowid,
    });
typedef $$ArtistsTableTableUpdateCompanionBuilder =
    ArtistsTableCompanion Function({
      Value<String> id,
      Value<String> serverId,
      Value<String> name,
      Value<DateTime> lastModified,
      Value<int?> albumCount,
      Value<String?> biography,
      Value<String?> imageUrl,
      Value<String?> musicBrainzId,
      Value<String?> lastFmUrl,
      Value<int> rowid,
    });

final class $$ArtistsTableTableReferences
    extends BaseReferences<_$AppDatabase, $ArtistsTableTable, ArtistData> {
  $$ArtistsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ServersTableTable _serverIdTable(_$AppDatabase db) =>
      db.serversTable.createAlias(
        $_aliasNameGenerator(db.artistsTable.serverId, db.serversTable.id),
      );

  $$ServersTableTableProcessedTableManager get serverId {
    final $_column = $_itemColumn<String>('server_id')!;

    final manager = $$ServersTableTableTableManager(
      $_db,
      $_db.serversTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_serverIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ArtistsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ArtistsTableTable> {
  $$ArtistsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get albumCount => $composableBuilder(
    column: $table.albumCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get biography => $composableBuilder(
    column: $table.biography,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get musicBrainzId => $composableBuilder(
    column: $table.musicBrainzId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastFmUrl => $composableBuilder(
    column: $table.lastFmUrl,
    builder: (column) => ColumnFilters(column),
  );

  $$ServersTableTableFilterComposer get serverId {
    final $$ServersTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serverId,
      referencedTable: $db.serversTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServersTableTableFilterComposer(
            $db: $db,
            $table: $db.serversTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArtistsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ArtistsTableTable> {
  $$ArtistsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get albumCount => $composableBuilder(
    column: $table.albumCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get biography => $composableBuilder(
    column: $table.biography,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get musicBrainzId => $composableBuilder(
    column: $table.musicBrainzId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastFmUrl => $composableBuilder(
    column: $table.lastFmUrl,
    builder: (column) => ColumnOrderings(column),
  );

  $$ServersTableTableOrderingComposer get serverId {
    final $$ServersTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serverId,
      referencedTable: $db.serversTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServersTableTableOrderingComposer(
            $db: $db,
            $table: $db.serversTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArtistsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArtistsTableTable> {
  $$ArtistsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<int> get albumCount => $composableBuilder(
    column: $table.albumCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get biography =>
      $composableBuilder(column: $table.biography, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get musicBrainzId => $composableBuilder(
    column: $table.musicBrainzId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastFmUrl =>
      $composableBuilder(column: $table.lastFmUrl, builder: (column) => column);

  $$ServersTableTableAnnotationComposer get serverId {
    final $$ServersTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serverId,
      referencedTable: $db.serversTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ServersTableTableAnnotationComposer(
            $db: $db,
            $table: $db.serversTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArtistsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArtistsTableTable,
          ArtistData,
          $$ArtistsTableTableFilterComposer,
          $$ArtistsTableTableOrderingComposer,
          $$ArtistsTableTableAnnotationComposer,
          $$ArtistsTableTableCreateCompanionBuilder,
          $$ArtistsTableTableUpdateCompanionBuilder,
          (ArtistData, $$ArtistsTableTableReferences),
          ArtistData,
          PrefetchHooks Function({bool serverId})
        > {
  $$ArtistsTableTableTableManager(_$AppDatabase db, $ArtistsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArtistsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArtistsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArtistsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> serverId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> lastModified = const Value.absent(),
                Value<int?> albumCount = const Value.absent(),
                Value<String?> biography = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> musicBrainzId = const Value.absent(),
                Value<String?> lastFmUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArtistsTableCompanion(
                id: id,
                serverId: serverId,
                name: name,
                lastModified: lastModified,
                albumCount: albumCount,
                biography: biography,
                imageUrl: imageUrl,
                musicBrainzId: musicBrainzId,
                lastFmUrl: lastFmUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String serverId,
                required String name,
                required DateTime lastModified,
                Value<int?> albumCount = const Value.absent(),
                Value<String?> biography = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> musicBrainzId = const Value.absent(),
                Value<String?> lastFmUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArtistsTableCompanion.insert(
                id: id,
                serverId: serverId,
                name: name,
                lastModified: lastModified,
                albumCount: albumCount,
                biography: biography,
                imageUrl: imageUrl,
                musicBrainzId: musicBrainzId,
                lastFmUrl: lastFmUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ArtistsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({serverId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (serverId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.serverId,
                                referencedTable: $$ArtistsTableTableReferences
                                    ._serverIdTable(db),
                                referencedColumn: $$ArtistsTableTableReferences
                                    ._serverIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ArtistsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArtistsTableTable,
      ArtistData,
      $$ArtistsTableTableFilterComposer,
      $$ArtistsTableTableOrderingComposer,
      $$ArtistsTableTableAnnotationComposer,
      $$ArtistsTableTableCreateCompanionBuilder,
      $$ArtistsTableTableUpdateCompanionBuilder,
      (ArtistData, $$ArtistsTableTableReferences),
      ArtistData,
      PrefetchHooks Function({bool serverId})
    >;
typedef $$PlaylistsTableTableCreateCompanionBuilder =
    PlaylistsTableCompanion Function({
      required String id,
      required String name,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<String?> description,
      Value<int?> durationMs,
      Value<bool> isPublic,
      Value<String?> coverArtUrl,
      Value<String?> owner,
      Value<int> rowid,
    });
typedef $$PlaylistsTableTableUpdateCompanionBuilder =
    PlaylistsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> description,
      Value<int?> durationMs,
      Value<bool> isPublic,
      Value<String?> coverArtUrl,
      Value<String?> owner,
      Value<int> rowid,
    });

final class $$PlaylistsTableTableReferences
    extends BaseReferences<_$AppDatabase, $PlaylistsTableTable, PlaylistData> {
  $$PlaylistsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$PlaylistTracksTableTable, List<PlaylistTrackData>>
  _playlistTracksTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.playlistTracksTable,
        aliasName: $_aliasNameGenerator(
          db.playlistsTable.id,
          db.playlistTracksTable.playlistId,
        ),
      );

  $$PlaylistTracksTableTableProcessedTableManager get playlistTracksTableRefs {
    final manager = $$PlaylistTracksTableTableTableManager(
      $_db,
      $_db.playlistTracksTable,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playlistTracksTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlaylistsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistsTableTable> {
  $$PlaylistsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPublic => $composableBuilder(
    column: $table.isPublic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverArtUrl => $composableBuilder(
    column: $table.coverArtUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get owner => $composableBuilder(
    column: $table.owner,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playlistTracksTableRefs(
    Expression<bool> Function($$PlaylistTracksTableTableFilterComposer f) f,
  ) {
    final $$PlaylistTracksTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistTracksTable,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistTracksTableTableFilterComposer(
            $db: $db,
            $table: $db.playlistTracksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistsTableTable> {
  $$PlaylistsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPublic => $composableBuilder(
    column: $table.isPublic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverArtUrl => $composableBuilder(
    column: $table.coverArtUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get owner => $composableBuilder(
    column: $table.owner,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistsTableTable> {
  $$PlaylistsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPublic =>
      $composableBuilder(column: $table.isPublic, builder: (column) => column);

  GeneratedColumn<String> get coverArtUrl => $composableBuilder(
    column: $table.coverArtUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get owner =>
      $composableBuilder(column: $table.owner, builder: (column) => column);

  Expression<T> playlistTracksTableRefs<T extends Object>(
    Expression<T> Function($$PlaylistTracksTableTableAnnotationComposer a) f,
  ) {
    final $$PlaylistTracksTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.playlistTracksTable,
          getReferencedColumn: (t) => t.playlistId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlaylistTracksTableTableAnnotationComposer(
                $db: $db,
                $table: $db.playlistTracksTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PlaylistsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistsTableTable,
          PlaylistData,
          $$PlaylistsTableTableFilterComposer,
          $$PlaylistsTableTableOrderingComposer,
          $$PlaylistsTableTableAnnotationComposer,
          $$PlaylistsTableTableCreateCompanionBuilder,
          $$PlaylistsTableTableUpdateCompanionBuilder,
          (PlaylistData, $$PlaylistsTableTableReferences),
          PlaylistData,
          PrefetchHooks Function({bool playlistTracksTableRefs})
        > {
  $$PlaylistsTableTableTableManager(
    _$AppDatabase db,
    $PlaylistsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<bool> isPublic = const Value.absent(),
                Value<String?> coverArtUrl = const Value.absent(),
                Value<String?> owner = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistsTableCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                description: description,
                durationMs: durationMs,
                isPublic: isPublic,
                coverArtUrl: coverArtUrl,
                owner: owner,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> description = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<bool> isPublic = const Value.absent(),
                Value<String?> coverArtUrl = const Value.absent(),
                Value<String?> owner = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistsTableCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                description: description,
                durationMs: durationMs,
                isPublic: isPublic,
                coverArtUrl: coverArtUrl,
                owner: owner,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaylistsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistTracksTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (playlistTracksTableRefs) db.playlistTracksTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (playlistTracksTableRefs)
                    await $_getPrefetchedData<
                      PlaylistData,
                      $PlaylistsTableTable,
                      PlaylistTrackData
                    >(
                      currentTable: table,
                      referencedTable: $$PlaylistsTableTableReferences
                          ._playlistTracksTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PlaylistsTableTableReferences(
                            db,
                            table,
                            p0,
                          ).playlistTracksTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.playlistId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistsTableTable,
      PlaylistData,
      $$PlaylistsTableTableFilterComposer,
      $$PlaylistsTableTableOrderingComposer,
      $$PlaylistsTableTableAnnotationComposer,
      $$PlaylistsTableTableCreateCompanionBuilder,
      $$PlaylistsTableTableUpdateCompanionBuilder,
      (PlaylistData, $$PlaylistsTableTableReferences),
      PlaylistData,
      PrefetchHooks Function({bool playlistTracksTableRefs})
    >;
typedef $$PlaylistTracksTableTableCreateCompanionBuilder =
    PlaylistTracksTableCompanion Function({
      required String playlistId,
      required String trackId,
      required int position,
      Value<int> rowid,
    });
typedef $$PlaylistTracksTableTableUpdateCompanionBuilder =
    PlaylistTracksTableCompanion Function({
      Value<String> playlistId,
      Value<String> trackId,
      Value<int> position,
      Value<int> rowid,
    });

final class $$PlaylistTracksTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PlaylistTracksTableTable,
          PlaylistTrackData
        > {
  $$PlaylistTracksTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlaylistsTableTable _playlistIdTable(_$AppDatabase db) =>
      db.playlistsTable.createAlias(
        $_aliasNameGenerator(
          db.playlistTracksTable.playlistId,
          db.playlistsTable.id,
        ),
      );

  $$PlaylistsTableTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$PlaylistsTableTableTableManager(
      $_db,
      $_db.playlistsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TracksTableTable _trackIdTable(_$AppDatabase db) =>
      db.tracksTable.createAlias(
        $_aliasNameGenerator(db.playlistTracksTable.trackId, db.tracksTable.id),
      );

  $$TracksTableTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<String>('track_id')!;

    final manager = $$TracksTableTableTableManager(
      $_db,
      $_db.tracksTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaylistTracksTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistTracksTableTable> {
  $$PlaylistTracksTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaylistsTableTableFilterComposer get playlistId {
    final $$PlaylistsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlistsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableTableFilterComposer(
            $db: $db,
            $table: $db.playlistsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableTableFilterComposer get trackId {
    final $$TracksTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableTableFilterComposer(
            $db: $db,
            $table: $db.tracksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistTracksTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistTracksTableTable> {
  $$PlaylistTracksTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableTableOrderingComposer get playlistId {
    final $$PlaylistsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlistsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableTableOrderingComposer(
            $db: $db,
            $table: $db.playlistsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableTableOrderingComposer get trackId {
    final $$TracksTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableTableOrderingComposer(
            $db: $db,
            $table: $db.tracksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistTracksTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistTracksTableTable> {
  $$PlaylistTracksTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$PlaylistsTableTableAnnotationComposer get playlistId {
    final $$PlaylistsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlistsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableTableAnnotationComposer get trackId {
    final $$TracksTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableTableAnnotationComposer(
            $db: $db,
            $table: $db.tracksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistTracksTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaylistTracksTableTable,
          PlaylistTrackData,
          $$PlaylistTracksTableTableFilterComposer,
          $$PlaylistTracksTableTableOrderingComposer,
          $$PlaylistTracksTableTableAnnotationComposer,
          $$PlaylistTracksTableTableCreateCompanionBuilder,
          $$PlaylistTracksTableTableUpdateCompanionBuilder,
          (PlaylistTrackData, $$PlaylistTracksTableTableReferences),
          PlaylistTrackData,
          PrefetchHooks Function({bool playlistId, bool trackId})
        > {
  $$PlaylistTracksTableTableTableManager(
    _$AppDatabase db,
    $PlaylistTracksTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistTracksTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistTracksTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PlaylistTracksTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> playlistId = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistTracksTableCompanion(
                playlistId: playlistId,
                trackId: trackId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String playlistId,
                required String trackId,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => PlaylistTracksTableCompanion.insert(
                playlistId: playlistId,
                trackId: trackId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaylistTracksTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false, trackId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playlistId,
                                referencedTable:
                                    $$PlaylistTracksTableTableReferences
                                        ._playlistIdTable(db),
                                referencedColumn:
                                    $$PlaylistTracksTableTableReferences
                                        ._playlistIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (trackId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.trackId,
                                referencedTable:
                                    $$PlaylistTracksTableTableReferences
                                        ._trackIdTable(db),
                                referencedColumn:
                                    $$PlaylistTracksTableTableReferences
                                        ._trackIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistTracksTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaylistTracksTableTable,
      PlaylistTrackData,
      $$PlaylistTracksTableTableFilterComposer,
      $$PlaylistTracksTableTableOrderingComposer,
      $$PlaylistTracksTableTableAnnotationComposer,
      $$PlaylistTracksTableTableCreateCompanionBuilder,
      $$PlaylistTracksTableTableUpdateCompanionBuilder,
      (PlaylistTrackData, $$PlaylistTracksTableTableReferences),
      PlaylistTrackData,
      PrefetchHooks Function({bool playlistId, bool trackId})
    >;
typedef $$DuplicateGroupsTableTableCreateCompanionBuilder =
    DuplicateGroupsTableCompanion Function({
      required String id,
      required String representativeTrackId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$DuplicateGroupsTableTableUpdateCompanionBuilder =
    DuplicateGroupsTableCompanion Function({
      Value<String> id,
      Value<String> representativeTrackId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$DuplicateGroupsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DuplicateGroupsTableTable,
          DuplicateGroupData
        > {
  $$DuplicateGroupsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TracksTableTable _representativeTrackIdTable(_$AppDatabase db) =>
      db.tracksTable.createAlias(
        $_aliasNameGenerator(
          db.duplicateGroupsTable.representativeTrackId,
          db.tracksTable.id,
        ),
      );

  $$TracksTableTableProcessedTableManager get representativeTrackId {
    final $_column = $_itemColumn<String>('representative_track_id')!;

    final manager = $$TracksTableTableTableManager(
      $_db,
      $_db.tracksTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _representativeTrackIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $DuplicateGroupMembersTableTable,
    List<DuplicateGroupMemberData>
  >
  _duplicateGroupMembersTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.duplicateGroupMembersTable,
        aliasName: $_aliasNameGenerator(
          db.duplicateGroupsTable.id,
          db.duplicateGroupMembersTable.groupId,
        ),
      );

  $$DuplicateGroupMembersTableTableProcessedTableManager
  get duplicateGroupMembersTableRefs {
    final manager = $$DuplicateGroupMembersTableTableTableManager(
      $_db,
      $_db.duplicateGroupMembersTable,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _duplicateGroupMembersTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DuplicateGroupsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DuplicateGroupsTableTable> {
  $$DuplicateGroupsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TracksTableTableFilterComposer get representativeTrackId {
    final $$TracksTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.representativeTrackId,
      referencedTable: $db.tracksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableTableFilterComposer(
            $db: $db,
            $table: $db.tracksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> duplicateGroupMembersTableRefs(
    Expression<bool> Function($$DuplicateGroupMembersTableTableFilterComposer f)
    f,
  ) {
    final $$DuplicateGroupMembersTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.duplicateGroupMembersTable,
          getReferencedColumn: (t) => t.groupId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DuplicateGroupMembersTableTableFilterComposer(
                $db: $db,
                $table: $db.duplicateGroupMembersTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DuplicateGroupsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DuplicateGroupsTableTable> {
  $$DuplicateGroupsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TracksTableTableOrderingComposer get representativeTrackId {
    final $$TracksTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.representativeTrackId,
      referencedTable: $db.tracksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableTableOrderingComposer(
            $db: $db,
            $table: $db.tracksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DuplicateGroupsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DuplicateGroupsTableTable> {
  $$DuplicateGroupsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TracksTableTableAnnotationComposer get representativeTrackId {
    final $$TracksTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.representativeTrackId,
      referencedTable: $db.tracksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableTableAnnotationComposer(
            $db: $db,
            $table: $db.tracksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> duplicateGroupMembersTableRefs<T extends Object>(
    Expression<T> Function(
      $$DuplicateGroupMembersTableTableAnnotationComposer a,
    )
    f,
  ) {
    final $$DuplicateGroupMembersTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.duplicateGroupMembersTable,
          getReferencedColumn: (t) => t.groupId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DuplicateGroupMembersTableTableAnnotationComposer(
                $db: $db,
                $table: $db.duplicateGroupMembersTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DuplicateGroupsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DuplicateGroupsTableTable,
          DuplicateGroupData,
          $$DuplicateGroupsTableTableFilterComposer,
          $$DuplicateGroupsTableTableOrderingComposer,
          $$DuplicateGroupsTableTableAnnotationComposer,
          $$DuplicateGroupsTableTableCreateCompanionBuilder,
          $$DuplicateGroupsTableTableUpdateCompanionBuilder,
          (DuplicateGroupData, $$DuplicateGroupsTableTableReferences),
          DuplicateGroupData,
          PrefetchHooks Function({
            bool representativeTrackId,
            bool duplicateGroupMembersTableRefs,
          })
        > {
  $$DuplicateGroupsTableTableTableManager(
    _$AppDatabase db,
    $DuplicateGroupsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DuplicateGroupsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DuplicateGroupsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DuplicateGroupsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> representativeTrackId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DuplicateGroupsTableCompanion(
                id: id,
                representativeTrackId: representativeTrackId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String representativeTrackId,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DuplicateGroupsTableCompanion.insert(
                id: id,
                representativeTrackId: representativeTrackId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DuplicateGroupsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                representativeTrackId = false,
                duplicateGroupMembersTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (duplicateGroupMembersTableRefs)
                      db.duplicateGroupMembersTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (representativeTrackId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.representativeTrackId,
                                    referencedTable:
                                        $$DuplicateGroupsTableTableReferences
                                            ._representativeTrackIdTable(db),
                                    referencedColumn:
                                        $$DuplicateGroupsTableTableReferences
                                            ._representativeTrackIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (duplicateGroupMembersTableRefs)
                        await $_getPrefetchedData<
                          DuplicateGroupData,
                          $DuplicateGroupsTableTable,
                          DuplicateGroupMemberData
                        >(
                          currentTable: table,
                          referencedTable: $$DuplicateGroupsTableTableReferences
                              ._duplicateGroupMembersTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DuplicateGroupsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).duplicateGroupMembersTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DuplicateGroupsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DuplicateGroupsTableTable,
      DuplicateGroupData,
      $$DuplicateGroupsTableTableFilterComposer,
      $$DuplicateGroupsTableTableOrderingComposer,
      $$DuplicateGroupsTableTableAnnotationComposer,
      $$DuplicateGroupsTableTableCreateCompanionBuilder,
      $$DuplicateGroupsTableTableUpdateCompanionBuilder,
      (DuplicateGroupData, $$DuplicateGroupsTableTableReferences),
      DuplicateGroupData,
      PrefetchHooks Function({
        bool representativeTrackId,
        bool duplicateGroupMembersTableRefs,
      })
    >;
typedef $$DuplicateGroupMembersTableTableCreateCompanionBuilder =
    DuplicateGroupMembersTableCompanion Function({
      required String groupId,
      required String trackId,
      required double similarityScore,
      Value<int> rowid,
    });
typedef $$DuplicateGroupMembersTableTableUpdateCompanionBuilder =
    DuplicateGroupMembersTableCompanion Function({
      Value<String> groupId,
      Value<String> trackId,
      Value<double> similarityScore,
      Value<int> rowid,
    });

final class $$DuplicateGroupMembersTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DuplicateGroupMembersTableTable,
          DuplicateGroupMemberData
        > {
  $$DuplicateGroupMembersTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DuplicateGroupsTableTable _groupIdTable(_$AppDatabase db) =>
      db.duplicateGroupsTable.createAlias(
        $_aliasNameGenerator(
          db.duplicateGroupMembersTable.groupId,
          db.duplicateGroupsTable.id,
        ),
      );

  $$DuplicateGroupsTableTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$DuplicateGroupsTableTableTableManager(
      $_db,
      $_db.duplicateGroupsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TracksTableTable _trackIdTable(_$AppDatabase db) =>
      db.tracksTable.createAlias(
        $_aliasNameGenerator(
          db.duplicateGroupMembersTable.trackId,
          db.tracksTable.id,
        ),
      );

  $$TracksTableTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<String>('track_id')!;

    final manager = $$TracksTableTableTableManager(
      $_db,
      $_db.tracksTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DuplicateGroupMembersTableTableFilterComposer
    extends Composer<_$AppDatabase, $DuplicateGroupMembersTableTable> {
  $$DuplicateGroupMembersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<double> get similarityScore => $composableBuilder(
    column: $table.similarityScore,
    builder: (column) => ColumnFilters(column),
  );

  $$DuplicateGroupsTableTableFilterComposer get groupId {
    final $$DuplicateGroupsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.duplicateGroupsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DuplicateGroupsTableTableFilterComposer(
            $db: $db,
            $table: $db.duplicateGroupsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableTableFilterComposer get trackId {
    final $$TracksTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableTableFilterComposer(
            $db: $db,
            $table: $db.tracksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DuplicateGroupMembersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DuplicateGroupMembersTableTable> {
  $$DuplicateGroupMembersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<double> get similarityScore => $composableBuilder(
    column: $table.similarityScore,
    builder: (column) => ColumnOrderings(column),
  );

  $$DuplicateGroupsTableTableOrderingComposer get groupId {
    final $$DuplicateGroupsTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.groupId,
          referencedTable: $db.duplicateGroupsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DuplicateGroupsTableTableOrderingComposer(
                $db: $db,
                $table: $db.duplicateGroupsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$TracksTableTableOrderingComposer get trackId {
    final $$TracksTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableTableOrderingComposer(
            $db: $db,
            $table: $db.tracksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DuplicateGroupMembersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DuplicateGroupMembersTableTable> {
  $$DuplicateGroupMembersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<double> get similarityScore => $composableBuilder(
    column: $table.similarityScore,
    builder: (column) => column,
  );

  $$DuplicateGroupsTableTableAnnotationComposer get groupId {
    final $$DuplicateGroupsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.groupId,
          referencedTable: $db.duplicateGroupsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DuplicateGroupsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.duplicateGroupsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$TracksTableTableAnnotationComposer get trackId {
    final $$TracksTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableTableAnnotationComposer(
            $db: $db,
            $table: $db.tracksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DuplicateGroupMembersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DuplicateGroupMembersTableTable,
          DuplicateGroupMemberData,
          $$DuplicateGroupMembersTableTableFilterComposer,
          $$DuplicateGroupMembersTableTableOrderingComposer,
          $$DuplicateGroupMembersTableTableAnnotationComposer,
          $$DuplicateGroupMembersTableTableCreateCompanionBuilder,
          $$DuplicateGroupMembersTableTableUpdateCompanionBuilder,
          (
            DuplicateGroupMemberData,
            $$DuplicateGroupMembersTableTableReferences,
          ),
          DuplicateGroupMemberData,
          PrefetchHooks Function({bool groupId, bool trackId})
        > {
  $$DuplicateGroupMembersTableTableTableManager(
    _$AppDatabase db,
    $DuplicateGroupMembersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DuplicateGroupMembersTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DuplicateGroupMembersTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DuplicateGroupMembersTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> groupId = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<double> similarityScore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DuplicateGroupMembersTableCompanion(
                groupId: groupId,
                trackId: trackId,
                similarityScore: similarityScore,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupId,
                required String trackId,
                required double similarityScore,
                Value<int> rowid = const Value.absent(),
              }) => DuplicateGroupMembersTableCompanion.insert(
                groupId: groupId,
                trackId: trackId,
                similarityScore: similarityScore,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DuplicateGroupMembersTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupId = false, trackId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (groupId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.groupId,
                                referencedTable:
                                    $$DuplicateGroupMembersTableTableReferences
                                        ._groupIdTable(db),
                                referencedColumn:
                                    $$DuplicateGroupMembersTableTableReferences
                                        ._groupIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (trackId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.trackId,
                                referencedTable:
                                    $$DuplicateGroupMembersTableTableReferences
                                        ._trackIdTable(db),
                                referencedColumn:
                                    $$DuplicateGroupMembersTableTableReferences
                                        ._trackIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DuplicateGroupMembersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DuplicateGroupMembersTableTable,
      DuplicateGroupMemberData,
      $$DuplicateGroupMembersTableTableFilterComposer,
      $$DuplicateGroupMembersTableTableOrderingComposer,
      $$DuplicateGroupMembersTableTableAnnotationComposer,
      $$DuplicateGroupMembersTableTableCreateCompanionBuilder,
      $$DuplicateGroupMembersTableTableUpdateCompanionBuilder,
      (DuplicateGroupMemberData, $$DuplicateGroupMembersTableTableReferences),
      DuplicateGroupMemberData,
      PrefetchHooks Function({bool groupId, bool trackId})
    >;
typedef $$CacheEntriesTableTableCreateCompanionBuilder =
    CacheEntriesTableCompanion Function({
      required String trackId,
      required String filePath,
      required int fileSize,
      required DateTime cachedAt,
      required DateTime lastAccessed,
      Value<bool> isComplete,
      Value<bool> isPinned,
      Value<int> rowid,
    });
typedef $$CacheEntriesTableTableUpdateCompanionBuilder =
    CacheEntriesTableCompanion Function({
      Value<String> trackId,
      Value<String> filePath,
      Value<int> fileSize,
      Value<DateTime> cachedAt,
      Value<DateTime> lastAccessed,
      Value<bool> isComplete,
      Value<bool> isPinned,
      Value<int> rowid,
    });

final class $$CacheEntriesTableTableReferences
    extends
        BaseReferences<_$AppDatabase, $CacheEntriesTableTable, CacheEntryData> {
  $$CacheEntriesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TracksTableTable _trackIdTable(_$AppDatabase db) =>
      db.tracksTable.createAlias(
        $_aliasNameGenerator(db.cacheEntriesTable.trackId, db.tracksTable.id),
      );

  $$TracksTableTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<String>('track_id')!;

    final manager = $$TracksTableTableTableManager(
      $_db,
      $_db.tracksTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CacheEntriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CacheEntriesTableTable> {
  $$CacheEntriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAccessed => $composableBuilder(
    column: $table.lastAccessed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  $$TracksTableTableFilterComposer get trackId {
    final $$TracksTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableTableFilterComposer(
            $db: $db,
            $table: $db.tracksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CacheEntriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CacheEntriesTableTable> {
  $$CacheEntriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAccessed => $composableBuilder(
    column: $table.lastAccessed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  $$TracksTableTableOrderingComposer get trackId {
    final $$TracksTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableTableOrderingComposer(
            $db: $db,
            $table: $db.tracksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CacheEntriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CacheEntriesTableTable> {
  $$CacheEntriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAccessed => $composableBuilder(
    column: $table.lastAccessed,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  $$TracksTableTableAnnotationComposer get trackId {
    final $$TracksTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracksTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableTableAnnotationComposer(
            $db: $db,
            $table: $db.tracksTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CacheEntriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CacheEntriesTableTable,
          CacheEntryData,
          $$CacheEntriesTableTableFilterComposer,
          $$CacheEntriesTableTableOrderingComposer,
          $$CacheEntriesTableTableAnnotationComposer,
          $$CacheEntriesTableTableCreateCompanionBuilder,
          $$CacheEntriesTableTableUpdateCompanionBuilder,
          (CacheEntryData, $$CacheEntriesTableTableReferences),
          CacheEntryData,
          PrefetchHooks Function({bool trackId})
        > {
  $$CacheEntriesTableTableTableManager(
    _$AppDatabase db,
    $CacheEntriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheEntriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheEntriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheEntriesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> trackId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<DateTime> lastAccessed = const Value.absent(),
                Value<bool> isComplete = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheEntriesTableCompanion(
                trackId: trackId,
                filePath: filePath,
                fileSize: fileSize,
                cachedAt: cachedAt,
                lastAccessed: lastAccessed,
                isComplete: isComplete,
                isPinned: isPinned,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String trackId,
                required String filePath,
                required int fileSize,
                required DateTime cachedAt,
                required DateTime lastAccessed,
                Value<bool> isComplete = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheEntriesTableCompanion.insert(
                trackId: trackId,
                filePath: filePath,
                fileSize: fileSize,
                cachedAt: cachedAt,
                lastAccessed: lastAccessed,
                isComplete: isComplete,
                isPinned: isPinned,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CacheEntriesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (trackId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.trackId,
                                referencedTable:
                                    $$CacheEntriesTableTableReferences
                                        ._trackIdTable(db),
                                referencedColumn:
                                    $$CacheEntriesTableTableReferences
                                        ._trackIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CacheEntriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CacheEntriesTableTable,
      CacheEntryData,
      $$CacheEntriesTableTableFilterComposer,
      $$CacheEntriesTableTableOrderingComposer,
      $$CacheEntriesTableTableAnnotationComposer,
      $$CacheEntriesTableTableCreateCompanionBuilder,
      $$CacheEntriesTableTableUpdateCompanionBuilder,
      (CacheEntryData, $$CacheEntriesTableTableReferences),
      CacheEntryData,
      PrefetchHooks Function({bool trackId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ServersTableTableTableManager get serversTable =>
      $$ServersTableTableTableManager(_db, _db.serversTable);
  $$TracksTableTableTableManager get tracksTable =>
      $$TracksTableTableTableManager(_db, _db.tracksTable);
  $$AlbumsTableTableTableManager get albumsTable =>
      $$AlbumsTableTableTableManager(_db, _db.albumsTable);
  $$ArtistsTableTableTableManager get artistsTable =>
      $$ArtistsTableTableTableManager(_db, _db.artistsTable);
  $$PlaylistsTableTableTableManager get playlistsTable =>
      $$PlaylistsTableTableTableManager(_db, _db.playlistsTable);
  $$PlaylistTracksTableTableTableManager get playlistTracksTable =>
      $$PlaylistTracksTableTableTableManager(_db, _db.playlistTracksTable);
  $$DuplicateGroupsTableTableTableManager get duplicateGroupsTable =>
      $$DuplicateGroupsTableTableTableManager(_db, _db.duplicateGroupsTable);
  $$DuplicateGroupMembersTableTableTableManager
  get duplicateGroupMembersTable =>
      $$DuplicateGroupMembersTableTableTableManager(
        _db,
        _db.duplicateGroupMembersTable,
      );
  $$CacheEntriesTableTableTableManager get cacheEntriesTable =>
      $$CacheEntriesTableTableTableManager(_db, _db.cacheEntriesTable);
}
