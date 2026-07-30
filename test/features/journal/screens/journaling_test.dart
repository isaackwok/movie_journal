import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/emotion/emotion.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/screens/journaling.dart';
import 'package:movie_journal/themes.dart';

import '../../../helpers/test_journal.dart';
import '../../../helpers/widget_test_setup.dart';

/// A journal controller whose save() always fails, standing in for a dead
/// network / Supabase outage. Non-empty emotions keep the Save button enabled.
class _FailingSaveController extends JournalController {
  @override
  JournalState build() =>
      makeJournal(emotions: [emotionList[EmotionType.joyful]!]);

  @override
  Future<JournalController> save() async {
    throw Exception('supabase unreachable');
  }
}

void main() {
  setUpAll(() => setUpWidgetTests());
  tearDownAll(() => tearDownWidgetTests());

  group('JournalingScreen save failure', () {
    // Regression test for ISA-9 bug 1: the catch block used to call
    // CustomToast.showSuccess with the failure message, so a failed save
    // looked exactly like a successful one.
    testWidgets('shows an error toast, not a success toast', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            journalControllerProvider.overrideWith(_FailingSaveController.new),
          ],
          child: const MaterialApp(
            home: JournalingScreen(
              movieTitle: 'Fight Club',
              moviePosterUrl: '/poster.jpg',
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Failed to save journal. Please try again.'),
        findsOneWidget,
      );

      // The toast must carry the *error* styling: a close glyph in a circle
      // filled with the error status color (success would be a check on the
      // primary color).
      final toastCircle = tester.widget<Container>(
        find
            .ancestor(
              of: find.byIcon(Icons.close),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = toastCircle.decoration as BoxDecoration;
      expect(decoration.color, StatusColors.error);

      // The screen stays put (no navigation to JournalComplete) and the Save
      // button recovers from its spinner state for a retry.
      expect(find.text('Save'), findsOneWidget);

      // Drain the fluttertoast timers before the test ends. pumpAndSettle
      // would never return here: the scenes selector's skeleton shimmer loops
      // forever because movieImages stays AsyncLoading by design (see
      // MovieImagesController.build in CLAUDE.md), so use fixed pumps.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
