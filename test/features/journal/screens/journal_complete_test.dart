import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/home/widgets/journal_card.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/screens/journal_complete.dart';

import '../../../helpers/fake_http_client.dart';
import '../../../helpers/test_journal.dart';

void main() {
  setUpAll(() {
    // Return a transparent 1x1 PNG for any Image.network request
    HttpOverrides.global = FakeHttpOverrides();
    // Prevent Google Fonts from making HTTP requests in tests
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  group('JournalCompleteScreen', () {
    late JournalState journal;

    setUp(() {
      journal = makeJournal(
        id: 'test-journal-123',
        movieTitle: 'Fight Club',
        moviePoster: '/poster.jpg',
      );
    });

    Widget buildSubject() {
      return ProviderScope(
        child: MaterialApp(
          home: JournalCompleteScreen(journal: journal),
        ),
      );
    }

    testWidgets('renders checkmark icon', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('renders success message text', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text("You've saved a journal"), findsOneWidget);
    });

    testWidgets('renders Share Ticket as ElevatedButton', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(ElevatedButton, 'Share Ticket'),
        findsOneWidget,
      );
    });

    testWidgets('renders View Journal as TextButton', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextButton, 'View Journal'),
        findsOneWidget,
      );
    });

    testWidgets('reuses JournalCard widget from home', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(JournalCard), findsOneWidget);
    });

    testWidgets('wraps JournalCard in IgnorePointer to disable tap',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      final ignorePointer = find.ancestor(
        of: find.byType(JournalCard),
        matching: find.byWidgetPredicate(
          (w) => w is IgnorePointer && w.ignoring,
        ),
      );
      expect(ignorePointer, findsOneWidget);
    });

    testWidgets('displays movie title from journal data', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.text('Fight Club'), findsOneWidget);
    });

    testWidgets('Share Ticket button is tappable without errors',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Share Ticket'));
      await tester.pumpAndSettle();
      // No exception = handler ran without crash (currently a TODO stub)
    });

    testWidgets('checkmark has filled white circle with dark icon',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.byIcon(Icons.check),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, Colors.white);

      final icon = tester.widget<Icon>(find.byIcon(Icons.check));
      expect(icon.color, Colors.black);
    });

    testWidgets('all elements visible after animations complete',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text("You've saved a journal"), findsOneWidget);
      expect(find.byType(JournalCard), findsOneWidget);
      expect(find.text('Share Ticket'), findsOneWidget);
      expect(find.text('View Journal'), findsOneWidget);
    });
  });
}
