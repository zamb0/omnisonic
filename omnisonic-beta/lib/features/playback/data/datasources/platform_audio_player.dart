import 'dart:async';
import 'dart:io' show Platform;

import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:audioplayers/audioplayers.dart' as audio_players;

/// Platform-agnostic audio player interface
abstract class PlatformAudioPlayer {
  factory PlatformAudioPlayer() {
    if (Platform.isLinux) {
      return _AudioPlayersImpl();
    } else {
      return _JustAudioImpl();
    }
  }

  Future<void> setUrl(String url);
  Future<void> setFilePath(String path);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  
  Stream<bool> get playingStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<PlayerState> get playerStateStream;
  
  bool get playing;
  Duration get position;
  Duration? get duration;
  
  void dispose();
}

enum PlayerState {
  idle,
  loading,
  buffering,
  ready,
  completed,
}

/// Implementation using just_audio (Android, iOS, macOS, Windows)
class _JustAudioImpl implements PlatformAudioPlayer {
  final just_audio.AudioPlayer _player = just_audio.AudioPlayer();
  
  @override
  Future<void> setUrl(String url) async {
    await _player.setUrl(url);
  }
  
  @override
  Future<void> setFilePath(String path) async {
    await _player.setFilePath(path);
  }
  
  @override
  Future<void> play() => _player.play();
  
  @override
  Future<void> pause() => _player.pause();
  
  @override
  Future<void> stop() => _player.stop();
  
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  
  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);
  
  @override
  Stream<bool> get playingStream => _player.playingStream;
  
  @override
  Stream<Duration> get positionStream => _player.positionStream;
  
  @override
  Stream<Duration?> get durationStream => _player.durationStream;
  
  @override
  Stream<PlayerState> get playerStateStream => _player.processingStateStream.map((state) {
    switch (state) {
      case just_audio.ProcessingState.idle:
        return PlayerState.idle;
      case just_audio.ProcessingState.loading:
        return PlayerState.loading;
      case just_audio.ProcessingState.buffering:
        return PlayerState.buffering;
      case just_audio.ProcessingState.ready:
        return PlayerState.ready;
      case just_audio.ProcessingState.completed:
        return PlayerState.completed;
    }
  });
  
  @override
  bool get playing => _player.playing;
  
  @override
  Duration get position => _player.position;
  
  @override
  Duration? get duration => _player.duration;
  
  @override
  void dispose() => _player.dispose();
}

/// Implementation using audioplayers (Linux)
class _AudioPlayersImpl implements PlatformAudioPlayer {
  final audio_players.AudioPlayer _player = audio_players.AudioPlayer();
  
  final StreamController<bool> _playingController = StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController = StreamController<Duration?>.broadcast();
  final StreamController<PlayerState> _stateController = StreamController<PlayerState>.broadcast();
  
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration? _duration;
  
  _AudioPlayersImpl() {
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == audio_players.PlayerState.playing;
      _playingController.add(_isPlaying);
      
      _stateController.add(_mapState(state));
    });
    
    _player.onPositionChanged.listen((position) {
      _position = position;
      _positionController.add(position);
    });
    
    _player.onDurationChanged.listen((duration) {
      _duration = duration;
      _durationController.add(duration);
    });
    
    _player.onPlayerComplete.listen((_) {
      _stateController.add(PlayerState.completed);
    });
  }
  
  PlayerState _mapState(audio_players.PlayerState state) {
    switch (state) {
      case audio_players.PlayerState.stopped:
        return PlayerState.idle;
      case audio_players.PlayerState.playing:
        return PlayerState.ready;
      case audio_players.PlayerState.paused:
        return PlayerState.ready;
      case audio_players.PlayerState.completed:
        return PlayerState.completed;
      case audio_players.PlayerState.disposed:
        return PlayerState.idle;
    }
  }
  
  @override
  Future<void> setUrl(String url) async {
    await _player.setSourceUrl(url);
  }
  
  @override
  Future<void> setFilePath(String path) async {
    await _player.setSourceDeviceFile(path);
  }
  
  @override
  Future<void> play() => _player.resume();
  
  @override
  Future<void> pause() => _player.pause();
  
  @override
  Future<void> stop() => _player.stop();
  
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  
  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);
  
  @override
  Stream<bool> get playingStream => _playingController.stream;
  
  @override
  Stream<Duration> get positionStream => _positionController.stream;
  
  @override
  Stream<Duration?> get durationStream => _durationController.stream;
  
  @override
  Stream<PlayerState> get playerStateStream => _stateController.stream;
  
  @override
  bool get playing => _isPlaying;
  
  @override
  Duration get position => _position;
  
  @override
  Duration? get duration => _duration;
  
  @override
  void dispose() {
    _player.dispose();
    _playingController.close();
    _positionController.close();
    _durationController.close();
    _stateController.close();
  }
}
