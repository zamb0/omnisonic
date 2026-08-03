import 'package:bloc_test/bloc_test.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/usecases/search_music_use_case.dart';
import 'package:omnisonic/features/music/presentation/bloc/search_bloc.dart';

/// Stand-ins for the event-driven half of the app's state management.
///
/// Unlike the view models, blocs are naturally driven from outside: a test
/// only needs to push states and record the events the widget dispatched.
/// `bloc_test`'s [MockBloc] does exactly that, so these are thin wrappers
/// that add the state constructors the pages care about.

class FakeSearchBloc extends MockBloc<SearchEvent, SearchState>
    implements SearchBloc {}

/// The four states `search_page` branches on, built without touching the
/// real use case.
class SearchStates {
  static const initial = SearchState.initial();

  static SearchState loading(String query) => SearchState(
    status: SearchStatus.loading,
    query: query,
    filters: const SearchFilters(),
    searchHistory: const [],
  );

  static SearchState success({
    String query = 'test',
    List<Track> tracks = const [],
    List<Album> albums = const [],
    List<Artist> artists = const [],
    List<String> history = const [],
  }) => SearchState(
    status: SearchStatus.success,
    query: query,
    filters: const SearchFilters(),
    searchHistory: history,
    results: SearchResults(
      query: query,
      tracks: tracks,
      albums: albums,
      artists: artists,
      // The page renders this as "N results merged from M results", so it
      // has to reflect the pre-dedup count, not the list lengths.
      totalResults: tracks.length + albums.length + artists.length,
      searchTime: DateTime(2026, 1, 1),
    ),
  );

  static SearchState failure(String message, {String query = 'test'}) =>
      SearchState(
        status: SearchStatus.failure,
        query: query,
        filters: const SearchFilters(),
        searchHistory: const [],
        errorMessage: message,
      );
}
