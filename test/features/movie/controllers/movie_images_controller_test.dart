import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
