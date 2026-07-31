import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/core/utils/tmdb_image_url.dart';
import 'package:movie_journal/features/share/widgets/ticket_front.dart';
import 'package:movie_journal/shared_widgets/tmdb_image.dart';

import '../../../helpers/widget_test_setup.dart';

void main() {
  setUpAll(() => setUpWidgetTests());
  tearDownAll(() => tearDownWidgetTests());

  // Fresh fake per test: failAll is per-test state.
  setUp(setUpWidgetTests);

  Widget buildSubject({String posterPath = '/poster.jpg'}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 500,
          child: TicketFront(posterPath: posterPath),
        ),
      ),
    );
  }

  group('TicketFront', () {
    testWidgets('renders ClipPath with FilmStripClipper', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(ClipPath), findsOneWidget);
    });

    testWidgets('renders the poster at the w780 bucket', (tester) async {
      await tester.pumpWidget(buildSubject(posterPath: '/abc.jpg'));
      final image = tester.widget<TmdbImage>(find.byType(TmdbImage));
      expect(image.path, '/abc.jpg');
      expect(image.size, TmdbImageSize.w780);
    });

    testWidgets('image uses BoxFit.cover', (tester) async {
      await tester.pumpWidget(buildSubject());
      final image = tester.widget<TmdbImage>(find.byType(TmdbImage));
      expect(image.fit, BoxFit.cover);
    });

    testWidgets('does not fade in, so a ticket capture cannot catch it '
        'mid-transition', (tester) async {
      await tester.pumpWidget(buildSubject());
      final image = tester.widget<TmdbImage>(find.byType(TmdbImage));
      expect(image.fadeInDuration, Duration.zero);
    });

    testWidgets('shows movie icon on image error', (tester) async {
      currentFakeCacheManager!.failAll = true;
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.movie), findsOneWidget);
    });
  });
}
