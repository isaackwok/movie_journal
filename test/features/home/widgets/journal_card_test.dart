import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:movie_journal/features/home/widgets/journal_card.dart';

import '../../../helpers/test_journal.dart';
import '../../../helpers/widget_test_setup.dart';

void main() {
  setUpAll(() => setUpWidgetTests());
  tearDownAll(() => tearDownWidgetTests());

  Widget buildSubject({
    String movieTitle = 'Fight Club',
    String moviePoster = '/poster.jpg',
    Jiffy? updatedAt,
  }) {
    final journal = makeJournal(
      movieTitle: movieTitle,
      moviePoster: moviePoster,
      updatedAt: updatedAt ?? Jiffy.parseFromDateTime(DateTime(2024, 3, 15)),
    );

    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: JournalCard(journal: journal),
        ),
      ),
    );
  }

  group('JournalCard', () {
    testWidgets('displays movie title', (tester) async {
      await tester.pumpWidget(buildSubject(movieTitle: 'Inception'));
      expect(find.text('Inception'), findsOneWidget);
    });

    testWidgets('displays formatted date', (tester) async {
      await tester.pumpWidget(buildSubject(
        updatedAt: Jiffy.parseFromDateTime(DateTime(2024, 3, 15)),
      ));
      // Jiffy formats 'MMM. do yyyy' → "Mar. 15th 2024"
      expect(find.textContaining('Mar'), findsOneWidget);
    });

    testWidgets('renders poster Image.network with TMDB URL', (tester) async {
      await tester.pumpWidget(buildSubject(moviePoster: '/abc.jpg'));
      final image = tester.widget<Image>(find.byType(Image));
      final networkImage = image.image as NetworkImage;
      expect(networkImage.url, 'https://image.tmdb.org/t/p/w342/abc.jpg');
    });

    testWidgets('poster uses BoxFit.cover', (tester) async {
      await tester.pumpWidget(buildSubject());
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.cover);
    });

    testWidgets('wraps content in InkWell for tap interaction', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('truncates long movie titles with ellipsis', (tester) async {
      await tester.pumpWidget(buildSubject(
        movieTitle:
            'The Lord of the Rings: The Return of the King Extended Edition',
      ));
      final text = tester.widget<Text>(find.text(
        'The Lord of the Rings: The Return of the King Extended Edition',
      ));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('has rounded container decoration', (tester) async {
      await tester.pumpWidget(buildSubject());
      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) =>
              c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).borderRadius != null)
          .toList();

      expect(containers, isNotEmpty);
      final decoration = containers.first.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF222222));
    });

    testWidgets('InkWell exposes onLongPress handler', (tester) async {
      await tester.pumpWidget(buildSubject());
      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onLongPress, isNotNull);
    });

    testWidgets('long press shows Edit, Share, and Delete options',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.longPress(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('Delete option is rendered in destructive color',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.longPress(find.byType(InkWell));
      await tester.pumpAndSettle();

      final deleteText = tester.widget<Text>(find.text('Delete'));
      expect(deleteText.style?.color, const Color(0xFFFF615D));
    });
  });
}
