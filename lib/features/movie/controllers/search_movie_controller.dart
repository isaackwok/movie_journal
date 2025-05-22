import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/movie/data/models/brief_movie.dart';
import 'package:movie_journal/features/movie/data/repositories/movie_repository.dart';

class SearchMovieState {
  final List<BriefMovie> movies;
  final String query;
  final int page;
  final bool isLoading;
  final bool hasMore;
  final bool isError;

  SearchMovieState({
    this.movies = const [],
    this.query = '',
    this.page = 1,
    this.isLoading = false,
    this.hasMore = true,
    this.isError = false,
  });

  SearchMovieState copyWith({
    List<BriefMovie>? movies,
    String? query,
    int? page,
    bool? isLoading,
    bool? hasMore,
    bool? isError,
  }) {
    return SearchMovieState(
      movies: movies ?? this.movies,
      query: query ?? this.query,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      isError: isError ?? this.isError,
    );
  }
}

class SearchMovieController extends StateNotifier<SearchMovieState> {
  final MovieRepository repository;

  SearchMovieController(this.repository) : super(SearchMovieState());

  Future<void> search(String query) async {
    state = SearchMovieState(query: query, isError: false);
    fetchNext();
  }

  Future<void> fetchNext() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final result = await repository.search(
        query: state.query,
        page: state.page,
      );
      state = state.copyWith(
        movies: [...state.movies, ...result.results],
        page: state.page + 1,
        hasMore: result.page < result.totalPages,
        isLoading: false,
        isError: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, isError: true);
    }
  }
}
