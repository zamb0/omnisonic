import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/entities/entities.dart';
import '../../../../core/usecases/usecases.dart';

/// BLoC for managing real-time search functionality
///
/// Handles:
/// - Real-time search with debouncing
/// - Search result filtering and sorting
/// - Search history management
/// - Advanced search filters
@injectable
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this._searchMusicUseCase) : super(const SearchState.initial()) {
    on<SearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: _debounceTransformer(),
    );
    on<SearchFiltersChanged>(_onSearchFiltersChanged);
    on<SearchCleared>(_onSearchCleared);
    on<SearchHistoryAdded>(_onSearchHistoryAdded);
    on<SearchHistoryCleared>(_onSearchHistoryCleared);
    on<SearchSuggestionSelected>(_onSearchSuggestionSelected);
  }

  final SearchMusicUseCase _searchMusicUseCase;

  // Debounce transformer for search queries
  EventTransformer<T> _debounceTransformer<T>() {
    return (events, mapper) => events
        .debounceTime(const Duration(milliseconds: 300))
        .asyncExpand(mapper);
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      emit(
        state.copyWith(
          status: SearchStatus.initial,
          query: '',
          results: null,
          errorMessage: null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: SearchStatus.loading,
        query: query,
        errorMessage: null,
      ),
    );

    try {
      final params = SearchMusicParams(
        query: query,
        searchTypes: state.filters.searchTypes,
        genre: state.filters.genre,
        year: state.filters.year,
        serverId: state.filters.serverId,
        minQuality: state.filters.minQuality,
        maxResults: state.filters.maxResults,
      );

      final result = await _searchMusicUseCase(params);

      result.fold(
        (failure) => emit(
          state.copyWith(
            status: SearchStatus.failure,
            errorMessage: failure.message,
          ),
        ),
        (results) => emit(
          state.copyWith(
            status: SearchStatus.success,
            results: results,
            errorMessage: null,
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SearchStatus.failure,
          errorMessage: 'Unexpected error during search: $e',
        ),
      );
    }
  }

  void _onSearchFiltersChanged(
    SearchFiltersChanged event,
    Emitter<SearchState> emit,
  ) {
    emit(state.copyWith(filters: event.filters));

    // Re-run search with new filters if there's an active query
    if (state.query.isNotEmpty) {
      add(SearchQueryChanged(state.query));
    }
  }

  void _onSearchCleared(SearchCleared event, Emitter<SearchState> emit) {
    emit(
      state.copyWith(
        status: SearchStatus.initial,
        query: '',
        results: null,
        errorMessage: null,
      ),
    );
  }

  void _onSearchHistoryAdded(
    SearchHistoryAdded event,
    Emitter<SearchState> emit,
  ) {
    final updatedHistory = List<String>.from(state.searchHistory);

    // Remove if already exists to avoid duplicates
    updatedHistory.remove(event.query);

    // Add to the beginning
    updatedHistory.insert(0, event.query);

    // Keep only the last 20 searches
    if (updatedHistory.length > 20) {
      updatedHistory.removeRange(20, updatedHistory.length);
    }

    emit(state.copyWith(searchHistory: updatedHistory));
  }

  void _onSearchHistoryCleared(
    SearchHistoryCleared event,
    Emitter<SearchState> emit,
  ) {
    emit(state.copyWith(searchHistory: const []));
  }

  void _onSearchSuggestionSelected(
    SearchSuggestionSelected event,
    Emitter<SearchState> emit,
  ) {
    add(SearchQueryChanged(event.suggestion));
    add(SearchHistoryAdded(event.suggestion));
  }
}

// Events
abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class SearchFiltersChanged extends SearchEvent {
  const SearchFiltersChanged(this.filters);

  final SearchFilters filters;

  @override
  List<Object?> get props => [filters];
}

class SearchCleared extends SearchEvent {
  const SearchCleared();
}

class SearchHistoryAdded extends SearchEvent {
  const SearchHistoryAdded(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class SearchHistoryCleared extends SearchEvent {
  const SearchHistoryCleared();
}

class SearchSuggestionSelected extends SearchEvent {
  const SearchSuggestionSelected(this.suggestion);

  final String suggestion;

  @override
  List<Object?> get props => [suggestion];
}

// State
enum SearchStatus { initial, loading, success, failure }

class SearchFilters extends Equatable {
  const SearchFilters({
    this.searchTypes = const [
      SearchType.tracks,
      SearchType.albums,
      SearchType.artists,
    ],
    this.genre,
    this.year,
    this.serverId,
    this.minQuality,
    this.maxResults,
  });

  final List<SearchType> searchTypes;
  final String? genre;
  final int? year;
  final String? serverId;
  final AudioQuality? minQuality;
  final int? maxResults;

  SearchFilters copyWith({
    List<SearchType>? searchTypes,
    String? genre,
    int? year,
    String? serverId,
    AudioQuality? minQuality,
    int? maxResults,
  }) {
    return SearchFilters(
      searchTypes: searchTypes ?? this.searchTypes,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      serverId: serverId ?? this.serverId,
      minQuality: minQuality ?? this.minQuality,
      maxResults: maxResults ?? this.maxResults,
    );
  }

  @override
  List<Object?> get props => [
    searchTypes,
    genre,
    year,
    serverId,
    minQuality,
    maxResults,
  ];
}

class SearchState extends Equatable {
  const SearchState({
    required this.status,
    required this.query,
    required this.filters,
    required this.searchHistory,
    this.results,
    this.errorMessage,
  });

  const SearchState.initial()
    : status = SearchStatus.initial,
      query = '',
      filters = const SearchFilters(),
      searchHistory = const [],
      results = null,
      errorMessage = null;

  final SearchStatus status;
  final String query;
  final SearchFilters filters;
  final List<String> searchHistory;
  final SearchResults? results;
  final String? errorMessage;

  bool get isInitial => status == SearchStatus.initial;
  bool get isLoading => status == SearchStatus.loading;
  bool get isSuccess => status == SearchStatus.success;
  bool get isFailure => status == SearchStatus.failure;
  bool get hasResults => results != null && results!.isNotEmpty;
  bool get hasQuery => query.isNotEmpty;
  bool get hasHistory => searchHistory.isNotEmpty;
  bool get hasError => errorMessage != null;

  // Result getters
  List<Track> get tracks => results?.tracks ?? [];
  List<Album> get albums => results?.albums ?? [];
  List<Artist> get artists => results?.artists ?? [];
  int get totalResults => results?.totalResults ?? 0;
  bool get hasTracks => results?.hasTracks ?? false;
  bool get hasAlbums => results?.hasAlbums ?? false;
  bool get hasArtists => results?.hasArtists ?? false;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    SearchFilters? filters,
    List<String>? searchHistory,
    SearchResults? results,
    String? errorMessage,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      filters: filters ?? this.filters,
      searchHistory: searchHistory ?? this.searchHistory,
      results: results ?? this.results,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    query,
    filters,
    searchHistory,
    results,
    errorMessage,
  ];
}
