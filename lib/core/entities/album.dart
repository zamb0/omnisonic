import 'package:equatable/equatable.dart';

class Album extends Equatable {
  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.serverId,
    required this.lastModified,
    this.artistId,
    this.year,
    this.genre,
    this.trackCount,
    this.duration,
    this.coverArtUrl,
    this.description,
    this.isStarred = false,
  });

  final String id;
  final String title;
  final String artist;
  final String serverId;
  final DateTime lastModified;
  final String? artistId;
  final int? year;
  final String? genre;
  final int? trackCount;
  final Duration? duration;
  final String? coverArtUrl;
  final String? description;
  final bool isStarred;

  /// Validates that the album has all required fields
  bool get isValid {
    return id.isNotEmpty &&
        title.isNotEmpty &&
        artist.isNotEmpty &&
        serverId.isNotEmpty;
  }

  /// Returns a similarity score with another album for deduplication
  double similarityScore(Album other) {
    if (id == other.id && serverId == other.serverId) return 1.0;

    double score = 0.0;

    // Title similarity (most important)
    if (_normalizeString(title) == _normalizeString(other.title)) {
      score += 0.5;
    }

    // Artist similarity
    if (_normalizeString(artist) == _normalizeString(other.artist)) {
      score += 0.3;
    }

    // Year similarity
    if (year != null && other.year != null && year == other.year) {
      score += 0.2;
    }

    return score;
  }

  String _normalizeString(String input) {
    return input.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');
  }

  /// Creates a copy of this album with updated fields
  Album copyWith({
    String? id,
    String? title,
    String? artist,
    String? serverId,
    DateTime? lastModified,
    String? artistId,
    int? year,
    String? genre,
    int? trackCount,
    Duration? duration,
    String? coverArtUrl,
    String? description,
    bool? isStarred,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      serverId: serverId ?? this.serverId,
      lastModified: lastModified ?? this.lastModified,
      artistId: artistId ?? this.artistId,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      trackCount: trackCount ?? this.trackCount,
      duration: duration ?? this.duration,
      coverArtUrl: coverArtUrl ?? this.coverArtUrl,
      description: description ?? this.description,
      isStarred: isStarred ?? this.isStarred,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        serverId,
        lastModified,
        artistId,
        year,
        genre,
        trackCount,
        duration,
        coverArtUrl,
        description,
        isStarred,
      ];

  @override
  String toString() => 'Album(id: $id, title: $title, artist: $artist, year: $year)';
}