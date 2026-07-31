import 'package:equatable/equatable.dart';
import 'audio_quality.dart';

class Track extends Equatable {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.serverId,
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
    this.isCached = false,
    this.cachePath,
    this.isStarred = false,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String serverId;
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

  /// Validates that the track has all required fields
  bool get isValid {
    return id.isNotEmpty &&
        title.isNotEmpty &&
        artist.isNotEmpty &&
        album.isNotEmpty &&
        duration.inMilliseconds > 0 &&
        serverId.isNotEmpty &&
        streamUrl.isNotEmpty;
  }

  /// Returns a similarity score with another track for deduplication
  double similarityScore(Track other) {
    if (id == other.id && serverId == other.serverId) return 1.0;

    double score = 0.0;

    // Title similarity (most important)
    if (_normalizeString(title) == _normalizeString(other.title)) {
      score += 0.4;
    }

    // Artist similarity
    if (_normalizeString(artist) == _normalizeString(other.artist)) {
      score += 0.3;
    }

    // Album similarity
    if (_normalizeString(album) == _normalizeString(other.album)) {
      score += 0.2;
    }

    // Duration similarity (within 5 seconds)
    final durationDiff = (duration.inSeconds - other.duration.inSeconds).abs();
    if (durationDiff <= 5) {
      score += 0.1;
    }

    return score;
  }

  String _normalizeString(String input) {
    return input.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');
  }

  /// Creates a copy of this track with updated fields
  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? serverId,
    String? streamUrl,
    AudioQuality? quality,
    DateTime? lastModified,
    String? albumId,
    String? artistId,
    int? trackNumber,
    int? discNumber,
    int? year,
    String? genre,
    int? fileSize,
    String? coverArtUrl,
    bool? isCached,
    String? cachePath,
    bool? isStarred,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      serverId: serverId ?? this.serverId,
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
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    artist,
    album,
    duration,
    serverId,
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
  String toString() =>
      'Track(id: $id, title: $title, artist: $artist, album: $album)';
}
