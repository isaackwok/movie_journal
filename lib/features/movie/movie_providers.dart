import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/movie/controllers/movie_detail_controller.dart';
import 'package:movie_journal/features/movie/controllers/movie_images_controller.dart';
import 'package:movie_journal/features/movie/controllers/search_movie_controller.dart';
import 'package:movie_journal/features/movie/data/data_sources/movie_api.dart';
import 'package:movie_journal/features/movie/data/repositories/movie_repository.dart';
import 'package:movie_journal/features/movie/data/models/detailed_movie.dart';

final movieApiProvider = Provider((_) => MovieAPI());

final movieRepoProvider = Provider(
  (ref) => MovieRepository(ref.watch(movieApiProvider)),
);

final searchMovieControllerProvider =
    AsyncNotifierProvider<SearchMovieController, SearchMovieState>(
      SearchMovieController.new,
    );

// Both are keyed by TMDB movie id. Deliberately NOT autoDispose: instances
// act as a per-movie session cache, and the prefetch-then-navigate pattern
// (journal_actions, share screens) relies on state surviving until the
// destination screen starts watching.
//
// retry is disabled: Riverpod 3's default exponential-backoff retry keeps
// `.future` pending across the whole retry schedule, so awaiters (e.g.
// TicketPosterPickerScreen._initAndFetch) would hang minutes on a network
// error instead of falling back. Errors surface immediately; the Retry
// button on MoviePreview re-fetches explicitly.
Duration? _noRetry(int retryCount, Object error) => null;

final movieDetailControllerProvider =
    AsyncNotifierProvider.family<MovieDetailController, DetailedMovie, int>(
      MovieDetailController.new,
      retry: _noRetry,
    );

final movieImagesControllerProvider =
    AsyncNotifierProvider.family<MovieImagesController, MovieImagesState, int>(
      MovieImagesController.new,
      retry: _noRetry,
    );
