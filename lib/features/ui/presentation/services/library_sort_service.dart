import '../../../../core/entities/entities.dart';
import '../models/sort_option.dart';

/// Sorting for the library's lists.
class LibrarySortService {
  const LibrarySortService._();

  /// The key names are compared by: case- and accent-insensitive, with a
  /// leading "The " ignored — so "the Beatles", "Émilie" and "abba" land
  /// where a person would look for them. Raw `compareTo` put every
  /// lowercase and accented title after Z.
  static String sortKey(String name) {
    var key = name.trim().toLowerCase();
    for (final (from, to) in _folds) {
      if (key.contains(from)) key = key.replaceAll(from, to);
    }
    if (key.startsWith('the ') && key.length > 4) key = key.substring(4);
    return key;
  }

  static int compareNames(String a, String b) {
    final byKey = sortKey(a).compareTo(sortKey(b));
    return byKey != 0 ? byKey : a.compareTo(b);
  }

  static List<Album> sortAlbums(List<Album> albums, SortOption option) {
    int compare(Album a, Album b) => switch (option.field) {
      SortField.title => compareNames(a.title, b.title),
      SortField.artist => _then(
        compareNames(a.artist, b.artist),
        () => (a.year ?? 0).compareTo(b.year ?? 0),
      ),
      SortField.year => (a.year ?? -1).compareTo(b.year ?? -1),
      SortField.dateAdded => a.lastModified.compareTo(b.lastModified),
    };
    return _sorted(
      albums,
      option,
      compare,
      (a, b) => compareNames(a.title, b.title),
    );
  }

  static List<Artist> sortArtists(List<Artist> artists, SortOption option) {
    int compare(Artist a, Artist b) => switch (option.field) {
      SortField.title || SortField.artist => compareNames(a.name, b.name),
      SortField.year => 0,
      SortField.dateAdded => a.lastModified.compareTo(b.lastModified),
    };
    return _sorted(
      artists,
      option,
      compare,
      (a, b) => compareNames(a.name, b.name),
    );
  }

  static List<T> _sorted<T>(
    List<T> items,
    SortOption option,
    int Function(T, T) compare,
    int Function(T, T) tieBreak,
  ) {
    final sorted = List<T>.of(items);
    sorted.sort((a, b) {
      final primary = option.descending ? compare(b, a) : compare(a, b);
      return primary != 0 ? primary : tieBreak(a, b);
    });
    return sorted;
  }

  static int _then(int first, int Function() next) =>
      first != 0 ? first : next();

  /// Accented Latin letters folded to their base letter.
  static const List<(String, String)> _folds = [
    ('à', 'a'),
    ('á', 'a'),
    ('â', 'a'),
    ('ã', 'a'),
    ('ä', 'a'),
    ('å', 'a'),
    ('æ', 'ae'),
    ('ç', 'c'),
    ('è', 'e'),
    ('é', 'e'),
    ('ê', 'e'),
    ('ë', 'e'),
    ('ì', 'i'),
    ('í', 'i'),
    ('î', 'i'),
    ('ï', 'i'),
    ('ñ', 'n'),
    ('ò', 'o'),
    ('ó', 'o'),
    ('ô', 'o'),
    ('õ', 'o'),
    ('ö', 'o'),
    ('ø', 'o'),
    ('œ', 'oe'),
    ('ù', 'u'),
    ('ú', 'u'),
    ('û', 'u'),
    ('ü', 'u'),
    ('ý', 'y'),
    ('ÿ', 'y'),
    ('ß', 'ss'),
    ('ł', 'l'),
    ('ś', 's'),
    ('š', 's'),
    ('ž', 'z'),
    ('ź', 'z'),
    ('ż', 'z'),
    ('č', 'c'),
    ('ć', 'c'),
    ('ř', 'r'),
    ('ě', 'e'),
    ('ę', 'e'),
    ('ą', 'a'),
    ('ő', 'o'),
    ('ű', 'u'),
    ('ğ', 'g'),
    ('ı', 'i'),
    ('ş', 's'),
  ];
}
