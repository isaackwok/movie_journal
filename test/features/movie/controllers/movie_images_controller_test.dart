import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/movie/controllers/movie_images_controller.dart';
import 'package:movie_journal/features/movie/data/data_sources/movie_api.dart';
import 'package:movie_journal/features/movie/data/models/detailed_movie.dart';
import 'package:movie_journal/features/movie/data/models/movie_image.dart';
import 'package:movie_journal/features/movie/data/repositories/movie_repository.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';

/// Serves one poster per movie id, tagged with the id and language.
class _FakeMovieRepo implements MovieRepository {
  @override
  Future<
    ({
      List<MovieImage> posters,
      List<MovieImage> logos,
      List<MovieImage> backdrops,
    })
  >
  getMovieImages({required int id, String? language}) async {
    final image = MovieImage(
      filePath: '/movie-$id-${language ?? 'any'}.jpg',
      aspectRatio: 1.778,
      height: 1080,
      width: 1920,
      iso6391: language,
      voteAverage: 5.0,
      voteCount: 1,
    );
    return (posters: [image], logos: <MovieImage>[], backdrops: [image]);
  }

  @override
  MovieAPI get api => throw UnimplementedError();

  @override
  Future<DetailedMovie> getMovieDetails(int id) => throw UnimplementedError();

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
}

void main() {
  group('movieImagesControllerProvider initial state', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('first read does not enter AsyncError state '
        '(regression: "Error loading images" flashed on every first render '
        'of the journaling page scenes section, issue #2)', () async {
      // Trigger construction of the AsyncNotifier.
      container.read(movieImagesControllerProvider(550));

      // Drain microtasks so the build() future has a chance to settle.
      // Without the fix, build() throws UnimplementedError and Riverpod
      // flips state to AsyncError on the next microtask tick — which is
      // exactly the window during which ScenesSelector renders its first
      // frame and shows "Error loading images".
      await Future<void>.delayed(Duration.zero);

      final state = container.read(movieImagesControllerProvider(550));

      expect(
        state.hasError,
        isFalse,
        reason:
            'movieImagesControllerProvider must not enter AsyncError on '
            'first read. The provider should stay in AsyncLoading until '
            'getMovieImages() is called externally.',
      );
      expect(
        state.isLoading,
        isTrue,
        reason:
            'Until getMovieImages() is called, the provider should '
            'remain in the loading state so consumers render their '
            'skeleton/loading UI rather than an error message.',
      );
    });
  });

  group('movieImagesControllerProvider (.family)', () {
    ProviderContainer containerWith() {
      final container = ProviderContainer(
        overrides: [movieRepoProvider.overrideWithValue(_FakeMovieRepo())],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('getMovieImages fetches for the instance\'s own movie id', () async {
      final container = containerWith();
      container.listen(movieImagesControllerProvider(1), (_, _) {});

      await container
          .read(movieImagesControllerProvider(1).notifier)
          .getMovieImages();

      final state = container.read(movieImagesControllerProvider(1)).value!;
      expect(state.posters.single.filePath, '/movie-1-any.jpg');
    });

    test(
      'instances are independent: fetching movie 1 leaves movie 2 loading',
      () async {
        final container = containerWith();
        container.listen(movieImagesControllerProvider(1), (_, _) {});
        container.listen(movieImagesControllerProvider(2), (_, _) {});

        await container
            .read(movieImagesControllerProvider(1).notifier)
            .getMovieImages();

        expect(
          container.read(movieImagesControllerProvider(1)).hasValue,
          isTrue,
        );
        expect(
          container.read(movieImagesControllerProvider(2)).isLoading,
          isTrue,
          reason: 'overlapping flows must no longer share one global state',
        );
      },
    );

    test('language refetch replaces the same instance\'s images', () async {
      final container = containerWith();
      container.listen(movieImagesControllerProvider(1), (_, _) {});
      final notifier = container.read(
        movieImagesControllerProvider(1).notifier,
      );

      await notifier.getMovieImages();
      await notifier.getMovieImages(language: 'zh-TW');

      final state = container.read(movieImagesControllerProvider(1)).value!;
      expect(state.posters.single.filePath, '/movie-1-zh-TW.jpg');
    });
  });

  group('MovieImagesState value equality', () {
    MovieImage buildImage({String filePath = '/img.jpg'}) {
      return MovieImage(
        filePath: filePath,
        aspectRatio: 1.778,
        height: 1080,
        width: 1920,
        iso6391: null,
        voteAverage: 5.0,
        voteCount: 1,
      );
    }

    test('same images (by value) → equal, same hashCode', () {
      final a = MovieImagesState(
        posters: [buildImage()],
        logos: [],
        backdrops: [buildImage(filePath: '/b.jpg')],
      );
      final b = MovieImagesState(
        posters: [buildImage()],
        logos: [],
        backdrops: [buildImage(filePath: '/b.jpg')],
      );
      expect(identical(a.posters, b.posters), isFalse);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different backdrops → not equal', () {
      final a = MovieImagesState(posters: [], logos: [], backdrops: []);
      final b = MovieImagesState(
        posters: [],
        logos: [],
        backdrops: [buildImage()],
      );
      expect(a, isNot(equals(b)));
    });
  });
}
