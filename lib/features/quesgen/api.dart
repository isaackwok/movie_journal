import 'package:movie_journal/core/network/quesgen_dio_client.dart';
import 'package:movie_journal/features/quesgen/review.dart';

class QuesgenAPI {
  Future<List<Review>> generateReviews({
    required int movieId,
    String? locale,
  }) async {
    final response = await quesgenDioClient.get(
      '/generate/$movieId',
      queryParameters: locale == null ? null : {'lang': locale},
    );
    return (response.data['reviews'] as List<dynamic>)
        .map((item) => Review.fromMap(item as Map<String, dynamic>))
        .toList();
  }
}
