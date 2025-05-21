import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_movies_result_item.freezed.dart';
part 'search_movies_result_item.g.dart';

@freezed
sealed class SearchMoviesResultItem with _$SearchMoviesResultItem {
  const factory SearchMoviesResultItem({
    required bool adult,
    @JsonKey(name: 'backdrop_path') required String? backdropPath,
    @JsonKey(name: 'genre_ids') required List<int>? genreIds,
    required int id,
    @JsonKey(name: 'original_language') required String originalLanguage,
    @JsonKey(name: 'original_title') required String originalTitle,
    required String overview,
    required double popularity,
    @JsonKey(name: 'poster_path') required String? posterPath,
    @JsonKey(name: 'release_date') required String releaseDate,
    required String title,
    required bool video,
    @JsonKey(name: 'vote_average') required double voteAverage,
    @JsonKey(name: 'vote_count') required int voteCount,
  }) = _SearchMoviesResultItem;

  factory SearchMoviesResultItem.fromJson(Map<String, dynamic> json) =>
      _$SearchMoviesResultItemFromJson(json);
}
