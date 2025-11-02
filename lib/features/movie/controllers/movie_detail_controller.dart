import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/movie/data/models/detailed_movie.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';

class MovieDetailController extends AsyncNotifier<DetailedMovie> {
  int? _movieId;
  final Completer<DetailedMovie> _completer = Completer<DetailedMovie>();

  @override
  Future<DetailedMovie> build() async {
    // Wait for fetchMovieDetails to be called
    return _completer.future;
  }

  Future<void> fetchMovieDetails(int id) async {
    _movieId = id;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final movie = await ref.read(movieRepoProvider).getMovieDetails(id);
      if (!_completer.isCompleted) {
        _completer.complete(movie);
      }
      return movie;
    });
  }

  Future<void> refresh() async {
    if (_movieId != null) {
      await fetchMovieDetails(_movieId!);
    }
  }
}

// MovieDetailState is no longer needed - AsyncValue<DetailedMovie> provides
// loading, error, and data states automatically
