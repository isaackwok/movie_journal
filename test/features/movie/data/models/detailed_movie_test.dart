import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/movie/data/models/detailed_movie.dart';

import '../../../../helpers/test_movie.dart';

void main() {
  group('Genre.fromJson', () {
    test('parses id and name', () {
      final genre = Genre.fromJson({'id': 18, 'name': 'Drama'});
      expect(genre.id, 18);
      expect(genre.name, 'Drama');
    });
  });

  group('ProductionCompany.fromJson', () {
    test('parses all fields', () {
      final company = ProductionCompany.fromJson({
        'id': 508,
        'logo_path': '/logo.png',
        'name': 'Regency Enterprises',
        'origin_country': 'US',
      });
      expect(company.id, 508);
      expect(company.logoPath, '/logo.png');
      expect(company.name, 'Regency Enterprises');
      expect(company.originCountry, 'US');
    });

    test('handles null logo_path', () {
      final company = ProductionCompany.fromJson({
        'id': 508,
        'logo_path': null,
        'name': 'Regency Enterprises',
        'origin_country': 'US',
      });
      expect(company.logoPath, isNull);
    });
  });

  group('ProductionCountry.fromJson', () {
    test('parses iso code and name', () {
      final country = ProductionCountry.fromJson({
        'iso_3166_1': 'US',
        'name': 'United States of America',
      });
      expect(country.iso31661, 'US');
      expect(country.name, 'United States of America');
    });
  });

  group('SpokenLanguage.fromJson', () {
    test('parses all fields', () {
      final lang = SpokenLanguage.fromJson({
        'english_name': 'English',
        'iso_639_1': 'en',
        'name': 'English',
      });
      expect(lang.englishName, 'English');
      expect(lang.iso6391, 'en');
      expect(lang.name, 'English');
    });
  });

  group('BelongsToCollection.fromJson', () {
    test('parses all fields', () {
      final collection = BelongsToCollection.fromJson({
        'id': 10,
        'name': 'Star Wars Collection',
        'poster_path': '/poster.jpg',
        'backdrop_path': '/backdrop.jpg',
      });
      expect(collection.id, 10);
      expect(collection.name, 'Star Wars Collection');
      expect(collection.posterPath, '/poster.jpg');
      expect(collection.backdropPath, '/backdrop.jpg');
    });

    test('handles null poster and backdrop paths', () {
      final collection = BelongsToCollection.fromJson({
        'id': 10,
        'name': 'Collection',
        'poster_path': null,
        'backdrop_path': null,
      });
      expect(collection.posterPath, isNull);
      expect(collection.backdropPath, isNull);
    });
  });

  group('Cast.fromJson', () {
    test('parses all fields from TMDB response', () {
      final cast = Cast.fromJson(makeCastJson());
      expect(cast.id, 819);
      expect(cast.name, 'Edward Norton');
      expect(cast.character, 'The Narrator');
      expect(cast.order, 0);
      expect(cast.knownForDepartment, 'Acting');
      expect(cast.popularity, 26.99);
      expect(cast.profilePath, '/profile.jpg');
      expect(cast.castId, 4);
      expect(cast.adult, false);
      expect(cast.gender, 2);
    });

    test('handles null profilePath', () {
      final cast = Cast.fromJson(makeCastJson(profilePath: null));
      expect(cast.profilePath, isNull);
    });
  });

  group('Crew.fromJson', () {
    test('parses all fields from TMDB response', () {
      final crew = Crew.fromJson(makeCrewJson());
      expect(crew.id, 7467);
      expect(crew.name, 'David Fincher');
      expect(crew.job, 'Director');
      expect(crew.department, 'Directing');
      expect(crew.knownForDepartment, 'Directing');
      expect(crew.popularity, 17.405);
      expect(crew.profilePath, '/director.jpg');
      expect(crew.adult, false);
      expect(crew.gender, 2);
    });

    test('handles null profilePath', () {
      final crew = Crew.fromJson(makeCrewJson(profilePath: null));
      expect(crew.profilePath, isNull);
    });
  });

  group('Credits.fromJson', () {
    test('parses cast and crew lists', () {
      final credits = Credits.fromJson({
        'cast': [
          makeCastJson(name: 'Edward Norton', order: 0),
          makeCastJson(id: 854, name: 'Brad Pitt', order: 1),
        ],
        'crew': [
          makeCrewJson(name: 'David Fincher', job: 'Director'),
        ],
      });
      expect(credits.cast.length, 2);
      expect(credits.cast[0].name, 'Edward Norton');
      expect(credits.cast[1].name, 'Brad Pitt');
      expect(credits.crew.length, 1);
      expect(credits.crew[0].name, 'David Fincher');
    });

    test('handles empty cast and crew', () {
      final credits = Credits.fromJson({
        'cast': <Map<String, dynamic>>[],
        'crew': <Map<String, dynamic>>[],
      });
      expect(credits.cast, isEmpty);
      expect(credits.crew, isEmpty);
    });
  });

  group('DetailedMovie.fromJson', () {
    test('parses standard TMDB detail response', () {
      final movie = DetailedMovie.fromJson(makeDetailedMovieJson());

      expect(movie.id, 550);
      expect(movie.title, 'Fight Club');
      expect(movie.originalTitle, 'Fight Club');
      expect(movie.originalLanguage, 'en');
      expect(movie.adult, false);
      expect(movie.backdropPath, '/backdrop.jpg');
      expect(movie.posterPath, '/poster.jpg');
      expect(movie.overview, contains('insomniac'));
      expect(movie.popularity, 61.4);
      expect(movie.voteAverage, 8.4);
      expect(movie.voteCount, 26000);
      expect(movie.budget, 63000000);
      expect(movie.revenue, 101209702);
      expect(movie.runtime, 139);
      expect(movie.status, 'Released');
      expect(movie.tagline, 'Mischief. Mayhem. Soap.');
      expect(movie.homepage, contains('foxmovies'));
      expect(movie.imdbId, 'tt0137523');
      expect(movie.video, false);
    });

    test('extracts 4-char year from release_date', () {
      final movie = DetailedMovie.fromJson(
        makeDetailedMovieJson(releaseDate: '2023-07-21'),
      );
      expect(movie.year, '2023');
    });

    test('sets year to "Unknown" when release_date is too short', () {
      final movie = DetailedMovie.fromJson(
        makeDetailedMovieJson(releaseDate: '99'),
      );
      expect(movie.year, 'Unknown');
    });

    test('parses genres list', () {
      final movie = DetailedMovie.fromJson(makeDetailedMovieJson(
        genres: [
          {'id': 18, 'name': 'Drama'},
          {'id': 53, 'name': 'Thriller'},
          {'id': 35, 'name': 'Comedy'},
        ],
      ));
      expect(movie.genres.length, 3);
      expect(movie.genres[0].name, 'Drama');
      expect(movie.genres[2].name, 'Comedy');
    });

    test('parses origin_country list', () {
      final movie = DetailedMovie.fromJson(
        makeDetailedMovieJson(originCountry: ['US', 'DE']),
      );
      expect(movie.originCountry, ['US', 'DE']);
    });

    test('parses production companies', () {
      final movie = DetailedMovie.fromJson(makeDetailedMovieJson(
        productionCompanies: [
          {
            'id': 508,
            'logo_path': '/logo.png',
            'name': 'Regency Enterprises',
            'origin_country': 'US',
          },
          {
            'id': 711,
            'logo_path': null,
            'name': 'Fox 2000 Pictures',
            'origin_country': 'US',
          },
        ],
      ));
      expect(movie.productionCompanies.length, 2);
      expect(movie.productionCompanies[0].name, 'Regency Enterprises');
      expect(movie.productionCompanies[1].logoPath, isNull);
    });

    test('parses production countries', () {
      final movie = DetailedMovie.fromJson(makeDetailedMovieJson(
        productionCountries: [
          {'iso_3166_1': 'US', 'name': 'United States of America'},
          {'iso_3166_1': 'DE', 'name': 'Germany'},
        ],
      ));
      expect(movie.productionCountries.length, 2);
      expect(movie.productionCountries[1].iso31661, 'DE');
    });

    test('parses spoken languages', () {
      final movie = DetailedMovie.fromJson(makeDetailedMovieJson(
        spokenLanguages: [
          {'english_name': 'English', 'iso_639_1': 'en', 'name': 'English'},
          {'english_name': 'Japanese', 'iso_639_1': 'ja', 'name': '日本語'},
        ],
      ));
      expect(movie.spokenLanguages.length, 2);
      expect(movie.spokenLanguages[1].englishName, 'Japanese');
      expect(movie.spokenLanguages[1].iso6391, 'ja');
    });

    test('parses nested credits with cast and crew', () {
      final movie = DetailedMovie.fromJson(makeDetailedMovieJson(
        credits: {
          'cast': [
            makeCastJson(name: 'Edward Norton', character: 'The Narrator'),
            makeCastJson(id: 854, name: 'Brad Pitt', character: 'Tyler Durden'),
          ],
          'crew': [
            makeCrewJson(name: 'David Fincher', job: 'Director'),
            makeCrewJson(
              id: 7468,
              name: 'Jim Uhls',
              job: 'Screenplay',
              department: 'Writing',
              knownForDepartment: 'Writing',
            ),
          ],
        },
      ));
      expect(movie.credits.cast.length, 2);
      expect(movie.credits.cast[0].character, 'The Narrator');
      expect(movie.credits.cast[1].character, 'Tyler Durden');
      expect(movie.credits.crew.length, 2);
      expect(movie.credits.crew[0].job, 'Director');
      expect(movie.credits.crew[1].job, 'Screenplay');
    });

    test('handles null belongsToCollection', () {
      final movie = DetailedMovie.fromJson(
        makeDetailedMovieJson(belongsToCollection: null),
      );
      expect(movie.belongsToCollection, isNull);
    });

    test('parses belongsToCollection when present', () {
      final movie = DetailedMovie.fromJson(makeDetailedMovieJson(
        belongsToCollection: {
          'id': 10,
          'name': 'Star Wars Collection',
          'poster_path': '/sw_poster.jpg',
          'backdrop_path': '/sw_backdrop.jpg',
        },
      ));
      expect(movie.belongsToCollection, isNotNull);
      expect(movie.belongsToCollection!.name, 'Star Wars Collection');
      expect(movie.belongsToCollection!.posterPath, '/sw_poster.jpg');
    });

    test('handles nullable posterPath and backdropPath', () {
      final movie = DetailedMovie.fromJson(
        makeDetailedMovieJson(posterPath: null, backdropPath: null),
      );
      expect(movie.posterPath, isNull);
      expect(movie.backdropPath, isNull);
    });

    test('handles null imdbId', () {
      final movie = DetailedMovie.fromJson(
        makeDetailedMovieJson(imdbId: null),
      );
      expect(movie.imdbId, isNull);
    });
  });
}
