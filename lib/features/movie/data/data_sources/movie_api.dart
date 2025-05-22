import 'package:movie_journal/core/network/tmdb_dio_client.dart';
import 'package:movie_journal/features/movie/data/models/brief_movie.dart';

typedef SearchMoviesParams =
    ({
      String query,
      int page,
      bool? includeAdult,
      String? language,
      String? region,
      int? primaryReleaseYear,
      int? year,
    });

class SearchMoviesResponse {
  final int page;
  final List<BriefMovie> results;
  final int totalPages;
  final int totalResults;

  const SearchMoviesResponse({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory SearchMoviesResponse.fromJson(Map<String, dynamic> json) =>
      SearchMoviesResponse(
        page: json['page'],
        results: List<BriefMovie>.from(
          json['results'].map((e) => BriefMovie.fromJson(e)),
        ),
        totalPages: json['total_pages'],
        totalResults: json['total_results'],
      );
}

class MovieAPI {
  Future<SearchMoviesResponse> searchMovies({
    required String query,
    required int page,
    bool? includeAdult,
    String? language,
    String? region,
    int? primaryReleaseYear,
    int? year,
  }) async {
    final response = await TmdbDioClient.get(
      '/search/movie',
      queryParameters: {
        'query': query,
        'page': page,
        'include_adult': includeAdult ?? false,
        'language': language ?? 'en-US',
        'region': region,
        'primary_release_year': primaryReleaseYear,
        'year': year,
      },
    );
    return SearchMoviesResponse.fromJson(response.data);
  }
}
