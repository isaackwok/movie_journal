import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/movie/controllers/movie_images_controller.dart';
import 'package:movie_journal/features/movie/data/models/movie_image.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';

void main() {
  group('movieImagesControllerProvider initial state', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'first read does not enter AsyncError state '
      '(regression: "Error loading images" flashed on every first render '
      'of the journaling page scenes section, issue #2)',
      () async {
        // Trigger construction of the AsyncNotifier.
        container.read(movieImagesControllerProvider);

        // Drain microtasks so the build() future has a chance to settle.
        // Without the fix, build() throws UnimplementedError and Riverpod
        // flips state to AsyncError on the next microtask tick — which is
        // exactly the window during which ScenesSelector renders its first
        // frame and shows "Error loading images".
        await Future<void>.delayed(Duration.zero);

        final state = container.read(movieImagesControllerProvider);

        expect(
          state.hasError,
          isFalse,
          reason:
              'movieImagesControllerProvider must not enter AsyncError on '
              'first read. The provider should stay in AsyncLoading until '
              'getMovieImages(id:) is called externally.',
        );
        expect(
          state.isLoading,
          isTrue,
          reason:
              'Until getMovieImages(id:) is called, the provider should '
              'remain in the loading state so consumers render their '
              'skeleton/loading UI rather than an error message.',
        );
      },
    );
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
