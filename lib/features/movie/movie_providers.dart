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

final movieDetailControllerProvider =
    AsyncNotifierProvider<MovieDetailController, DetailedMovie>(
      MovieDetailController.new,
    );

final movieImagesControllerProvider =
    AsyncNotifierProvider<MovieImagesController, MovieImagesState>(
      MovieImagesController.new,
    );
