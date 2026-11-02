/// Represents a music genre with its statistics
class Genre {
  const Genre({
    required this.name,
    required this.songCount,
    required this.albumCount,
  });

  /// The name of the genre
  final String name;

  /// Number of songs in this genre
  final int songCount;

  /// Number of albums in this genre
  final int albumCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Genre && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() =>
      'Genre(name: $name, songs: $songCount, albums: $albumCount)';

  Genre copyWith({String? name, int? songCount, int? albumCount}) {
    return Genre(
      name: name ?? this.name,
      songCount: songCount ?? this.songCount,
      albumCount: albumCount ?? this.albumCount,
    );
  }
}
