import 'dart:async';

import 'package:dio/dio.dart';
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
  Future<MovieListResponse> popular({
    required int page,
    CancelToken? cancelToken,
  }) async {
    if (failPopular) throw Exception('network down');
    return _page(page);
  }

  @override
  Future<MovieListResponse> search({
    required String query,
    required int page,
    CancelToken? cancelToken,
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

typedef _PendingRequest = ({
  String? query,
  int page,
  CancelToken? cancelToken,
  Completer<MovieListResponse> completer,
});

/// Never resolves on its own: every popular()/search() call parks a Completer
/// in [pending] so tests decide the order responses arrive in — the only way
/// to reproduce out-of-order races deterministically.
class _ControlledMovieRepo implements MovieRepository {
  final List<_PendingRequest> pending = [];

  MovieListResponse page(int page, {String title = 'Movie'}) =>
      MovieListResponse(
        page: page,
        results: [
          BriefMovie.fromJson(makeBriefMovieJson(id: page, title: title)),
        ],
        totalPages: 5,
        totalResults: 5,
      );

  @override
  Future<MovieListResponse> popular({
    required int page,
    CancelToken? cancelToken,
  }) {
    final completer = Completer<MovieListResponse>();
    pending.add((
      query: null,
      page: page,
      cancelToken: cancelToken,
      completer: completer,
    ));
    return completer.future;
  }

  @override
  Future<MovieListResponse> search({
    required String query,
    required int page,
    CancelToken? cancelToken,
  }) {
    final completer = Completer<MovieListResponse>();
    pending.add((
      query: query,
      page: page,
      cancelToken: cancelToken,
      completer: completer,
    ));
    return completer.future;
  }

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

  group('SearchMovieState value equality', () {
    test('same fields → equal, same hashCode', () {
      final a = SearchMovieState(
        movies: [BriefMovie.fromJson(makeBriefMovieJson())],
        query: 'fight',
        page: 2,
        hasMore: true,
        mode: SearchMovieMode.search,
      );
      final b = SearchMovieState(
        movies: [BriefMovie.fromJson(makeBriefMovieJson())],
        query: 'fight',
        page: 2,
        hasMore: true,
        mode: SearchMovieMode.search,
      );
      expect(identical(a.movies, b.movies), isFalse);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('default states → equal', () {
      expect(SearchMovieState(), equals(SearchMovieState()));
    });

    test('different movies → not equal', () {
      final a = SearchMovieState(
        movies: [BriefMovie.fromJson(makeBriefMovieJson(id: 1))],
      );
      final b = SearchMovieState(
        movies: [BriefMovie.fromJson(makeBriefMovieJson(id: 2))],
      );
      expect(a, isNot(equals(b)));
    });

    test('different query → not equal', () {
      final a = SearchMovieState(query: 'a', mode: SearchMovieMode.search);
      final b = SearchMovieState(query: 'b', mode: SearchMovieMode.search);
      expect(a, isNot(equals(b)));
    });

    test('different page → not equal', () {
      expect(
        SearchMovieState(page: 1),
        isNot(equals(SearchMovieState(page: 2))),
      );
    });

    test('different hasMore → not equal', () {
      expect(
        SearchMovieState(hasMore: true),
        isNot(equals(SearchMovieState(hasMore: false))),
      );
    });
  });

  group('SearchMovieController', () {
    ProviderContainer containerWith(_FakeMovieRepo repo) {
      final container = ProviderContainer(
        overrides: [movieRepoProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      // Riverpod 3 auto-disposes unlistened providers mid-flight; keep the
      // element alive or `.future` never completes (see CLAUDE.md).
      container.listen(searchMovieControllerProvider, (_, _) {});
      return container;
    }

    // Regression test for ISA-9 bug 5: a pagination failure used to set a
    // bare AsyncError, which dropped every already-loaded page from the state
    // and made all later loadMore() calls bail at the `state.value == null`
    // guard.
    test('loadMore() failure preserves loaded movies and stays retryable',
        () async {
      final repo = _FakeMovieRepo();
      final container = containerWith(repo);

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

    test('build() loads the first popular page', () async {
      final container = containerWith(_FakeMovieRepo());

      final state = await container.read(searchMovieControllerProvider.future);

      expect(state.movies.single.id, 1);
      expect(state.page, 2);
      expect(state.hasMore, isTrue);
      expect(state.mode, SearchMovieMode.popular);
    });

    test('loadMore() appends the next page', () async {
      final container = containerWith(_FakeMovieRepo());
      await container.read(searchMovieControllerProvider.future);

      await container
          .read(searchMovieControllerProvider.notifier)
          .loadMore();

      final state = container.read(searchMovieControllerProvider).value!;
      expect(state.movies.map((m) => m.id), [1, 2]);
      expect(state.page, 3);
    });

    test('search() switches to search mode and resets paging', () async {
      final container = containerWith(_FakeMovieRepo());
      await container.read(searchMovieControllerProvider.future);

      await container
          .read(searchMovieControllerProvider.notifier)
          .search('fight');

      final state = container.read(searchMovieControllerProvider).value!;
      expect(state.mode, SearchMovieMode.search);
      expect(state.query, 'fight');
      expect(state.page, 2);
    });

    test('failed popular reload surfaces AsyncError', () async {
      final repo = _FakeMovieRepo();
      final container = containerWith(repo);
      await container.read(searchMovieControllerProvider.future);

      repo.failPopular = true;
      await container.read(searchMovieControllerProvider.notifier).search('');

      expect(container.read(searchMovieControllerProvider).hasError, isTrue);
    });
  });

  group('SearchMovieController race guards', () {
    ProviderContainer containerWith(_ControlledMovieRepo repo) {
      final container = ProviderContainer(
        overrides: [movieRepoProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      // Riverpod 3 auto-disposes unlistened providers mid-flight; keep the
      // element alive or `.future` never completes (see CLAUDE.md).
      container.listen(searchMovieControllerProvider, (_, _) {});
      return container;
    }

    /// Completes build()'s initial popular fetch (always repo.pending[0]).
    Future<SearchMovieState> settleInitialLoad(
      ProviderContainer container,
      _ControlledMovieRepo repo,
    ) async {
      final initial = container.read(searchMovieControllerProvider.future);
      repo.pending.single.completer.complete(repo.page(1, title: 'Popular'));
      return initial;
    }

    test('a slow stale response cannot clobber a newer search', () async {
      final repo = _ControlledMovieRepo();
      final container = containerWith(repo);
      await settleInitialLoad(container, repo);
      final notifier = container.read(searchMovieControllerProvider.notifier);

      final slow = notifier.search('slow');
      final fast = notifier.search('fast');
      expect(repo.pending, hasLength(3)); // initial + slow + fast

      repo.pending[2].completer.complete(repo.page(1, title: 'Fast result'));
      await fast;

      final afterFast = container.read(searchMovieControllerProvider).value!;
      expect(afterFast.query, 'fast');
      expect(afterFast.movies.single.title, 'Fast result');

      // The stale response arrives late — it must be dropped, not applied.
      repo.pending[1].completer.complete(repo.page(1, title: 'Slow result'));
      await slow;

      final afterSlow = container.read(searchMovieControllerProvider).value!;
      expect(afterSlow.query, 'fast');
      expect(afterSlow.movies.single.title, 'Fast result');
    });

    test('a stale failure cannot clobber a newer result either', () async {
      final repo = _ControlledMovieRepo();
      final container = containerWith(repo);
      await settleInitialLoad(container, repo);
      final notifier = container.read(searchMovieControllerProvider.notifier);

      final slow = notifier.search('slow');
      final fast = notifier.search('fast');

      repo.pending[2].completer.complete(repo.page(1, title: 'Fast result'));
      await fast;

      repo.pending[1].completer.completeError(Exception('network down'));
      await slow;

      final state = container.read(searchMovieControllerProvider);
      expect(state.hasError, isFalse);
      expect(state.value!.query, 'fast');
    });

    test('a new search cancels the previous in-flight request token',
        () async {
      final repo = _ControlledMovieRepo();
      final container = containerWith(repo);
      await settleInitialLoad(container, repo);
      final notifier = container.read(searchMovieControllerProvider.notifier);

      final first = notifier.search('first');
      final second = notifier.search('second');

      final firstToken = repo.pending[1].cancelToken;
      final secondToken = repo.pending[2].cancelToken;
      expect(firstToken, isNotNull);
      expect(firstToken!.isCancelled, isTrue);
      expect(secondToken!.isCancelled, isFalse);

      repo.pending[2].completer.complete(repo.page(1));
      // The cancelled request errors the way a real Dio call would.
      repo.pending[1].completer
          .completeError(DioException.requestCancelled(
        requestOptions: RequestOptions(),
        reason: 'superseded',
      ));
      await first;
      await second;

      expect(container.read(searchMovieControllerProvider).hasError, isFalse);
    });

    test('reload preserves the previous results while loading', () async {
      final repo = _ControlledMovieRepo();
      final container = containerWith(repo);
      await settleInitialLoad(container, repo);
      final notifier = container.read(searchMovieControllerProvider.notifier);

      final pendingSearch = notifier.search('new query');

      final during = container.read(searchMovieControllerProvider);
      expect(during.isLoading, isTrue);
      expect(
        during.value?.movies.single.title,
        'Popular',
        reason: 'the old list must stay available during the reload',
      );

      repo.pending[1].completer.complete(repo.page(1, title: 'New'));
      await pendingSearch;
      expect(
        container.read(searchMovieControllerProvider).value!.movies.single
            .title,
        'New',
      );
    });

    test('loadMore is a no-op while a reload is in flight', () async {
      final repo = _ControlledMovieRepo();
      final container = containerWith(repo);
      await settleInitialLoad(container, repo);
      final notifier = container.read(searchMovieControllerProvider.notifier);

      // copyWithPrevious keeps the old list visible during the reload, so the
      // user can still scroll — loadMore must not fetch pages for the old
      // query underneath the new one.
      final pendingSearch = notifier.search('new query');
      await notifier.loadMore();

      expect(
        repo.pending,
        hasLength(2),
        reason: 'initial + search only — loadMore must not have fetched',
      );

      repo.pending[1].completer.complete(repo.page(1, title: 'New'));
      await pendingSearch;
    });

    test('a stale loadMore response is not appended after a newer search',
        () async {
      final repo = _ControlledMovieRepo();
      final container = containerWith(repo);
      await settleInitialLoad(container, repo);
      final notifier = container.read(searchMovieControllerProvider.notifier);

      final pendingMore = notifier.loadMore(); // popular page 2, in flight
      final pendingSearch = notifier.search('new query');

      repo.pending[2].completer.complete(repo.page(1, title: 'New'));
      await pendingSearch;

      // The old-query page arrives after the new search resolved.
      repo.pending[1].completer.complete(repo.page(2, title: 'Stale page'));
      await pendingMore;

      final state = container.read(searchMovieControllerProvider).value!;
      expect(state.movies.single.title, 'New');
      expect(state.page, 2);
    });
  });
}
