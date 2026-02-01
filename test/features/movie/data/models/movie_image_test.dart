import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/movie/data/models/movie_image.dart';

void main() {
  group('MovieImage', () {
    test('fromJson() parses all fields from TMDB image response', () {
      final image = MovieImage.fromJson({
        'file_path': '/abc123.jpg',
        'aspect_ratio': 0.667,
        'height': 3000,
        'width': 2000,
        'iso_639_1': 'en',
        'vote_average': 5.312,
        'vote_count': 4,
      });

      expect(image.filePath, '/abc123.jpg');
      expect(image.aspectRatio, 0.667);
      expect(image.height, 3000);
      expect(image.width, 2000);
      expect(image.iso6391, 'en');
      expect(image.voteAverage, 5.312);
      expect(image.voteCount, 4);
    });
  });
}
