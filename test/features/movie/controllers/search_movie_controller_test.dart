import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/movie/controllers/search_movie_controller.dart';
import 'package:movie_journal/features/movie/data/data_sources/movie_api.dart';
import 'package:movie_journal/features/movie/data/models/brief_movie.dart';
import 'package:movie_journal/features/movie/data/models/detailed_movie.dart';
import 'package:movie_journal/features/movie/data/models/movie_image.dart';
import 'package:movie_journal/features/movie/data/repositories/movie_repository.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';

import '../../../helpers/test_movie.dart';

/// One movie per page, five pages total; popular() can be told to fail so
/// pagination errors are reproducible.
class _FakeMovieRepo implements MovieRepository {
  bool failPopular = false;

  MovieListResponse _page(int page) => MovieListResponse(
        page: page,
        results: [
          BriefMovie.fromJson(
            makeBriefMovieJson(id: page, title: 'Movie page $page'),
          ),
        ],
        totalPages: 5,
        totalResults: 5,
      );

  @override
  Future<MovieListResponse> popular({required int page}) async {
    if (failPopular) throw Exception('network down');
    return _page(page);
  }

  @override
  Future<MovieListResponse> search({
    required String query,
    required int page,
  }) async =>
      _page(page);

  @override
  MovieAPI get api => throw UnimplementedError();

  @override
  Future<DetailedMovie> getMovieDetails(int id) => throw UnimplementedError();

  @override
  Future<
      ({
        List<MovieImage> posters,
        List<MovieImage> logos,
        List<MovieImage> backdrops,
      })> getMovieImages({required int id, String? language}) =>
      throw UnimplementedError();
}

void main() {
  group('movieIntegrityChecker', () {
    test('returns true for valid movie', () {
      final movie = BriefMovie.fromJson(makeBriefMovieJson());
      expect(movieIntegrityChecker(movie), true);
    });

    test('returns false when posterPath is null', () {
      final movie = BriefMovie.fromJson(makeBriefMovieJson(posterPath: null));
      expect(movieIntegrityChecker(movie), false);
    });

    test('returns false when overview is empty', () {
      final movie = BriefMovie.fromJson(makeBriefMovieJson(overview: ''));
      expect(movieIntegrityChecker(movie), false);
    });
  });

  group('SearchMovieState.copyWith', () {
    test('auto-sets mode to popular when query empty', () {
      final state = SearchMovieState(
        query: 'old query',
        mode: SearchMovieMode.search,
      );
      final updated = state.copyWith(query: '');

      expect(updated.mode, SearchMovieMode.popular);
      expect(updated.query, '');
    });

    test('auto-sets mode to search when query non-empty', () {
      final state = SearchMovieState();
      final updated = state.copyWith(query: 'inception');

      expect(updated.mode, SearchMovieMode.search);
      expect(updated.query, 'inception');
    });
  });

  group('SearchMovieController.loadMore', () {
    // Regression test for ISA-9 bug 5: a pagination failure used to set a
    // bare AsyncError, which dropped every already-loaded page from the state
    // and made all later loadMore() calls bail at the `state.value == null`
    // guard.
    test('failure preserves loaded movies and stays retryable', () async {
      final repo = _FakeMovieRepo();
      final container = ProviderContainer(
        overrides: [movieRepoProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      // Riverpod 3 auto-disposes unlistened providers mid-await; keep the
      // element alive (see Known Test Findings in CLAUDE.md).
      container.listen(searchMovieControllerProvider, (_, _) {});

      final initial =
          await container.read(searchMovieControllerProvider.future);
      final initialCount = initial.movies.length;
      expect(initialCount, greaterThan(0));

      repo.failPopular = true;
      await container.read(searchMovieControllerProvider.notifier).loadMore();

      final failed = container.read(searchMovieControllerProvider);
      expect(failed.hasError, isTrue);
      expect(
        failed.value?.movies.length,
        initialCount,
        reason: 'the already-loaded pages must survive a pagination error',
      );

      repo.failPopular = false;
      await container.read(searchMovieControllerProvider.notifier).loadMore();

      final recovered = container.read(searchMovieControllerProvider);
      expect(recovered.hasError, isFalse);
      expect(recovered.value!.movies.length, greaterThan(initialCount));
    });
  });
}
