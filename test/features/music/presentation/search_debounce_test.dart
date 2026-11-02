import 'package:flutter_test/flutter_test.dart';
import 'package:omnisonic/core/errors/errors.dart';
import 'package:omnisonic/core/usecases/usecases.dart';
import 'package:omnisonic/features/music/presentation/bloc/search_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CountingSearch extends Fake implements SearchMusicUseCase {
  final queries = <String>[];

  @override
  Future<Result<SearchResults>> call(SearchMusicParams params) async {
    queries.add(params.query);
    return ResultHelper.success(const SearchResults.empty());
  }
}

/// #56: queries were debounced but clearing was not, so typing and clearing
/// within 300ms brought the old results back into an empty field.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('clearing before the debounce fires drops the pending query', () async {
    final search = _CountingSearch();
    final bloc = SearchBloc(search)
      ..add(const SearchQueryChanged('coltrane'))
      ..add(const SearchCleared());

    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(search.queries, isEmpty);
    expect(bloc.state.query, '');
    expect(bloc.state.status, SearchStatus.initial);
    await bloc.close();
  });

  test('only the last of several quick queries runs', () async {
    final search = _CountingSearch();
    final bloc = SearchBloc(search)
      ..add(const SearchQueryChanged('c'))
      ..add(const SearchQueryChanged('co'))
      ..add(const SearchQueryChanged('col'));

    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(search.queries, ['col']);
    await bloc.close();
  });
}
