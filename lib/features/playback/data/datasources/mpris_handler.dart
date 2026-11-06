import 'dart:async';

import 'package:dbus/dbus.dart';

import '../../../../core/repositories/playback_repository.dart'
    show PlaybackState;
import '../../../../core/utils/app_log.dart';
import '../../../../core/utils/platform_info.dart';
import 'audio_player_data_source.dart';

/// MPRIS (Media Player Remote Interfacing Specification) handler for Linux
/// Provides system-level media controls integration
class MprisHandler extends DBusObject {
  MprisHandler({required AudioPlayerDataSource audioPlayerDataSource})
    : _audioPlayerDataSource = audioPlayerDataSource,
      super(DBusObjectPath('/org/mpris/MediaPlayer2'));

  final AudioPlayerDataSource _audioPlayerDataSource;
  DBusClient? _client;
  StreamSubscription<PlaybackState>? _playbackStateSubscription;
  PlaybackState? _currentState;

  Future<void> initialize() async {
    if (!AppPlatform.isLinux) return;

    try {
      AppLog.info('Initializing MPRIS for Linux desktop integration');

      _client = DBusClient.session();

      // Register this object on the bus
      await _client!.registerObject(this);

      // Register MPRIS MediaPlayer2 interface
      await _client!.requestName(
        'org.mpris.MediaPlayer2.omnisonic',
        flags: {DBusRequestNameFlag.doNotQueue},
      );

      // Listen to playback state changes (with deduplication)
      _playbackStateSubscription = _audioPlayerDataSource
          .observePlaybackState()
          .distinct((previous, current) {
            // Only emit if meaningful properties changed
            return previous.isPlaying == current.isPlaying &&
                previous.currentTrack?.id == current.currentTrack?.id &&
                previous.queue.length == current.queue.length;
          })
          .listen((state) {
            _currentState = state;
            _updateMprisMetadata(state);
          });

      AppLog.info('MPRIS initialized successfully');
    } catch (e) {
      AppLog.warn('Failed to initialize MPRIS: $e');
    }
  }

  @override
  List<DBusIntrospectInterface> introspect() {
    return [
      DBusIntrospectInterface(
        'org.mpris.MediaPlayer2',
        methods: [DBusIntrospectMethod('Raise'), DBusIntrospectMethod('Quit')],
        properties: [
          DBusIntrospectProperty(
            'Identity',
            DBusSignature('s'),
            access: DBusPropertyAccess.read,
          ),
          DBusIntrospectProperty(
            'DesktopEntry',
            DBusSignature('s'),
            access: DBusPropertyAccess.read,
          ),
          DBusIntrospectProperty(
            'SupportedUriSchemes',
            DBusSignature('as'),
            access: DBusPropertyAccess.read,
          ),
          DBusIntrospectProperty(
            'SupportedMimeTypes',
            DBusSignature('as'),
            access: DBusPropertyAccess.read,
          ),
        ],
      ),
      DBusIntrospectInterface(
        'org.mpris.MediaPlayer2.Player',
        methods: [
          DBusIntrospectMethod('Play'),
          DBusIntrospectMethod('Pause'),
          DBusIntrospectMethod('PlayPause'),
          DBusIntrospectMethod('Next'),
          DBusIntrospectMethod('Previous'),
        ],
        properties: [
          DBusIntrospectProperty(
            'PlaybackStatus',
            DBusSignature('s'),
            access: DBusPropertyAccess.read,
          ),
          DBusIntrospectProperty(
            'Metadata',
            DBusSignature('a{sv}'),
            access: DBusPropertyAccess.read,
          ),
          DBusIntrospectProperty(
            'Position',
            DBusSignature('x'),
            access: DBusPropertyAccess.read,
          ),
          DBusIntrospectProperty(
            'CanGoNext',
            DBusSignature('b'),
            access: DBusPropertyAccess.read,
          ),
          DBusIntrospectProperty(
            'CanGoPrevious',
            DBusSignature('b'),
            access: DBusPropertyAccess.read,
          ),
          DBusIntrospectProperty(
            'CanPlay',
            DBusSignature('b'),
            access: DBusPropertyAccess.read,
          ),
          DBusIntrospectProperty(
            'CanPause',
            DBusSignature('b'),
            access: DBusPropertyAccess.read,
          ),
        ],
      ),
    ];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    AppLog.debug(
      'MPRIS handleMethodCall(${methodCall.interface}.${methodCall.name})',
    );

    if (methodCall.interface == 'org.mpris.MediaPlayer2') {
      switch (methodCall.name) {
        case 'Raise':
          AppLog.debug('MPRIS Raise requested (not implemented)');
          return DBusMethodSuccessResponse();
        case 'Quit':
          AppLog.debug('MPRIS Quit requested (not implemented)');
          return DBusMethodSuccessResponse();
      }
    } else if (methodCall.interface == 'org.mpris.MediaPlayer2.Player') {
      switch (methodCall.name) {
        case 'Play':
          AppLog.debug('MPRIS Play requested');
          _audioPlayerDataSource.resume();
          return DBusMethodSuccessResponse();
        case 'Pause':
          AppLog.debug('MPRIS Pause requested');
          _audioPlayerDataSource.pause();
          return DBusMethodSuccessResponse();
        case 'PlayPause':
          AppLog.debug('MPRIS PlayPause requested');
          if (_currentState?.isPlaying ?? false) {
            _audioPlayerDataSource.pause();
          } else {
            _audioPlayerDataSource.resume();
          }
          return DBusMethodSuccessResponse();
        case 'Next':
          AppLog.debug('MPRIS Next requested');
          _audioPlayerDataSource.skipToNext();
          return DBusMethodSuccessResponse();
        case 'Previous':
          AppLog.debug('MPRIS Previous requested');
          _audioPlayerDataSource.skipToPrevious();
          return DBusMethodSuccessResponse();
        case 'Stop':
          AppLog.debug('MPRIS Stop requested');
          _audioPlayerDataSource.stop();
          return DBusMethodSuccessResponse();
      }
    }
    AppLog.warn(
      'MPRIS unknown method: ${methodCall.interface}.${methodCall.name}',
    );
    return DBusMethodErrorResponse.unknownMethod();
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    // Don't log Position requests - they're polled frequently by media controllers
    if (name != 'Position') {
      AppLog.debug('MPRIS getProperty($interface, $name)');
    }
    if (interface == 'org.mpris.MediaPlayer2') {
      switch (name) {
        case 'Identity':
          return DBusGetPropertyResponse(DBusString('OmniSonic'));
        case 'DesktopEntry':
          return DBusGetPropertyResponse(DBusString('omnisonic'));
        case 'SupportedUriSchemes':
          return DBusGetPropertyResponse(
            DBusArray.string(['file', 'http', 'https']),
          );
        case 'SupportedMimeTypes':
          return DBusGetPropertyResponse(
            DBusArray.string(['audio/mpeg', 'audio/flac', 'audio/ogg']),
          );
        case 'CanQuit':
          return DBusGetPropertyResponse(const DBusBoolean(true));
        case 'CanRaise':
          return DBusGetPropertyResponse(const DBusBoolean(false));
      }
    } else if (interface == 'org.mpris.MediaPlayer2.Player') {
      switch (name) {
        case 'PlaybackStatus':
          final status = _currentState?.isPlaying ?? false
              ? 'Playing'
              : _currentState?.currentTrack != null
              ? 'Paused'
              : 'Stopped';
          AppLog.debug('MPRIS returning PlaybackStatus=$status');
          return DBusGetPropertyResponse(DBusString(status));
        case 'Metadata':
          final metadata = _getMetadata();
          AppLog.debug(
            'MPRIS returning metadata with ${(metadata.children as Map).length} fields',
          );
          return DBusGetPropertyResponse(metadata);
        case 'Position':
          final position = _currentState?.position.inMicroseconds ?? 0;
          return DBusGetPropertyResponse(DBusInt64(position));
        case 'CanGoNext':
          return DBusGetPropertyResponse(
            DBusBoolean((_currentState?.queue.length ?? 0) > 1),
          );
        case 'CanGoPrevious':
          return DBusGetPropertyResponse(
            DBusBoolean((_currentState?.queue.length ?? 0) > 1),
          );
        case 'CanPlay':
          return DBusGetPropertyResponse(const DBusBoolean(true));
        case 'CanPause':
          return DBusGetPropertyResponse(const DBusBoolean(true));
        case 'CanSeek':
          return DBusGetPropertyResponse(const DBusBoolean(false));
        case 'CanControl':
          return DBusGetPropertyResponse(const DBusBoolean(true));
      }
    }
    AppLog.warn('MPRIS unknown property: $interface.$name');
    return DBusMethodErrorResponse.unknownProperty();
  }

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    AppLog.debug('MPRIS getAllProperties($interface)');
    final properties = <String, DBusValue>{};

    if (interface == 'org.mpris.MediaPlayer2') {
      properties['Identity'] = DBusString('OmniSonic');
      properties['DesktopEntry'] = DBusString('omnisonic');
      properties['SupportedUriSchemes'] = DBusArray.string([
        'file',
        'http',
        'https',
      ]);
      properties['SupportedMimeTypes'] = DBusArray.string([
        'audio/mpeg',
        'audio/flac',
        'audio/ogg',
      ]);
      properties['CanQuit'] = const DBusBoolean(true);
      properties['CanRaise'] = const DBusBoolean(false);
    } else if (interface == 'org.mpris.MediaPlayer2.Player') {
      final status = _currentState?.isPlaying ?? false
          ? 'Playing'
          : _currentState?.currentTrack != null
          ? 'Paused'
          : 'Stopped';
      properties['PlaybackStatus'] = DBusString(status);
      properties['Metadata'] = _getMetadata();
      properties['Position'] = DBusInt64(
        _currentState?.position.inMicroseconds ?? 0,
      );
      properties['CanGoNext'] = DBusBoolean(
        (_currentState?.queue.length ?? 0) > 1,
      );
      properties['CanGoPrevious'] = DBusBoolean(
        (_currentState?.queue.length ?? 0) > 1,
      );
      properties['CanPlay'] = const DBusBoolean(true);
      properties['CanPause'] = const DBusBoolean(true);
      properties['CanSeek'] = const DBusBoolean(false);
      properties['CanControl'] = const DBusBoolean(true);
      AppLog.debug('MPRIS returning ${properties.length} properties');
    }

    return DBusGetAllPropertiesResponse(properties);
  }

  DBusDict _getMetadata() {
    final track = _currentState?.currentTrack;
    if (track == null) {
      return DBusDict.stringVariant({});
    }

    final metadata = <String, DBusValue>{
      'mpris:trackid': DBusObjectPath('/org/omnisonic/track/${track.id}'),
      'xesam:title': DBusString(track.title),
      'xesam:artist': DBusArray.string([track.artist]),
      'xesam:album': DBusString(track.album),
      'mpris:length': DBusInt64(_currentState!.duration.inMicroseconds),
    };

    if (track.coverArtUrl != null) {
      metadata['mpris:artUrl'] = DBusString(track.coverArtUrl!);
    }

    return DBusDict.stringVariant(metadata);
  }

  void _updateMprisMetadata(PlaybackState state) {
    if (_client == null) return;

    try {
      AppLog.debug('Updating MPRIS metadata');

      // Emit property changed signal
      emitPropertiesChanged(
        'org.mpris.MediaPlayer2.Player',
        changedProperties: {
          'PlaybackStatus': DBusString(
            state.isPlaying
                ? 'Playing'
                : state.currentTrack != null
                ? 'Paused'
                : 'Stopped',
          ),
          'Metadata': _getMetadata(),
          'Position': DBusInt64(state.position.inMicroseconds),
          'CanGoNext': DBusBoolean(state.queue.length > 1),
          'CanGoPrevious': DBusBoolean(state.queue.length > 1),
        },
      );
    } catch (e) {
      AppLog.warn('Failed to update MPRIS metadata: $e');
    }
  }

  void dispose() {
    _playbackStateSubscription?.cancel();
    _client?.close();
  }
}
