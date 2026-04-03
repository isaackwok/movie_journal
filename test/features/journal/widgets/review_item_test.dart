import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/journal/widgets/review_item.dart';
import 'package:movie_journal/features/quesgen/review.dart';

import '../../../helpers/fake_http_client.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = FakeHttpOverrides();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  final testReview = Review(
    text: 'A masterpiece of modern cinema.',
    source: 'letterboxd',
  );

  Widget buildSubject({
    Review? review,
    VoidCallback? onPress,
    bool showAction = true,
    bool isSelected = false,
    bool transparent = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ReviewItem(
          review: review ?? testReview,
          onPress: onPress,
          showAction: showAction,
          isSelected: isSelected,
          transparent: transparent,
        ),
      ),
    );
  }

  group('ReviewItem', () {
    group('text and source', () {
      testWidgets('displays review text', (tester) async {
        await tester.pumpWidget(buildSubject());
        expect(find.text('A masterpiece of modern cinema.'), findsOneWidget);
      });

      testWidgets('displays source name in uppercase', (tester) async {
        await tester.pumpWidget(buildSubject());
        expect(find.text('LETTERBOXD'), findsOneWidget);
      });

      testWidgets('displays reddit source', (tester) async {
        final redditReview = Review(text: 'Great film.', source: 'reddit');
        await tester.pumpWidget(buildSubject(review: redditReview));
        expect(find.text('REDDIT'), findsOneWidget);
      });
    });

    group('action button states', () {
      testWidgets('hides action button when showAction is false',
          (tester) async {
        await tester.pumpWidget(buildSubject(showAction: false));
        expect(find.byIcon(Icons.add_rounded), findsNothing);
        expect(find.byIcon(Icons.check_rounded), findsNothing);
      });

      testWidgets('shows add icon when not selected', (tester) async {
        await tester.pumpWidget(
          buildSubject(showAction: true, isSelected: false),
        );
        expect(find.byIcon(Icons.add_rounded), findsOneWidget);
        expect(find.byIcon(Icons.check_rounded), findsNothing);
      });

      testWidgets('shows check icon when selected', (tester) async {
        await tester.pumpWidget(
          buildSubject(showAction: true, isSelected: true),
        );
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
        expect(find.byIcon(Icons.add_rounded), findsNothing);
      });

      testWidgets('selected button has teal background', (tester) async {
        await tester.pumpWidget(
          buildSubject(showAction: true, isSelected: true),
        );
        final container = tester.widget<Container>(
          find.ancestor(
            of: find.byIcon(Icons.check_rounded),
            matching: find.byType(Container),
          ).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, const Color(0xFFA8DADD));
      });

      testWidgets('unselected button has transparent background',
          (tester) async {
        await tester.pumpWidget(
          buildSubject(showAction: true, isSelected: false),
        );
        final container = tester.widget<Container>(
          find.ancestor(
            of: find.byIcon(Icons.add_rounded),
            matching: find.byType(Container),
          ).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, Colors.transparent);
      });
    });

    group('transparent variant', () {
      testWidgets('has transparent background when transparent is true',
          (tester) async {
        await tester.pumpWidget(buildSubject(transparent: true));

        // Find the outer Container of the ReviewItem (the one with decoration)
        final containers = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) =>
                c.decoration is BoxDecoration &&
                (c.decoration as BoxDecoration).borderRadius != null)
            .toList();

        // The first matching container should be the ReviewItem's outer container
        final outerDecoration = containers.first.decoration as BoxDecoration;
        expect(outerDecoration.color, Colors.transparent);
      });

      testWidgets('has visible border when transparent is true',
          (tester) async {
        await tester.pumpWidget(buildSubject(transparent: true));

        final containers = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) =>
                c.decoration is BoxDecoration &&
                (c.decoration as BoxDecoration).borderRadius != null)
            .toList();

        final outerDecoration = containers.first.decoration as BoxDecoration;
        expect(outerDecoration.border, isNotNull);
        // White with alpha 76
        expect(
          outerDecoration.border!.top.color,
          Colors.white.withAlpha(76),
        );
      });

      testWidgets('has dark background when transparent is false',
          (tester) async {
        await tester.pumpWidget(buildSubject(transparent: false));

        final containers = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) =>
                c.decoration is BoxDecoration &&
                (c.decoration as BoxDecoration).borderRadius != null)
            .toList();

        final outerDecoration = containers.first.decoration as BoxDecoration;
        expect(outerDecoration.color, const Color(0xFF202020));
      });
    });

    group('interaction', () {
      testWidgets('calls onPress when tapped', (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          buildSubject(onPress: () => tapped = true),
        );
        await tester.tap(find.byType(InkWell).first);
        expect(tapped, isTrue);
      });

      testWidgets('does not crash when onPress is null', (tester) async {
        await tester.pumpWidget(buildSubject(onPress: null));
        await tester.tap(find.byType(InkWell).first);
        // No crash = pass
      });
    });
  });
}
