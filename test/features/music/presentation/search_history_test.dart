import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:omnisonic/core/usecases/usecases.dart';
import 'package:omnisonic/features/music/presentation/bloc/search_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UnusedSearchUseCase extends Mock implements SearchMusicUseCase {}

/// Recent searches used to live only in memory and vanished on restart.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('history survives a new bloc, like an app restart', () async {
    final first = SearchBloc(_UnusedSearchUseCase());
    first
      ..add(const SearchHistoryAdded('miles davis'))
      ..add(const SearchHistoryAdded('coltrane'));
    await pumpEventQueue();
    await first.close();

    final second = SearchBloc(_UnusedSearchUseCase());
    await pumpEventQueue();

    expect(second.state.searchHistory, ['coltrane', 'miles davis']);
    await second.close();
  });

  test('clearing the history clears what is saved too', () async {
    final first = SearchBloc(_UnusedSearchUseCase())
      ..add(const SearchHistoryAdded('miles davis'));
    await pumpEventQueue();
    first.add(const SearchHistoryCleared());
    await pumpEventQueue();
    await first.close();

    final second = SearchBloc(_UnusedSearchUseCase());
    await pumpEventQueue();

    expect(second.state.searchHistory, isEmpty);
    await second.close();
  });
}
