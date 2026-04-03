import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/share/widgets/ticket_front.dart';

import '../../../helpers/fake_http_client.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = FakeHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

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

    testWidgets('renders Image.network with TMDB URL', (tester) async {
      await tester.pumpWidget(buildSubject(posterPath: '/abc.jpg'));
      final image = tester.widget<Image>(find.byType(Image));
      final networkImage = image.image as NetworkImage;
      expect(networkImage.url, 'https://image.tmdb.org/t/p/w500/abc.jpg');
    });

    testWidgets('image uses BoxFit.cover', (tester) async {
      await tester.pumpWidget(buildSubject());
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.cover);
    });

    testWidgets('shows movie icon on image error', (tester) async {
      await tester.pumpWidget(buildSubject());
      // Trigger the errorBuilder by calling it directly
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.errorBuilder, isNotNull);

      // Pump the error state widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 500,
              child: image.errorBuilder!(
                tester.element(find.byType(Image)),
                'error',
                null,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.movie), findsOneWidget);
    });
  });
}
