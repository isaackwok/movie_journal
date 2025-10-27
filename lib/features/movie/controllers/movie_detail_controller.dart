import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/movie/data/models/detailed_movie.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';

class MovieDetailController extends Notifier<MovieDetailState> {
  @override
  MovieDetailState build() {
    return MovieDetailState(
      movie: DetailedMovie(
        belongsToCollection: null,
        budget: 0,
        adult: false,
        backdropPath: '',
        genres: [],
        homepage: '',
        id: 0,
        imdbId: '',
        originCountry: [],
        originalLanguage: '',
        originalTitle: '',
        overview: '',
        popularity: 0,
        posterPath: '',
        productionCompanies: [],
        productionCountries: [],
        releaseDate: '',
        year: '',
        revenue: 0,
        runtime: 0,
        spokenLanguages: [],
        status: '',
        tagline: '',
        title: '',
        video: false,
        voteAverage: 0,
        voteCount: 0,
        credits: Credits(cast: [], crew: []),
      ),
      isLoading: false,
      isError: false,
    );
  }

  Future<void> fetchMovieDetails(int id) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final movie = await ref.read(movieRepoProvider).getMovieDetails(id);
      state = state.copyWith(movie: movie, isLoading: false, isError: false);
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      state = state.copyWith(isError: true, isLoading: false);
    }
  }
}

class MovieDetailState {
  final DetailedMovie? movie;
  final bool isLoading;
  final bool isError;

  MovieDetailState({
    required this.movie,
    required this.isLoading,
    required this.isError,
  });

  MovieDetailState copyWith({
    DetailedMovie? movie,
    bool? isLoading,
    bool? isError,
  }) {
    return MovieDetailState(
      movie: movie ?? this.movie,
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
    );
  }
}
