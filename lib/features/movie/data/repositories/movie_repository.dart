import 'package:movie_journal/features/movie/data/data_sources/movie_api.dart';
import 'package:movie_journal/features/movie/data/models/detailed_movie.dart';
import 'package:movie_journal/features/movie/data/models/movie_image.dart';

class MovieRepository {
  final MovieAPI api;

  MovieRepository(this.api);

  Future<MovieListResponse> search({
    required String query,
    required int page,
  }) async {
    final data = await api.searchMovies(query: query, page: page);
    return data;
  }

  Future<MovieListResponse> popular({required int page}) async {
    final data = await api.popularMovies(page: page);
    return data;
  }

  Future<DetailedMovie> getMovieDetails(int id) async {
    final data = await api.getMovieDetails(id: id);
    return data;
  }

  Future<
    ({
      List<MovieImage> posters,
      List<MovieImage> logos,
      List<MovieImage> backdrops,
    })
  >
  getMovieImages({required int id, String? language}) async {
    final data = await api.getMovieImages(id: id, language: language);
    return data;
  }
}
