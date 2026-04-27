import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/home/widgets/journal_card.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/screens/journal_complete.dart';
import 'package:movie_journal/features/share/screens/share_ticket_screen.dart';
import 'package:movie_journal/features/share/screens/ticket_poster_picker_screen.dart';

import '../../../helpers/test_journal.dart';
import '../../../helpers/widget_test_setup.dart';

// Note: journal_complete.dart now logs a screen view in initState via AnalyticsManager.
// The call is safely wrapped and is a no-op without Firebase — no test changes needed.

void main() {
  setUpAll(() => setUpWidgetTests());
  tearDownAll(() => tearDownWidgetTests());

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

    testWidgets('Share Ticket navigates to TicketPosterPickerScreen',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Share Ticket'));
      await tester.pumpAndSettle();

      // Verifies the new required `entry` parameter is satisfied and
      // navigation from JournalComplete reaches the poster picker screen.
      expect(find.byType(TicketPosterPickerScreen), findsOneWidget);
    });

    testWidgets(
      'Share Ticket pushes a route tagged with kShareFlowRouteName',
      (tester) async {
        // Tagging is load-bearing: closeShareFlow popUntil's predicate uses the
        // route name to know where the share flow ends. If the tag is missing,
        // the journalContent close path overshoots back past JournalContent.
        final observer = _RouteSettingsObserver();
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              navigatorObservers: [observer],
              home: JournalCompleteScreen(journal: journal),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Share Ticket'));
        await tester.pumpAndSettle();

        expect(observer.lastPushedName, kShareFlowRouteName);
      },
    );

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

class _RouteSettingsObserver extends NavigatorObserver {
  String? lastPushedName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    lastPushedName = route.settings.name;
  }
}
