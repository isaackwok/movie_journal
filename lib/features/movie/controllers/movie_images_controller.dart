import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/movie/data/models/movie_image.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';

class MovieImagesController extends AsyncNotifier<MovieImagesState> {
  int? _movieId;

  @override
  Future<MovieImagesState> build() {
    // Stay in AsyncLoading until getMovieImages(id:) is called externally.
    //
    // We deliberately return a Future that never completes instead of
    // throwing or returning an empty state. Throwing here (the previous
    // behavior) caused Riverpod to flip the provider into AsyncError on the
    // next microtask, producing a one-frame "Error loading images" flash on
    // ScenesSelector's first render in the journaling page (issue #2).
    // Returning an empty state would similarly mis-render — backdrops would
    // briefly look "empty" and trigger the "Scene missing!" placeholder.
    //
    // getMovieImages() assigns directly to `state`, so this pending future
    // is never awaited beyond keeping the initial state as AsyncLoading.
    return Completer<MovieImagesState>().future;
  }

  Future<void> getMovieImages({required int id, String? language}) async {
    _movieId = id;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final images = await ref.read(movieRepoProvider).getMovieImages(
        id: id,
        language: language,
      );
      return MovieImagesState(
        posters: images.posters,
        logos: images.logos,
        backdrops: images.backdrops,
      );
    });
  }

  Future<void> refresh() async {
    if (_movieId != null) {
      await getMovieImages(id: _movieId!);
    }
  }
}

// Simplified state without manual async flags
class MovieImagesState {
  final List<MovieImage> posters;
  final List<MovieImage> logos;
  final List<MovieImage> backdrops;

  MovieImagesState({
    required this.posters,
    required this.logos,
    required this.backdrops,
  });

  MovieImagesState copyWith({
    List<MovieImage>? posters,
    List<MovieImage>? logos,
    List<MovieImage>? backdrops,
  }) {
    return MovieImagesState(
      posters: posters ?? this.posters,
      logos: logos ?? this.logos,
      backdrops: backdrops ?? this.backdrops,
    );
  }
}
