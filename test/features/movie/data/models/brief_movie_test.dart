import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/movie/data/models/brief_movie.dart';

import '../../../../helpers/test_movie.dart';

void main() {
  group('BriefMovie.fromJson', () {
    test('parses standard TMDB response correctly', () {
      final movie = BriefMovie.fromJson(makeBriefMovieJson());

      expect(movie.id, 550);
      expect(movie.title, 'Fight Club');
      expect(movie.originalTitle, 'Fight Club');
      expect(movie.adult, false);
      expect(movie.posterPath, '/poster.jpg');
      expect(movie.backdropPath, '/backdrop.jpg');
      expect(movie.overview, contains('insomniac'));
      expect(movie.genreIds, [18, 53]);
      expect(movie.popularity, 61.4);
      expect(movie.voteAverage, 8.4);
      expect(movie.voteCount, 26000);
    });

    test('extracts 4-char year from release_date', () {
      final movie = BriefMovie.fromJson(
        makeBriefMovieJson(releaseDate: '2023-07-21'),
      );
      expect(movie.year, '2023');
    });

    test('sets year to "Unknown" when release_date is null', () {
      final movie = BriefMovie.fromJson(
        makeBriefMovieJson(releaseDate: null),
      );
      expect(movie.year, 'Unknown');
    });

    test('sets year to "Unknown" when release_date is too short', () {
      final movie = BriefMovie.fromJson(
        makeBriefMovieJson(releaseDate: '99'),
      );
      expect(movie.year, 'Unknown');
    });

    test('handles nullable fields (backdropPath, posterPath, etc.)', () {
      final movie = BriefMovie.fromJson(makeBriefMovieJson(
        backdropPath: null,
        posterPath: null,
        genreIds: null,
        video: null,
        voteAverage: null,
        voteCount: null,
      ));
      expect(movie.backdropPath, isNull);
      expect(movie.posterPath, isNull);
      expect(movie.genreIds, isNull);
      expect(movie.video, isNull);
      expect(movie.voteAverage, isNull);
      expect(movie.voteCount, isNull);
    });
  });

  group('BriefMovie value equality', () {
    test('same JSON → equal, same hashCode', () {
      final a = BriefMovie.fromJson(makeBriefMovieJson());
      final b = BriefMovie.fromJson(makeBriefMovieJson());
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('genreIds compared by value, not identity', () {
      final a = BriefMovie.fromJson(makeBriefMovieJson(genreIds: [18, 53]));
      final b = BriefMovie.fromJson(makeBriefMovieJson(genreIds: [18, 53]));
      expect(a, equals(b));
    });

    test('different id → not equal', () {
      final a = BriefMovie.fromJson(makeBriefMovieJson(id: 1));
      final b = BriefMovie.fromJson(makeBriefMovieJson(id: 2));
      expect(a, isNot(equals(b)));
    });

    test('different title → not equal', () {
      final a = BriefMovie.fromJson(makeBriefMovieJson(title: 'A'));
      final b = BriefMovie.fromJson(makeBriefMovieJson(title: 'B'));
      expect(a, isNot(equals(b)));
    });
  });
}
