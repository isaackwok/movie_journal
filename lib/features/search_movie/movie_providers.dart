import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/search_movie/controllers/movie_controller.dart';
import 'package:movie_journal/features/search_movie/data/data_sources/movie_api.dart';
import 'package:movie_journal/features/search_movie/data/repositories/movie_repository.dart';

final movieApiProvider = Provider((_) => MovieAPI());

final movieRepoProvider = Provider(
  (ref) => MovieRepository(ref.watch(movieApiProvider)),
);

final movieControllerProvider =
    StateNotifierProvider<MovieController, SearchMovieState>(
      (ref) => MovieController(ref.read(movieRepoProvider)),
    );
