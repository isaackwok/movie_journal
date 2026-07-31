import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/core/utils/tmdb_image_url.dart';

void main() {
  group('tmdbImageUrl', () {
    test('builds a sized URL from a TMDB path with its leading slash', () {
      expect(
        tmdbImageUrl('/poster.jpg', TmdbImageSize.w780),
        'https://image.tmdb.org/t/p/w780/poster.jpg',
      );
    });

    test('tolerates a path missing the leading slash', () {
      expect(
        tmdbImageUrl('poster.jpg', TmdbImageSize.w342),
        'https://image.tmdb.org/t/p/w342/poster.jpg',
      );
    });

    test('never produces a double slash', () {
      expect(
        tmdbImageUrl('/poster.jpg', TmdbImageSize.original),
        isNot(contains('//poster')),
      );
    });

    test('covers every size bucket the app uses', () {
      for (final size in TmdbImageSize.values) {
        expect(
          tmdbImageUrl('/x.jpg', size),
          'https://image.tmdb.org/t/p/${size.name}/x.jpg',
        );
      }
    });
  });
}
