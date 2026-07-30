import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/movie/data/data_sources/movie_api.dart';
import 'package:movie_journal/features/movie/data/models/brief_movie.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';

enum SearchMovieMode { search, popular }

// Simplified state without manual async flags
class SearchMovieState {
  final List<BriefMovie> movies;
  final String query;
  final int page;
  final bool hasMore;
  final SearchMovieMode mode;

  SearchMovieState({
    this.movies = const [],
    this.query = '',
    this.page = 1,
    this.hasMore = true,
    this.mode = SearchMovieMode.popular,
  });

  SearchMovieState copyWith({
    List<BriefMovie>? movies,
    String? query,
    int? page,
    bool? hasMore,
    SearchMovieMode? mode,
  }) {
    final nextQuery = query ?? this.query;
    return SearchMovieState(
      movies: movies ?? this.movies,
      query: nextQuery,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      mode:
          mode ??
          (nextQuery.isEmpty
              ? SearchMovieMode.popular
              : SearchMovieMode.search),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchMovieState &&
          runtimeType == other.runtimeType &&
          listEquals(movies, other.movies) &&
          query == other.query &&
          page == other.page &&
          hasMore == other.hasMore &&
          mode == other.mode;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(movies), query, page, hasMore, mode);
}

bool movieIntegrityChecker(BriefMovie movie) =>
    movie.posterPath != null &&
    movie.overview.isNotEmpty &&
    movie.title.isNotEmpty;

class SearchMovieController extends AsyncNotifier<SearchMovieState> {
  // The debounce in MovieSearchBar does not serialize searches — a submit
  // right after a debounced fire produces overlapping requests, and TMDB
  // responses can come back out of order. A response (or failure) is applied
  // only if its id is still current; anything older is dropped.
  int _requestId = 0;
  CancelToken? _cancelToken;

  /// True while the response that produced [_requestId] is still awaited.
  bool _isStale(int id) => id != _requestId;

  @override
  Future<SearchMovieState> build() async {
    ref.onDispose(() => _cancelToken?.cancel());
    // Load initial popular movies
    final result = await ref.read(movieRepoProvider).popular(page: 1);
    return SearchMovieState(
      movies: result.results.where(movieIntegrityChecker).toList(),
      page: 2,
      hasMore: result.page < result.totalPages,
      mode: SearchMovieMode.popular,
    );
  }

  Future<void> search(String query) async {
    final id = ++_requestId;
    // Don't let the superseded request keep consuming the network; its state
    // write is already dead either way thanks to the id guard.
    _cancelToken?.cancel();
    final token = _cancelToken = CancelToken();

    // Riverpod merges this with the current state (copyWithPrevious under the
    // state setter), so listeners still see the previous list while loading —
    // MovieResultList opts in via skipLoadingOnReload.
    state = const AsyncLoading();
    final next = await AsyncValue.guard(() async {
      final repo = ref.read(movieRepoProvider);
      final result = query.isEmpty
          ? await repo.popular(page: 1, cancelToken: token)
          : await repo.search(query: query, page: 1, cancelToken: token);
      return SearchMovieState(
        movies: result.results.where(movieIntegrityChecker).toList(),
        query: query,
        page: 2,
        hasMore: result.page < result.totalPages,
        mode: query.isEmpty ? SearchMovieMode.popular : SearchMovieMode.search,
      );
    });
    if (_isStale(id)) return;
    state = next;
  }

  Future<void> loadMore() async {
    // While a reload is in flight the visible list is the *previous* query's
    // (preserved by copyWithPrevious), so paging from it would fetch pages
    // for a query the user has already left.
    if (state.isLoading) return;
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore) return;
    final id = _requestId;

    // Keep current state while loading more
    try {
      late final MovieListResponse result;
      if (currentState.query.isEmpty) {
        result = await ref.read(movieRepoProvider).popular(page: currentState.page);
      } else {
        result = await ref.read(movieRepoProvider).search(
          query: currentState.query,
          page: currentState.page,
        );
      }

      // A search() started while this page was in flight owns the state now.
      if (_isStale(id)) return;
      state = AsyncData(currentState.copyWith(
        movies: [
          ...currentState.movies,
          ...result.results.where(movieIntegrityChecker),
        ],
        page: currentState.page + 1,
        hasMore: result.page < result.totalPages,
      ));
    } catch (error, stackTrace) {
      if (_isStale(id)) return;
      // Keep the already-loaded pages: without copyWithPrevious the error
      // state has no value, so the list UI loses everything and a retried
      // loadMore() bails out at the `state.value == null` guard above.
      // copyWithPrevious is @internal in Riverpod 3, but it is also exactly
      // what the framework uses to represent "errored while holding data",
      // and no public constructor produces that state.
      state = AsyncError<SearchMovieState>(error, stackTrace)
          // ignore: invalid_use_of_internal_member
          .copyWithPrevious(state);
    }
  }

  void reset() {
    // The notifier instance (and these fields) survive invalidateSelf, so any
    // in-flight response must be orphaned before build() runs again.
    _requestId++;
    _cancelToken?.cancel();
    _cancelToken = null;
    ref.invalidateSelf();
  }
}
