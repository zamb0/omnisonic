import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/features/ui/presentation/models/sort_option.dart';
import 'package:omnisonic/features/ui/presentation/services/library_sort_service.dart';

import '../../helpers/entity_factories.dart';

/// #62: raw compareTo put lowercase and accented titles after Z.
void main() {
  List<String> titles(List<String> input, SortOption option) =>
      LibrarySortService.sortAlbums([
        for (final (i, t) in input.indexed)
          testAlbum(id: 'server1_a$i', title: t),
      ], option).map((a) => a.title).toList();

  test('case- and accent-insensitive, ignoring a leading "The"', () {
    expect(
      titles([
        'Zebra',
        'the Beatles',
        'Émilie',
        'abba',
        'Dune',
      ], SortOption.alphabetical),
      ['abba', 'the Beatles', 'Dune', 'Émilie', 'Zebra'],
    );
  });

  test('descending reverses the order', () {
    expect(
      titles([
        'b',
        'a',
        'c',
      ], const SortOption(SortField.title, descending: true)),
      ['c', 'b', 'a'],
    );
  });

  test('sortKey folds accents and articles', () {
    expect(LibrarySortService.sortKey('The Öresund'), 'oresund');
  });
}
