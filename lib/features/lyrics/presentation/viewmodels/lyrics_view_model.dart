import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/repositories/lyrics_repository.dart';

@lazySingleton
class LyricsViewModel extends ChangeNotifier {
  LyricsViewModel(this._lyricsRepository);

  final LyricsRepository _lyricsRepository;

  Track? _track;
  LyricsData? _lyrics;
  LyricsOverride? _override;
  LyricsSource? _preferredSource;
  List<LyricsSearchResult> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _follow = true;
  int _offsetMs = 0;
  String? _errorMessage;

  Track? get track => _track;
  LyricsData? get lyrics => _lyrics;
  LyricsOverride? get override => _override;
  LyricsSource? get preferredSource => _preferredSource;
  List<LyricsSearchResult> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get follow => _follow;
  int get offsetMs => _offsetMs;
  String? get errorMessage => _errorMessage;

  Future<void> setTrack(Track? track) async {
    if (track?.id == _track?.id) return;

    _track = track;
    _lyrics = null;
    _override = null;
    _searchResults = [];
    _errorMessage = null;

    if (track == null) {
      notifyListeners();
      return;
    }

    final preferredResult = await _lyricsRepository.getPreferredSource();
    _preferredSource = preferredResult.valueOrNull;

    final overrideResult = await _lyricsRepository.getOverride(track.id);
    _override = overrideResult.valueOrNull;

    final offsetResult = await _lyricsRepository.getOffsetMs(track.id);
    _offsetMs = offsetResult.valueOrNull ?? 0;

    final cachedResult = await _lyricsRepository.getCachedLyrics(track.id);
    _lyrics = cachedResult.valueOrNull;

    notifyListeners();
    await _loadLyrics();
  }

  Future<void> refresh() async {
    await _loadLyrics(forceRefresh: true);
  }

  Future<void> searchLyrics({
    String? query,
    String? artist,
    String? title,
    String? album,
  }) async {
    if (_track == null) return;

    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _lyricsRepository.searchLyrics(
      artist: artist ?? _track!.artist,
      title: title ?? _track!.title,
      album: album ?? _track!.album,
      query: query,
    );

    _isSearching = false;
    result.fold(
      (failure) => _errorMessage = failure.message,
      (results) => _searchResults = results,
    );

    notifyListeners();
  }

  Future<void> applySearchResult(LyricsSearchResult result) async {
    if (_track == null) return;

    _override = LyricsOverride(
      id: result.id,
      title: result.title,
      artist: result.artist,
      source: result.source,
      isSynced: result.isSynced,
    );

    await _lyricsRepository.setOverride(_track!.id, _override);
    notifyListeners();
    await _loadLyrics(forceRefresh: true);
  }

  Future<void> clearOverride() async {
    if (_track == null) return;

    _override = null;
    await _lyricsRepository.setOverride(_track!.id, null);
    notifyListeners();
    await _loadLyrics(forceRefresh: true);
  }

  Future<void> setPreferredSource(LyricsSource? source) async {
    _preferredSource = source;
    await _lyricsRepository.setPreferredSource(source);
    notifyListeners();
    await _loadLyrics(forceRefresh: true);
  }

  void setFollow(bool value) {
    _follow = value;
    notifyListeners();
  }

  Future<void> adjustOffset(int deltaMs) async {
    if (_track == null) return;

    _offsetMs += deltaMs;
    await _lyricsRepository.setOffsetMs(_track!.id, _offsetMs);
    notifyListeners();
  }

  Future<void> resetOffset() async {
    if (_track == null) return;

    _offsetMs = 0;
    await _lyricsRepository.setOffsetMs(_track!.id, _offsetMs);
    notifyListeners();
  }

  Future<void> _loadLyrics({bool forceRefresh = false}) async {
    if (_track == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    Result<LyricsData?> result;

    if (_override != null) {
      result = await _lyricsRepository.getLyricsById(
        _override!.source,
        _override!.id,
        _track!,
      );
    } else if (!forceRefresh && _lyrics != null) {
      _isLoading = false;
      notifyListeners();
      return;
    } else {
      result = await _lyricsRepository.getBestLyrics(
        _track!,
        preferredSource: _preferredSource,
      );
    }

    _isLoading = false;

    result.fold(
      (failure) => _errorMessage = failure.message,
      (data) => _lyrics = data,
    );

    notifyListeners();
  }
}
