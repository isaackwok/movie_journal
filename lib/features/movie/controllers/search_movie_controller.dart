import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/movie/data/data_sources/movie_api.dart';
import 'package:movie_journal/features/movie/data/models/brief_movie.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';

enum SearchMovieMode { search, popular }

class SearchMovieState {
  final List<BriefMovie> movies;
  final String query;
  final int page;
  final bool isLoading;
  final bool hasMore;
  final bool isError;
  final SearchMovieMode mode;

  SearchMovieState({
    this.movies = const [],
    this.query = '',
    this.page = 1,
    this.isLoading = false,
    this.hasMore = true,
    this.isError = false,
    this.mode = SearchMovieMode.popular,
  });

  SearchMovieState copyWith({
    List<BriefMovie>? movies,
    String? query,
    int? page,
    bool? isLoading,
    bool? hasMore,
    bool? isError,
    SearchMovieMode? mode,
  }) {
    final nextQuery = query ?? this.query;
    return SearchMovieState(
      movies: movies ?? this.movies,
      query: nextQuery,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      isError: isError ?? this.isError,
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

class SearchMovieController extends Notifier<SearchMovieState> {
  @override
  SearchMovieState build() {
    // Initialize the state and fetch data asynchronously
    Future.microtask(() => fetchNext());
    return SearchMovieState();
  }

  Future<void> search(String query) async {
    state = SearchMovieState(query: query, isError: false);
    fetchNext();
  }

  Future<void> fetchNext() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      late final MovieListResponse result;
      if (state.query.isEmpty) {
        result = await ref.read(movieRepoProvider).popular(page: state.page);
      } else {
        result = await ref.read(movieRepoProvider).search(query: state.query, page: state.page);
      }
      state = state.copyWith(
        movies: [
          ...state.movies,
          ...result.results.where(movieIntegrityChecker),
        ],
        page: state.page + 1,
        hasMore: result.page < result.totalPages,
        isLoading: false,
        isError: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, isError: true);
    }
  }

  void reset() {
    state = SearchMovieState();
    fetchNext();
  }
}
