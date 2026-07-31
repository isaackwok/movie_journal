import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/movie/data/data_sources/movie_api.dart';
import 'package:movie_journal/features/movie/data/models/detailed_movie.dart';
import 'package:movie_journal/features/movie/data/models/movie_image.dart';
import 'package:movie_journal/features/movie/data/repositories/movie_repository.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';

import '../../../helpers/test_movie.dart';

/// Serves a distinct movie per id; ids in [failIds] throw instead.
class _FakeMovieRepo implements MovieRepository {
  _FakeMovieRepo({Set<int>? failIds}) : failIds = failIds ?? {};

  final Set<int> failIds;
  int detailCalls = 0;

  @override
  Future<DetailedMovie> getMovieDetails(int id) async {
    detailCalls++;
    if (failIds.contains(id)) throw Exception('network down');
    return DetailedMovie.fromJson(
      makeDetailedMovieJson(id: id, title: 'Movie $id'),
    );
  }

  @override
  MovieAPI get api => throw UnimplementedError();

  @override
  Future<MovieListResponse> popular({
    required int page,
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<MovieListResponse> search({
    required String query,
    required int page,
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<
    ({
      List<MovieImage> posters,
      List<MovieImage> logos,
      List<MovieImage> backdrops,
    })
  >
  getMovieImages({required int id, String? language}) =>
      throw UnimplementedError();
}

void main() {
  ProviderContainer containerWith(_FakeMovieRepo repo) {
    final container = ProviderContainer(
      overrides: [movieRepoProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('movieDetailControllerProvider (.family)', () {
    test('each instance fetches and holds its own movie', () async {
      final repo = _FakeMovieRepo();
      final container = containerWith(repo);
      container.listen(movieDetailControllerProvider(1), (_, _) {});
      container.listen(movieDetailControllerProvider(2), (_, _) {});

      final first = await container.read(
        movieDetailControllerProvider(1).future,
      );
      final second = await container.read(
        movieDetailControllerProvider(2).future,
      );

      expect(first.title, 'Movie 1');
      expect(second.title, 'Movie 2');
      // Overlapping flows can no longer clobber each other: instance 1 is
      // untouched by instance 2's fetch.
      expect(
        container.read(movieDetailControllerProvider(1)).value!.title,
        'Movie 1',
      );
    });

    test(
      'a failed fetch completes .future with the error instead of hanging',
      () async {
        // Regression: the pre-family controller's build() returned a
        // Completer future that fetchMovieDetails only completed on SUCCESS,
        // so after an error `.future` hung forever.
        final repo = _FakeMovieRepo(failIds: {99});
        final container = containerWith(repo);
        container.listen(movieDetailControllerProvider(99), (_, _) {});

        await expectLater(
          container.read(movieDetailControllerProvider(99).future),
          throwsException,
        );
        expect(
          container.read(movieDetailControllerProvider(99)).hasError,
          isTrue,
        );
      },
    );

    test('refresh retries a failed instance (Retry button path)', () async {
      final repo = _FakeMovieRepo(failIds: {7});
      final container = containerWith(repo);
      container.listen(movieDetailControllerProvider(7), (_, _) {});

      await expectLater(
        container.read(movieDetailControllerProvider(7).future),
        throwsException,
      );

      repo.failIds.clear();
      container.invalidate(movieDetailControllerProvider(7));

      final movie = await container.read(
        movieDetailControllerProvider(7).future,
      );
      expect(movie.title, 'Movie 7');
    });

    test(
      're-reading a loaded instance does not refetch (keep-alive cache)',
      () async {
        final repo = _FakeMovieRepo();
        final container = containerWith(repo);
        container.listen(movieDetailControllerProvider(1), (_, _) {});

        await container.read(movieDetailControllerProvider(1).future);
        await container.read(movieDetailControllerProvider(1).future);

        expect(repo.detailCalls, 1);
      },
    );
  });
}
