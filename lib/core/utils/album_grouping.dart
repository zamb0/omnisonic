import '../entities/album.dart';

/// Result of [dedupeAlbumsByServer]: one representative album per
/// (title, artist, year) group, plus which servers each representative was
/// found on.
typedef AlbumDedupeResult = ({
  List<Album> albums,
  Map<String, List<String>> sourceServerIds,
});

/// Collapses same-album-on-multiple-servers duplicates down to the "best"
/// copy (most tracks, then most recently modified), while recording which
/// servers each surviving album was found on — used for corner/source-count
/// badges in the library grid and search results.
AlbumDedupeResult dedupeAlbumsByServer(List<Album> albums) {
  final grouped = <String, List<Album>>{};
  for (final album in albums) {
    final key = albumGroupKey(album);
    grouped.putIfAbsent(key, () => []).add(album);
  }

  final deduped = <Album>[];
  final sourceServerIds = <String, List<String>>{};
  for (final group in grouped.values) {
    group.sort((a, b) {
      final aTracks = a.trackCount ?? 0;
      final bTracks = b.trackCount ?? 0;
      if (aTracks != bTracks) {
        return bTracks.compareTo(aTracks);
      }
      return b.lastModified.compareTo(a.lastModified);
    });
    final best = group.first;
    deduped.add(best);
    sourceServerIds[best.id] = group.map((a) => a.serverId).toList();
  }
  return (albums: deduped, sourceServerIds: sourceServerIds);
}

String albumGroupKey(Album album) {
  final title = _normalizeAlbumKey(album.title);
  final artist = album.artist; // Exact match for artist
  final year = album.year?.toString() ?? '';
  return '$title|$artist|$year';
}

String _normalizeAlbumKey(String input) {
  return input.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');
}
