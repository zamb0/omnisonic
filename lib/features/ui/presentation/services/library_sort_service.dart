import '../../../../core/entities/entities.dart';
import '../models/sort_option.dart';

/// Service for sorting library items (albums, artists, tracks, playlists)
class LibrarySortService {
  /// Generic method to sort a list of items based on sort option
  static List<T> sortItems<T>({
    required List<T> items,
    required SortOption option,
    required Comparable Function(T) getTitle,
    required DateTime Function(T) getDate,
  }) {
    final sorted = List<T>.from(items);
    switch (option) {
      case SortOption.alphabetical:
        sorted.sort((a, b) => getTitle(a).compareTo(getTitle(b)));
        break;
      case SortOption.recentlyAdded:
        sorted.sort((a, b) => getDate(b).compareTo(getDate(a)));
        break;
    }
    return sorted;
  }

  /// Sort albums by the current sort option
  static List<Album> sortAlbums(List<Album> albums, SortOption option) {
    return sortItems<Album>(
      items: albums,
      option: option,
      getTitle: (album) => album.title,
      getDate: (album) => album.lastModified,
    );
  }

  /// Sort artists by the current sort option
  static List<Artist> sortArtists(List<Artist> artists, SortOption option) {
    return sortItems<Artist>(
      items: artists,
      option: option,
      getTitle: (artist) => artist.name,
      getDate: (artist) => artist.lastModified,
    );
  }

  /// Sort tracks by the current sort option
  static List<Track> sortTracks(List<Track> tracks, SortOption option) {
    return sortItems<Track>(
      items: tracks,
      option: option,
      getTitle: (track) => track.title,
      getDate: (track) => track.lastModified,
    );
  }

  /// Sort playlists by the current sort option
  static List<Playlist> sortPlaylists(
    List<Playlist> playlists,
    SortOption option,
  ) {
    return sortItems<Playlist>(
      items: playlists,
      option: option,
      getTitle: (playlist) => playlist.name,
      getDate: (playlist) => playlist.createdAt,
    );
  }
}
