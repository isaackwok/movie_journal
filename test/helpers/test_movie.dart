/// Returns a TMDB-style JSON map for DetailedMovie.fromJson testing.
/// Override any field to customize for a specific test case.
Map<String, dynamic> makeDetailedMovieJson({
  bool adult = false,
  String? backdropPath = '/backdrop.jpg',
  Map<String, dynamic>? belongsToCollection,
  int budget = 63000000,
  List<Map<String, dynamic>>? genres,
  String homepage = 'http://www.foxmovies.com/movies/fight-club',
  int id = 550,
  String? imdbId = 'tt0137523',
  List<String> originCountry = const ['US'],
  String originalLanguage = 'en',
  String originalTitle = 'Fight Club',
  String overview =
      'An insomniac office worker and a soap maker form an underground fight club.',
  double popularity = 61.4,
  String? posterPath = '/poster.jpg',
  List<Map<String, dynamic>>? productionCompanies,
  List<Map<String, dynamic>>? productionCountries,
  String releaseDate = '1999-10-15',
  int revenue = 101209702,
  int runtime = 139,
  List<Map<String, dynamic>>? spokenLanguages,
  String status = 'Released',
  String tagline = 'Mischief. Mayhem. Soap.',
  String title = 'Fight Club',
  bool video = false,
  double voteAverage = 8.4,
  int voteCount = 26000,
  Map<String, dynamic>? credits,
}) {
  return {
    'adult': adult,
    'backdrop_path': backdropPath,
    'belongs_to_collection': belongsToCollection,
    'budget': budget,
    'genres': genres ?? [
      {'id': 18, 'name': 'Drama'},
      {'id': 53, 'name': 'Thriller'},
    ],
    'homepage': homepage,
    'id': id,
    'imdb_id': imdbId,
    'origin_country': originCountry,
    'original_language': originalLanguage,
    'original_title': originalTitle,
    'overview': overview,
    'popularity': popularity,
    'poster_path': posterPath,
    'production_companies': productionCompanies ?? [
      {
        'id': 508,
        'logo_path': '/logo.png',
        'name': 'Regency Enterprises',
        'origin_country': 'US',
      },
    ],
    'production_countries': productionCountries ?? [
      {'iso_3166_1': 'US', 'name': 'United States of America'},
    ],
    'release_date': releaseDate,
    'revenue': revenue,
    'runtime': runtime,
    'spoken_languages': spokenLanguages ?? [
      {'english_name': 'English', 'iso_639_1': 'en', 'name': 'English'},
    ],
    'status': status,
    'tagline': tagline,
    'title': title,
    'video': video,
    'vote_average': voteAverage,
    'vote_count': voteCount,
    'credits': credits ?? {
      'cast': [makeCastJson()],
      'crew': [makeCrewJson()],
    },
  };
}

/// Returns a TMDB-style cast member JSON map.
Map<String, dynamic> makeCastJson({
  bool adult = false,
  int gender = 2,
  int id = 819,
  String knownForDepartment = 'Acting',
  String name = 'Edward Norton',
  String originalName = 'Edward Norton',
  double popularity = 26.99,
  String? profilePath = '/profile.jpg',
  int castId = 4,
  String character = 'The Narrator',
  String creditId = '52fe4250c3a36847f80149f3',
  int order = 0,
}) {
  return {
    'adult': adult,
    'gender': gender,
    'id': id,
    'known_for_department': knownForDepartment,
    'name': name,
    'original_name': originalName,
    'popularity': popularity,
    'profile_path': profilePath,
    'cast_id': castId,
    'character': character,
    'credit_id': creditId,
    'order': order,
  };
}

/// Returns a TMDB-style crew member JSON map.
Map<String, dynamic> makeCrewJson({
  bool adult = false,
  int gender = 2,
  int id = 7467,
  String knownForDepartment = 'Directing',
  String name = 'David Fincher',
  String originalName = 'David Fincher',
  double popularity = 17.405,
  String? profilePath = '/director.jpg',
  String creditId = '52fe4250c3a36847f8014a11',
  String department = 'Directing',
  String job = 'Director',
}) {
  return {
    'adult': adult,
    'gender': gender,
    'id': id,
    'known_for_department': knownForDepartment,
    'name': name,
    'original_name': originalName,
    'popularity': popularity,
    'profile_path': profilePath,
    'credit_id': creditId,
    'department': department,
    'job': job,
  };
}

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
