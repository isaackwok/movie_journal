import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/movie/controllers/search_movie_controller.dart';
import 'package:movie_journal/features/movie/data/models/brief_movie.dart';

import '../../../helpers/test_movie.dart';

void main() {
  group('movieIntegrityChecker', () {
    test('returns true for valid movie', () {
      final movie = BriefMovie.fromJson(makeBriefMovieJson());
      expect(movieIntegrityChecker(movie), true);
    });

    test('returns false when posterPath is null', () {
      final movie = BriefMovie.fromJson(makeBriefMovieJson(posterPath: null));
      expect(movieIntegrityChecker(movie), false);
    });

    test('returns false when overview is empty', () {
      final movie = BriefMovie.fromJson(makeBriefMovieJson(overview: ''));
      expect(movieIntegrityChecker(movie), false);
    });
  });

  group('SearchMovieState.copyWith', () {
    test('auto-sets mode to popular when query empty', () {
      final state = SearchMovieState(
        query: 'old query',
        mode: SearchMovieMode.search,
      );
      final updated = state.copyWith(query: '');

      expect(updated.mode, SearchMovieMode.popular);
      expect(updated.query, '');
    });

    test('auto-sets mode to search when query non-empty', () {
      final state = SearchMovieState();
      final updated = state.copyWith(query: 'inception');

      expect(updated.mode, SearchMovieMode.search);
      expect(updated.query, 'inception');
    });
  });
}
