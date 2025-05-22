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
}
