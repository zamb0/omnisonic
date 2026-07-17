import 'package:equatable/equatable.dart';

class Playlist extends Equatable {
  const Playlist({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.trackIds = const [],
    this.duration,
    this.isPublic = false,
    this.coverArtUrl,
    this.owner,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final List<String> trackIds;
  final Duration? duration;
  final bool isPublic;
  final String? coverArtUrl;
  final String? owner;

  /// Validates that the playlist has all required fields
  bool get isValid {
    return id.isNotEmpty && name.isNotEmpty;
  }

  /// Returns the number of tracks in the playlist
  int get trackCount => trackIds.length;

  /// Returns true if the playlist is empty
  bool get isEmpty => trackIds.isEmpty;

  /// Returns true if the playlist is not empty
  bool get isNotEmpty => trackIds.isNotEmpty;

  /// Adds a track ID to the playlist
  Playlist addTrack(String trackId) {
    if (trackIds.contains(trackId)) return this;

    return copyWith(
      trackIds: [...trackIds, trackId],
      updatedAt: DateTime.now(),
    );
  }

  /// Removes a track ID from the playlist
  Playlist removeTrack(String trackId) {
    if (!trackIds.contains(trackId)) return this;

    final newTrackIds = List<String>.from(trackIds);
    newTrackIds.remove(trackId);

    return copyWith(trackIds: newTrackIds, updatedAt: DateTime.now());
  }

  /// Reorders tracks in the playlist
  Playlist reorderTracks(List<String> newTrackIds) {
    // Validate that all track IDs are present
    if (newTrackIds.length != trackIds.length ||
        !newTrackIds.every((id) => trackIds.contains(id))) {
      throw ArgumentError('Invalid track IDs for reordering');
    }

    return copyWith(trackIds: newTrackIds, updatedAt: DateTime.now());
  }

  /// Moves a track from one position to another
  Playlist moveTrack(int fromIndex, int toIndex) {
    if (fromIndex < 0 ||
        fromIndex >= trackIds.length ||
        toIndex < 0 ||
        toIndex >= trackIds.length) {
      throw RangeError('Invalid index for moving track');
    }

    final newTrackIds = List<String>.from(trackIds);
    final trackId = newTrackIds.removeAt(fromIndex);
    newTrackIds.insert(toIndex, trackId);

    return copyWith(trackIds: newTrackIds, updatedAt: DateTime.now());
  }

  /// Creates a copy of this playlist with updated fields
  Playlist copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    List<String>? trackIds,
    Duration? duration,
    bool? isPublic,
    String? coverArtUrl,
    String? owner,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      trackIds: trackIds ?? this.trackIds,
      duration: duration ?? this.duration,
      isPublic: isPublic ?? this.isPublic,
      coverArtUrl: coverArtUrl ?? this.coverArtUrl,
      owner: owner ?? this.owner,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    createdAt,
    updatedAt,
    description,
    trackIds,
    duration,
    isPublic,
    coverArtUrl,
    owner,
  ];

  @override
  String toString() =>
      'Playlist(id: $id, name: $name, trackCount: $trackCount)';
}
