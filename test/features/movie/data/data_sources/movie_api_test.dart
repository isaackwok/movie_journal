import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/movie/data/data_sources/movie_api.dart';

import '../../../../helpers/test_movie.dart';

void main() {
  group('MovieListResponse.fromJson', () {
    test('parses page, totalPages, totalResults', () {
      final response = MovieListResponse.fromJson({
        'page': 1,
        'total_pages': 5,
        'total_results': 100,
        'results': <Map<String, dynamic>>[],
      });

      expect(response.page, 1);
      expect(response.totalPages, 5);
      expect(response.totalResults, 100);
      expect(response.results, isEmpty);
    });

    test('maps each result into BriefMovie', () {
      final response = MovieListResponse.fromJson({
        'page': 1,
        'total_pages': 1,
        'total_results': 2,
        'results': [
          makeBriefMovieJson(id: 1, title: 'Movie A'),
          makeBriefMovieJson(id: 2, title: 'Movie B'),
        ],
      });

      expect(response.results.length, 2);
      expect(response.results[0].id, 1);
      expect(response.results[0].title, 'Movie A');
      expect(response.results[1].id, 2);
      expect(response.results[1].title, 'Movie B');
    });
  });
}
