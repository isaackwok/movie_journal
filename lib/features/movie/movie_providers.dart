import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/movie/controllers/movie_detail_controller.dart';
import 'package:movie_journal/features/movie/controllers/movie_images_controller.dart';
import 'package:movie_journal/features/movie/controllers/search_movie_controller.dart';
import 'package:movie_journal/features/movie/data/data_sources/movie_api.dart';
import 'package:movie_journal/features/movie/data/repositories/movie_repository.dart';

final movieApiProvider = Provider((_) => MovieAPI());

final movieRepoProvider = Provider(
  (ref) => MovieRepository(ref.watch(movieApiProvider)),
);

final searchMovieControllerProvider =
    StateNotifierProvider<SearchMovieController, SearchMovieState>(
      (ref) => SearchMovieController(ref.read(movieRepoProvider)),
    );

final movieDetailControllerProvider =
    StateNotifierProvider<MovieDetailController, MovieDetailState>(
      (ref) => MovieDetailController(ref.read(movieRepoProvider)),
    );

final movieImagesControllerProvider =
    StateNotifierProvider<MovieImagesController, MovieImagesState>(
      (ref) => MovieImagesController(ref.read(movieRepoProvider)),
    );
