import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/movie/data/models/movie_image.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';

class MovieImagesController extends Notifier<MovieImagesState> {
  @override
  MovieImagesState build() {
    return MovieImagesState(
      posters: [],
      logos: [],
      backdrops: [],
      isLoading: false,
      isError: false,
    );
  }

  Future<void> getMovieImages({required int id, String? language}) async {
    state = state.copyWith(isLoading: true);
    try {
      final images = await ref.read(movieRepoProvider).getMovieImages(
        id: id,
        language: language,
      );
      state = state.copyWith(
        posters: images.posters,
        logos: images.logos,
        backdrops: images.backdrops,
        isError: false,
      );
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      state = state.copyWith(isError: true, isLoading: false);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

class MovieImagesState {
  final List<MovieImage> posters;
  final List<MovieImage> logos;
  final List<MovieImage> backdrops;
  final bool isLoading;
  final bool isError;

  MovieImagesState({
    required this.posters,
    required this.logos,
    required this.backdrops,
    required this.isLoading,
    required this.isError,
  });

  MovieImagesState copyWith({
    List<MovieImage>? posters,
    List<MovieImage>? logos,
    List<MovieImage>? backdrops,
    bool? isLoading,
    bool? isError,
  }) {
    return MovieImagesState(
      posters: posters ?? this.posters,
      logos: logos ?? this.logos,
      backdrops: backdrops ?? this.backdrops,
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
    );
  }
}
