import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/quesgen/controller.dart';
import 'package:movie_journal/features/quesgen/review.dart';

void main() {
  group('QuesgenState value equality', () {
    test('same fields → equal, same hashCode', () {
      final a = QuesgenState(
        reviews: [Review(text: 'Great', source: 'reddit')],
        isLoading: false,
        isError: false,
      );
      final b = QuesgenState(
        reviews: [Review(text: 'Great', source: 'reddit')],
        isLoading: false,
        isError: false,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('equal even when review lists are distinct instances', () {
      final a = QuesgenState(
        reviews: [Review(text: 'A', source: 'letterboxd')],
        isLoading: true,
        isError: false,
      );
      final b = QuesgenState(
        reviews: [Review(text: 'A', source: 'letterboxd')],
        isLoading: true,
        isError: false,
      );
      expect(identical(a.reviews, b.reviews), isFalse);
      expect(a, equals(b));
    });

    test('different reviews → not equal', () {
      final a = QuesgenState(reviews: [], isLoading: false, isError: false);
      final b = QuesgenState(
        reviews: [Review(text: 'B', source: 'reddit')],
        isLoading: false,
        isError: false,
      );
      expect(a, isNot(equals(b)));
    });

    test('different isLoading → not equal', () {
      final a = QuesgenState(reviews: [], isLoading: false, isError: false);
      final b = a.copyWith(isLoading: true);
      expect(a, isNot(equals(b)));
    });

    test('different isError → not equal', () {
      final a = QuesgenState(reviews: [], isLoading: false, isError: false);
      final b = a.copyWith(isError: true);
      expect(a, isNot(equals(b)));
    });

    test('copyWith with no args → equal to original', () {
      final a = QuesgenState(
        reviews: [Review(text: 'X', source: 'reddit')],
        isLoading: false,
        isError: true,
      );
      expect(a.copyWith(), equals(a));
    });
  });

  group('toBackendLocaleTag', () {
    test('language + country → "lang-COUNTRY"', () {
      expect(toBackendLocaleTag(const Locale('en', 'US')), 'en-US');
    });

    test('language only → language', () {
      expect(toBackendLocaleTag(const Locale('ja')), 'ja');
    });

    test('empty country → language only', () {
      expect(toBackendLocaleTag(const Locale('en', '')), 'en');
    });

    test('script subtag is dropped (zh-Hant-TW → zh-TW)', () {
      const locale = Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'TW',
      );
      expect(toBackendLocaleTag(locale), 'zh-TW');
    });

    test('blank language → null so caller omits ?lang=', () {
      expect(toBackendLocaleTag(const Locale(' ')), isNull);
    });
  });
}
