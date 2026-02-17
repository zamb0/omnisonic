import 'package:equatable/equatable.dart';

class Artist extends Equatable {
  const Artist({
    required this.id,
    required this.name,
    required this.serverId,
    required this.lastModified,
    this.albumCount,
    this.biography,
    this.imageUrl,
    this.musicBrainzId,
    this.lastFmUrl,
  });

  final String id;
  final String name;
  final String serverId;
  final DateTime lastModified;
  final int? albumCount;
  final String? biography;
  final String? imageUrl;
  final String? musicBrainzId;
  final String? lastFmUrl;

  /// Validates that the artist has all required fields
  bool get isValid {
    return id.isNotEmpty &&
        name.isNotEmpty &&
        serverId.isNotEmpty;
  }

  /// Returns a similarity score with another artist for deduplication
  double similarityScore(Artist other) {
    if (id == other.id && serverId == other.serverId) return 1.0;

    double score = 0.0;

    // Name similarity (most important)
    if (_normalizeString(name) == _normalizeString(other.name)) {
      score += 0.8;
    }

    // MusicBrainz ID match (if available)
    if (musicBrainzId != null && 
        other.musicBrainzId != null && 
        musicBrainzId == other.musicBrainzId) {
      score += 0.2;
    }

    return score;
  }

  String _normalizeString(String input) {
    return input.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');
  }

  /// Creates a copy of this artist with updated fields
  Artist copyWith({
    String? id,
    String? name,
    String? serverId,
    DateTime? lastModified,
    int? albumCount,
    String? biography,
    String? imageUrl,
    String? musicBrainzId,
    String? lastFmUrl,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      serverId: serverId ?? this.serverId,
      lastModified: lastModified ?? this.lastModified,
      albumCount: albumCount ?? this.albumCount,
      biography: biography ?? this.biography,
      imageUrl: imageUrl ?? this.imageUrl,
      musicBrainzId: musicBrainzId ?? this.musicBrainzId,
      lastFmUrl: lastFmUrl ?? this.lastFmUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        serverId,
        lastModified,
        albumCount,
        biography,
        imageUrl,
        musicBrainzId,
        lastFmUrl,
      ];

  @override
  String toString() => 'Artist(id: $id, name: $name, albumCount: $albumCount)';
}