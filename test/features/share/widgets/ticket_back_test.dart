import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:movie_journal/features/emotion/emotion.dart';
import 'package:movie_journal/features/share/widgets/film_strip_clipper.dart';
import 'package:movie_journal/features/share/widgets/ticket_back.dart';

import '../../../helpers/widget_test_setup.dart';

void main() {
  setUpAll(() => setUpWidgetTests());
  tearDownAll(() => tearDownWidgetTests());

  late Jiffy testDate;

  setUp(() {
    testDate = Jiffy.parseFromDateTime(DateTime(2024, 3, 15, 14, 30));
  });

  Widget buildSubject({
    String movieTitle = 'Fight Club',
    String year = '1999',
    String releaseDate = '1999-10-15',
    String director = 'David Fincher',
    String cast = 'Brad Pitt, Edward Norton',
    List<Emotion> emotions = const [],
    String? scenePath = '/scene.jpg',
    Jiffy? createdAt,
    int ticketNumber = 7,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 350,
          height: 550,
          child: TicketBack(
            movieTitle: movieTitle,
            year: year,
            releaseDate: releaseDate,
            director: director,
            cast: cast,
            emotions: emotions,
            scenePath: scenePath,
            createdAt: createdAt ?? testDate,
            ticketNumber: ticketNumber,
          ),
        ),
      ),
    );
  }

  group('TicketBack', () {
    group('header', () {
      testWidgets('renders FINK MOVIE JOURNAL text', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        expect(find.text('FINK MOVIE JOURNAL'), findsOneWidget);
      });

      testWidgets('renders ticket number', (tester) async {
        await tester.pumpWidget(buildSubject(ticketNumber: 12));
        await tester.pumpAndSettle();
        expect(find.text('NO. 12'), findsOneWidget);
      });
    });

    group('title section', () {
      testWidgets('renders Title label', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        expect(find.text('Title'), findsOneWidget);
      });

      testWidgets('renders year in brackets', (tester) async {
        await tester.pumpWidget(buildSubject(year: '2003'));
        await tester.pumpAndSettle();
        expect(find.text('[2003]'), findsOneWidget);
      });

      testWidgets('renders movie title in uppercase', (tester) async {
        await tester.pumpWidget(
          buildSubject(movieTitle: 'Lost in Translation'),
        );
        await tester.pumpAndSettle();
        expect(find.text('LOST IN TRANSLATION'), findsOneWidget);
      });
    });

    group('details section', () {
      testWidgets('renders Release label and value', (tester) async {
        await tester.pumpWidget(buildSubject(releaseDate: '2024-01-15'));
        await tester.pumpAndSettle();
        expect(find.text('Release'), findsOneWidget);
        expect(find.text('2024-01-15'), findsOneWidget);
      });

      testWidgets('renders Director label and value', (tester) async {
        await tester.pumpWidget(buildSubject(director: 'Sofia Coppola'));
        await tester.pumpAndSettle();
        expect(find.text('Director'), findsOneWidget);
        expect(find.text('Sofia Coppola'), findsOneWidget);
      });

      testWidgets('renders Cast label and value', (tester) async {
        await tester.pumpWidget(
          buildSubject(cast: 'Bill Murray, Scarlett Johansson'),
        );
        await tester.pumpAndSettle();
        expect(find.text('Cast'), findsOneWidget);
        expect(find.text('Bill Murray, Scarlett Johansson'), findsOneWidget);
      });
    });

    group('emotion section', () {
      testWidgets('renders "--" when emotions list is empty', (tester) async {
        await tester.pumpWidget(buildSubject(emotions: []));
        await tester.pumpAndSettle();
        expect(find.text('Emotion'), findsOneWidget);
        expect(find.text('--'), findsOneWidget);
      });

      testWidgets('renders emotion names joined by commas', (tester) async {
        await tester.pumpWidget(
          buildSubject(
            emotions: const [
              Emotion(
                id: 'joyful',
                name: 'Joyful',
                group: 'Uplifting',
                energyLevel: 'high',
              ),
              Emotion(
                id: 'inspired',
                name: 'Inspired',
                group: 'Uplifting',
                energyLevel: 'high',
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Joyful, Inspired'), findsOneWidget);
      });

      testWidgets('renders single emotion without comma', (tester) async {
        await tester.pumpWidget(
          buildSubject(
            emotions: const [
              Emotion(
                id: 'peaceful',
                name: 'Peaceful',
                group: 'Soothing',
                energyLevel: 'low',
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Peaceful'), findsOneWidget);
      });
    });

    group('date/time section', () {
      testWidgets('renders Date and Time labels', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        expect(find.text('Date'), findsOneWidget);
        expect(find.text('Time'), findsOneWidget);
      });

      testWidgets('renders formatted date as MMM dd', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        expect(find.text('Mar 15'), findsOneWidget);
      });

      testWidgets('renders formatted time as HH:mm', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        expect(find.text('14:30'), findsOneWidget);
      });

      testWidgets('has IntrinsicHeight for vertical divider', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        expect(find.byType(IntrinsicHeight), findsOneWidget);
      });
    });

    group('scene image', () {
      testWidgets('renders image when scenePath is provided', (tester) async {
        await tester.pumpWidget(buildSubject(scenePath: '/scene.jpg'));
        await tester.pumpAndSettle();
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('does not render image when scenePath is null',
          (tester) async {
        await tester.pumpWidget(buildSubject(scenePath: null));
        await tester.pumpAndSettle();
        expect(find.byType(Image), findsNothing);
      });

      testWidgets('image is wrapped in ClipRect', (tester) async {
        await tester.pumpWidget(buildSubject(scenePath: '/scene.jpg'));
        await tester.pumpAndSettle();
        expect(
          find.ancestor(
            of: find.byType(Image),
            matching: find.byType(ClipRect),
          ),
          findsOneWidget,
        );
      });

      testWidgets('image has grayscale ColorFiltered via saturation blend',
          (tester) async {
        await tester.pumpWidget(buildSubject(scenePath: '/scene.jpg'));
        await tester.pumpAndSettle();
        final colorFiltered = tester.widget<ColorFiltered>(
          find.ancestor(
            of: find.byType(Image),
            matching: find.byType(ColorFiltered),
          ),
        );
        expect(
          colorFiltered.colorFilter,
          const ColorFilter.mode(Colors.grey, BlendMode.saturation),
        );
      });
    });

    group('layout structure', () {
      testWidgets('uses ClipPath with FilmStripClipper', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        final clipPath = find.byWidgetPredicate(
          (w) => w is ClipPath && w.clipper is FilmStripClipper,
        );
        expect(clipPath, findsOneWidget);
      });

      testWidgets('outer container has white background', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        final container = find.descendant(
          of: find.byType(ClipPath),
          matching: find.byWidgetPredicate(
            (w) => w is Container && w.color == Colors.white,
          ),
        );
        expect(container, findsOneWidget);
      });

      testWidgets('bordered container uses foregroundDecoration',
          (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        final container = find.byWidgetPredicate(
          (w) => w is Container && w.foregroundDecoration != null,
        );
        expect(container, findsOneWidget);
      });
    });
  });
}
