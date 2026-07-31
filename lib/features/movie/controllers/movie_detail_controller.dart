import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/movie/data/models/detailed_movie.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';

/// One instance per TMDB movie id (`movieDetailControllerProvider(movieId)`).
///
/// Scoping by id is what makes overlapping flows safe: the old global
/// singleton was mutated from four-plus screens, so navigating while a fetch
/// was in flight could show movie A's screen with movie B's details. It also
/// retires the old build() Completer that fetchMovieDetails only completed on
/// success — an error left `.future` hanging forever. Here build() fetches
/// directly, so errors surface as AsyncError and `.future` always settles.
class MovieDetailController extends AsyncNotifier<DetailedMovie> {
  MovieDetailController(this.movieId);

  /// The family argument.
  final int movieId;

  @override
  Future<DetailedMovie> build() =>
      ref.read(movieRepoProvider).getMovieDetails(movieId);
}
