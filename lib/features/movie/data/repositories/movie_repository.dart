import 'package:movie_journal/features/movie/data/data_sources/movie_api.dart';
import 'package:movie_journal/features/movie/data/models/detailed_movie.dart';

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
}
