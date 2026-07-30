import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/journal/widgets/journal_actions.dart';
import 'package:movie_journal/features/share/screens/share_ticket_screen.dart';
import 'package:movie_journal/features/share/screens/ticket_poster_picker_screen.dart';

import '../../../helpers/test_journal.dart';
import '../../../helpers/widget_test_setup.dart';

void main() {
  setUpAll(() {
    setUpWidgetTests();
    // TicketPosterPickerScreen fetches movie details/posters on mount; the
    // TMDB client reads its token from dotenv at construction time.
    dotenv.loadFromString(envString: 'TMDB_ACCESS_TOKEN=test-token');
  });
  tearDownAll(tearDownWidgetTests);

  group('confirmDeleteJournal', () {
    Future<void> pumpHost(
      WidgetTester tester,
      void Function(bool) onResult,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                onResult(await confirmDeleteJournal(context));
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the confirmation dialog', (tester) async {
      await pumpHost(tester, (_) {});
      expect(find.text('Delete Journal'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete this journal?'),
        findsOneWidget,
      );
    });

    testWidgets('returns true when Delete is tapped', (tester) async {
      bool? result;
      await pumpHost(tester, (r) => result = r);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('returns false when Cancel is tapped', (tester) async {
      bool? result;
      await pumpHost(tester, (r) => result = r);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('returns false when dismissed via the barrier', (tester) async {
      bool? result;
      await pumpHost(tester, (r) => result = r);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });

  group('shareJournal', () {
    testWidgets(
      'pushes TicketPosterPickerScreen on a route tagged kShareFlowRouteName',
      (tester) async {
        final pushedRouteNames = <String?>[];
        final observer = _RecordingNavigatorObserver(pushedRouteNames);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              navigatorObservers: [observer],
              home: Builder(
                builder: (context) => TextButton(
                  onPressed: () => shareJournal(context, makeJournal()),
                  child: const Text('share'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('share'));
        // Bounded pumps: the picker shows an infinite skeleton shimmer while
        // loading, so pumpAndSettle would never settle.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(TicketPosterPickerScreen), findsOneWidget);
        expect(pushedRouteNames, contains(kShareFlowRouteName));
      },
    );
  });
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  _RecordingNavigatorObserver(this.pushedRouteNames);

  final List<String?> pushedRouteNames;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRouteNames.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}
