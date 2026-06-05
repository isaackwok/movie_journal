import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/journal/widgets/scenes_select_sheet.dart';
import 'package:movie_journal/features/movie/controllers/movie_images_controller.dart';
import 'package:movie_journal/features/movie/data/models/movie_image.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';

import '../../../helpers/widget_test_setup.dart';

/// Serves a fixed set of backdrops synchronously so the sheet renders its grid
/// without any network call (the real controller stays in AsyncLoading forever).
class _FakeMovieImagesController extends MovieImagesController {
  _FakeMovieImagesController(this._backdrops);

  final List<MovieImage> _backdrops;

  @override
  Future<MovieImagesState> build() async => MovieImagesState(
        posters: const [],
        logos: const [],
        backdrops: _backdrops,
      );
}

List<MovieImage> _fakeBackdrops(int count) => List.generate(
      count,
      (i) => MovieImage(
        filePath: '/scene$i.jpg',
        aspectRatio: 1.78,
        height: 1080,
        width: 1920,
        voteAverage: 1,
        voteCount: 1,
      ),
    );

void main() {
  setUpAll(setUpWidgetTests);
  tearDownAll(tearDownWidgetTests);

  Widget buildSubject(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ScenesSelectSheet()),
    );
  }

  ProviderContainer makeContainer(int backdropCount) {
    return ProviderContainer(
      overrides: [
        movieImagesControllerProvider.overrideWith(
          () => _FakeMovieImagesController(_fakeBackdrops(backdropCount)),
        ),
      ],
    );
  }

  group('ScenesSelectSheet', () {
    testWidgets('shows the emotion-style count, starting at 0/10',
        (tester) async {
      final container = makeContainer(12);
      addTearDown(container.dispose);

      await tester.pumpWidget(buildSubject(container));
      await tester.pumpAndSettle();

      expect(find.text('Select up to 10 (0/10)'), findsOneWidget);
    });

    testWidgets('selecting a scene updates the count', (tester) async {
      final container = makeContainer(12);
      addTearDown(container.dispose);

      await tester.pumpWidget(buildSubject(container));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SceneButton).first);
      await tester.pump();

      expect(find.text('Select up to 10 (1/10)'), findsOneWidget);
    });

    testWidgets('blocks selection past the cap and shows a toast',
        (tester) async {
      // A tall surface so all 12 grid cells render and are hit-testable.
      tester.view.physicalSize = const Size(1000, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = makeContainer(12);
      addTearDown(container.dispose);

      await tester.pumpWidget(buildSubject(container));
      await tester.pumpAndSettle();

      // Fill the cap.
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.byType(SceneButton).at(i));
        await tester.pump();
      }
      expect(find.text('Select up to 10 (10/10)'), findsOneWidget);

      // Tapping an 11th is blocked: count holds at 10/10 and a toast appears.
      await tester.tap(find.byType(SceneButton).at(10));
      await tester.pump();
      expect(find.text('Select up to 10 (10/10)'), findsOneWidget);
      expect(find.text('You can select up to 10 scenes'), findsWidgets);

      // Drain fluttertoast's chained timers so none leak past teardown.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });
  });
}
