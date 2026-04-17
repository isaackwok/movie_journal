import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/quesgen/api.dart';
import 'package:movie_journal/features/quesgen/review.dart';

final quesgenApiProvider = Provider((_) => QuesgenAPI());

class QuesgenState {
  final List<Review> reviews;
  final bool isLoading;
  final bool isError;

  QuesgenState({
    required this.reviews,
    required this.isLoading,
    required this.isError,
  });

  QuesgenState copyWith({
    List<Review>? reviews,
    bool? isLoading,
    bool? isError,
  }) {
    return QuesgenState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
    );
  }
}

class QuesgenController extends Notifier<QuesgenState> {
  @override
  QuesgenState build() {
    return QuesgenState(reviews: [], isLoading: false, isError: false);
  }

  Future<void> generateReviews({
    required int movieId,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final locale = _toBackendLocaleTag(PlatformDispatcher.instance.locale);
      final newReviews = await ref
          .read(quesgenApiProvider)
          .generateReviews(
            movieId: movieId,
            locale: locale,
          );
      state = state.copyWith(reviews: newReviews, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, isError: true);
    }
  }

  void clear() {
    state = state.copyWith(reviews: [], isLoading: false, isError: false);
  }
}

/// Convert the OS-reported [Locale] into a BCP 47 tag the backend
/// (and TMDB, in the future) understands.
///
/// - Combines [Locale.languageCode] with [Locale.countryCode] when present,
///   e.g. `en_US` -> `"en-US"`.
/// - Drops [Locale.scriptCode]. TMDB does not accept script subtags
///   (`zh-Hant-TW` is invalid; `zh-TW` is correct). For CJK the country
///   code already encodes the script (TW/HK -> Traditional, CN -> Simplified).
/// - Returns `null` when the language code is missing so the caller can
///   omit `?lang=` and let the server apply its own default.
String? _toBackendLocaleTag(Locale locale) {
  final language = locale.languageCode.trim();
  if (language.isEmpty) return null;
  final country = locale.countryCode;
  if (country == null || country.isEmpty) return language;
  return '$language-$country';
}

