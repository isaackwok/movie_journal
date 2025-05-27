import 'package:movie_journal/core/network/tmdb_dio_client.dart';
import 'package:movie_journal/features/movie/data/models/brief_movie.dart';
import 'package:movie_journal/features/movie/data/models/detailed_movie.dart';

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

class MovieListResponse {
  final int page;
  final List<BriefMovie> results;
  final int totalPages;
  final int totalResults;

  const MovieListResponse({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory MovieListResponse.fromJson(Map<String, dynamic> json) =>
      MovieListResponse(
        page: json['page'],
        results: List<BriefMovie>.from(
          json['results'].map((e) => BriefMovie.fromJson(e)),
        ),
        totalPages: json['total_pages'],
        totalResults: json['total_results'],
      );
}

class MovieAPI {
  Future<MovieListResponse> popularMovies({
    required int page,
    String language = 'en-US',
    String? region,
  }) async {
    final response = await TmdbDioClient.get(
      '/movie/popular',
      queryParameters: {'page': page, 'language': language, 'region': region},
    );
    return MovieListResponse.fromJson(response.data);
  }

  Future<MovieListResponse> searchMovies({
    required String query,
    required int page,
    bool includeAdult = false,
    String language = 'en-US',
    String? region,
    int? primaryReleaseYear,
    int? year,
  }) async {
    final response = await TmdbDioClient.get(
      '/search/movie',
      queryParameters: {
        'query': query,
        'page': page,
        'include_adult': includeAdult,
        'language': language,
        'region': region,
        'primary_release_year': primaryReleaseYear,
        'year': year,
      },
    );
    return MovieListResponse.fromJson(response.data);
  }

  Future<DetailedMovie> getMovieDetails({
    required int id,
    String language = 'en-US',
  }) async {
    final response = await TmdbDioClient.get(
      '/movie/$id',
      queryParameters: {'language': language, 'append_to_response': 'credits'},
    );
    final data = DetailedMovie.fromJson(response.data);
    return data;
  }
}
