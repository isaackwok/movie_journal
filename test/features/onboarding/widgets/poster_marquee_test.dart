import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/onboarding/controllers/splash_posters.dart';
import 'package:movie_journal/features/onboarding/widgets/poster_marquee.dart';
import 'package:movie_journal/themes.dart';

import '../../../helpers/widget_test_setup.dart';

Widget _wrap({
  required ProviderContainer container,
  required Widget child,
  Size size = const Size(390, 844),
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(theme: Themes.dark, home: Scaffold(body: child)),
    ),
  );
}

void main() {
  setUpAll(setUpWidgetTests);
  tearDownAll(tearDownWidgetTests);

  group('PosterMarquee', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          splashPostersProvider.overrideWith(
            (ref) async => List<String>.generate(
              8,
              (index) => 'https://example.com/poster_$index.jpg',
            ),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('renders both marquee rows with visible poster tiles', (
      tester,
    ) async {
      final controller = AnimationController(
        vsync: tester,
        duration: const Duration(seconds: 24),
      )..value = 0.25;

      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(
          container: container,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 380,
              child: PosterMarquee(progress: controller),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      final posterImages = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is NetworkImage &&
            (widget.image as NetworkImage).url.contains('poster_'),
      );

      expect(find.byType(PosterMarquee), findsOneWidget);
      expect(posterImages, findsAtLeastNWidgets(4));

      final imageRects =
          tester.widgetList<Image>(posterImages).map((image) {
            final element = find.byWidget(image);
            return tester.getRect(element);
          }).toList();

      final distinctRows =
          imageRects.map((rect) => rect.top.round()).toSet().length;
      expect(distinctRows, greaterThanOrEqualTo(2));

      final firstPosterWidget = tester.widget<Image>(posterImages.first);
      expect(firstPosterWidget.width, 75);
      expect(firstPosterWidget.height, 100);
    });
  });
}
