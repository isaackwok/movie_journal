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
}

bool movieIntegrityChecker(BriefMovie movie) =>
    movie.posterPath != null &&
    movie.overview.isNotEmpty &&
    movie.title.isNotEmpty;

class SearchMovieController extends AsyncNotifier<SearchMovieState> {
  @override
  Future<SearchMovieState> build() async {
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
    if (query.isEmpty) {
      // Reset to popular movies
      state = const AsyncLoading();
      state = await AsyncValue.guard(() async {
        final result = await ref.read(movieRepoProvider).popular(page: 1);
        return SearchMovieState(
          movies: result.results.where(movieIntegrityChecker).toList(),
          page: 2,
          hasMore: result.page < result.totalPages,
          mode: SearchMovieMode.popular,
        );
      });
    } else {
      // Search with new query
      state = const AsyncLoading();
      state = await AsyncValue.guard(() async {
        final result = await ref.read(movieRepoProvider).search(query: query, page: 1);
        return SearchMovieState(
          movies: result.results.where(movieIntegrityChecker).toList(),
          query: query,
          page: 2,
          hasMore: result.page < result.totalPages,
          mode: SearchMovieMode.search,
        );
      });
    }
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore) return;

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

      state = AsyncData(currentState.copyWith(
        movies: [
          ...currentState.movies,
          ...result.results.where(movieIntegrityChecker),
        ],
        page: currentState.page + 1,
        hasMore: result.page < result.totalPages,
      ));
    } catch (error, stackTrace) {
      // Keep current movies but show error for pagination
      state = AsyncError(error, stackTrace);
    }
  }

  void reset() {
    ref.invalidateSelf();
  }
}
