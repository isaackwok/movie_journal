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
      final newReviews = await ref
          .read(quesgenApiProvider)
          .generateReviews(
            movieId: movieId,
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
