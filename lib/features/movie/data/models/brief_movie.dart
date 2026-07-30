import 'package:flutter/foundation.dart';

class BriefMovie {
  final int id;
  final bool adult;
  final String title;
  final String originalTitle;
  final String originalLanguage;
  final String overview;
  final String? backdropPath;
  final String? posterPath;
  final List<int>? genreIds;
  final double? popularity;
  final String? releaseDate;
  final bool? video;
  final double? voteAverage;
  final int? voteCount;

  // custom field
  final String year;

  const BriefMovie({
    required this.adult,
    required this.backdropPath,
    required this.genreIds,
    required this.id,
    required this.originalLanguage,
    required this.originalTitle,
    required this.overview,
    required this.popularity,
    required this.posterPath,
    required this.releaseDate,
    required this.title,
    required this.video,
    required this.voteAverage,
    required this.voteCount,
    required this.year,
  });

  factory BriefMovie.fromJson(Map<String, dynamic> json) => BriefMovie(
    adult: json['adult'],
    backdropPath: json['backdrop_path'],
    genreIds: json['genre_ids']?.cast<int>(),
    id: json['id'],
    originalLanguage: json['original_language'],
    originalTitle: json['original_title'],
    overview: json['overview'],
    popularity: json['popularity'],
    posterPath: json['poster_path'],
    releaseDate: json['release_date'],
    title: json['title'],
    video: json['video'],
    voteAverage: json['vote_average'],
    voteCount: json['vote_count'],
    year:
        (json['release_date']?.length ?? 0) >= 4
            ? json['release_date'].substring(0, 4)
            : 'Unknown',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BriefMovie &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          adult == other.adult &&
          title == other.title &&
          originalTitle == other.originalTitle &&
          originalLanguage == other.originalLanguage &&
          overview == other.overview &&
          backdropPath == other.backdropPath &&
          posterPath == other.posterPath &&
          listEquals(genreIds, other.genreIds) &&
          popularity == other.popularity &&
          releaseDate == other.releaseDate &&
          video == other.video &&
          voteAverage == other.voteAverage &&
          voteCount == other.voteCount &&
          year == other.year;

  @override
  int get hashCode => Object.hash(
        id,
        adult,
        title,
        originalTitle,
        originalLanguage,
        overview,
        backdropPath,
        posterPath,
        genreIds == null ? null : Object.hashAll(genreIds!),
        popularity,
        releaseDate,
        video,
        voteAverage,
        voteCount,
        year,
      );
}
