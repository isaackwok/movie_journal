import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/quesgen/review.dart';

void main() {
  group('Review', () {
    test('toMap() serializes text and source', () {
      final review = Review(text: 'Great film', source: 'letterboxd');
      expect(review.toMap(), {'text': 'Great film', 'source': 'letterboxd'});
    });

    test('fromMap() deserializes correctly', () {
      final review = Review.fromMap({
        'text': 'Loved the cinematography',
        'source': 'reddit',
      });
      expect(review.text, 'Loved the cinematography');
      expect(review.source, 'reddit');
    });

    test('fromString() creates review with source "unknown" (backward compat)',
        () {
      final review = Review.fromString('A classic film');
      expect(review.text, 'A classic film');
      expect(review.source, 'unknown');
    });

    test('same text + source → equal', () {
      final a = Review(text: 'Great', source: 'reddit');
      final b = Review(text: 'Great', source: 'reddit');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different source → not equal', () {
      final a = Review(text: 'Great', source: 'reddit');
      final b = Review(text: 'Great', source: 'letterboxd');
      expect(a, isNot(equals(b)));
    });
  });
}
