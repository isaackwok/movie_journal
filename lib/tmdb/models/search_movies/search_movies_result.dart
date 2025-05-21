import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:movie_journal/tmdb/models/search_movies/search_movies_result_item.dart';

part 'search_movies_result.freezed.dart';
part 'search_movies_result.g.dart';

@freezed
sealed class SearchMoviesResult with _$SearchMoviesResult {
  const factory SearchMoviesResult({
    required int page,
    required List<SearchMoviesResultItem> results,
    @JsonKey(name: 'total_pages') required int totalPages,
    @JsonKey(name: 'total_results') required int totalResults,
  }) = _SearchMoviesResult;

  factory SearchMoviesResult.fromJson(Map<String, dynamic> json) =>
      _$SearchMoviesResultFromJson(json);
}
