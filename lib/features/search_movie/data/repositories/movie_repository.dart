import 'package:movie_journal/features/search_movie/data/data_sources/movie_api.dart';

class MovieRepository {
  final MovieAPI api;

  MovieRepository(this.api);

  Future<SearchMoviesResponse> search({
    required String query,
    required int page,
  }) async {
    final data = await api.searchMovies(query: query, page: page);
    return data;
  }
}
