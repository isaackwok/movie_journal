/// Returns a TMDB-style JSON map for BriefMovie.fromJson testing.
/// Override any field to customize for a specific test case.
Map<String, dynamic> makeBriefMovieJson({
  int id = 550,
  bool adult = false,
  String title = 'Fight Club',
  String originalTitle = 'Fight Club',
  String originalLanguage = 'en',
  String overview = 'An insomniac office worker and a soap maker form an underground fight club.',
  String? backdropPath = '/backdrop.jpg',
  String? posterPath = '/poster.jpg',
  List<int>? genreIds = const [18, 53],
  double? popularity = 61.4,
  String? releaseDate = '1999-10-15',
  bool? video = false,
  double? voteAverage = 8.4,
  int? voteCount = 26000,
}) {
  return {
    'id': id,
    'adult': adult,
    'title': title,
    'original_title': originalTitle,
    'original_language': originalLanguage,
    'overview': overview,
    'backdrop_path': backdropPath,
    'poster_path': posterPath,
    'genre_ids': genreIds,
    'popularity': popularity,
    'release_date': releaseDate,
    'video': video,
    'vote_average': voteAverage,
    'vote_count': voteCount,
  };
}
