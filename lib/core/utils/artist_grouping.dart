import '../entities/album.dart';
import '../entities/artist.dart';
import 'album_grouping.dart';

/// Result of [dedupeArtists]: one representative per artist name, plus the
/// IDs of every per-server copy it stands for, keyed by representative ID.
typedef ArtistDedupeResult = ({
  List<Artist> artists,
  Map<String, List<String>> memberIds,
});

/// Groups artists by normalized name.
///
/// Albums were already deduplicated across servers, artists were not: an
/// artist on two servers showed up twice, each with half the discography.
String artistGroupKey(String name) =>
    name.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '');

/// Collapses same-artist-on-multiple-servers copies into one.
///
/// The representative is the copy with an image, then the most albums. Its
/// album count is recomputed from [albums] across every copy, counting an
/// album shared by two servers once.
ArtistDedupeResult dedupeArtists(List<Artist> artists, List<Album> albums) {
  final grouped = <String, List<Artist>>{};
  for (final artist in artists) {
    grouped.putIfAbsent(artistGroupKey(artist.name), () => []).add(artist);
  }

  final albumsByArtistId = <String, List<Album>>{};
  for (final album in albums) {
    final artistId = album.artistId;
    if (artistId == null) continue;
    albumsByArtistId.putIfAbsent(artistId, () => []).add(album);
  }

  final deduped = <Artist>[];
  final memberIds = <String, List<String>>{};
  for (final group in grouped.values) {
    if (group.length == 1) {
      deduped.add(group.single);
      memberIds[group.single.id] = [group.single.id];
      continue;
    }

    group.sort((a, b) {
      final aImage = a.imageUrl != null ? 1 : 0;
      final bImage = b.imageUrl != null ? 1 : 0;
      if (aImage != bImage) return bImage.compareTo(aImage);
      return (b.albumCount ?? 0).compareTo(a.albumCount ?? 0);
    });
    final best = group.first;

    final albumKeys = {
      for (final artist in group)
        for (final album in albumsByArtistId[artist.id] ?? const <Album>[])
          albumGroupKey(album),
    };
    final fallbackCount = group
        .map((a) => a.albumCount ?? 0)
        .fold(0, (a, b) => a > b ? a : b);

    deduped.add(
      best.copyWith(
        albumCount: albumKeys.isEmpty ? fallbackCount : albumKeys.length,
      ),
    );
    memberIds[best.id] = [for (final artist in group) artist.id];
  }
  return (artists: deduped, memberIds: memberIds);
}
