import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omnisonic/core/entities/entities.dart';
import 'package:omnisonic/core/usecases/search_music_use_case.dart';
import 'package:omnisonic/features/music/presentation/bloc/search_bloc.dart';

/// Stand-ins for the event-driven half of the app's state management.
///
/// A real [Bloc] rather than a mock, for the same reason the view model
/// fakes are hand-written: the widget subscribes to the state stream, so a
/// test needs [emitState] to actually push through it. Events the widget
/// dispatches land in [dispatched] instead of being handled.
class FakeSearchBloc extends Bloc<SearchEvent, SearchState>
    implements SearchBloc {
  FakeSearchBloc([SearchState? initialState])
    : super(initialState ?? const SearchState.initial()) {
    on<SearchEvent>((event, emit) => dispatched.add(event));
  }

  /// Every event the widget under test raised, in order.
  final dispatched = <SearchEvent>[];

  /// Pushes [state] through the stream the widget is listening to.
  void emitState(SearchState state) => emit(state);
}

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
