import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/movie/controllers/search_movie_controller.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';
import 'package:movie_journal/features/search_movie/widgets/movie_search_bar.dart';

import '../../../helpers/widget_test_setup.dart';

/// Records every `search()` call and never touches the network, so the
/// widget's debounce timing can be asserted in isolation.
class _FakeSearchMovieController extends SearchMovieController {
  final List<String> searchCalls = [];

  @override
  Future<SearchMovieState> build() async => SearchMovieState();

  @override
  Future<void> search(String query) async {
    searchCalls.add(query);
  }
}

Widget _wrap(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: Scaffold(body: MovieSearchBar())),
  );
}

void main() {
  setUpAll(setUpWidgetTests);
  tearDownAll(tearDownWidgetTests);

  group('MovieSearchBar debounce', () {
    late ProviderContainer container;
    late _FakeSearchMovieController fake;

    setUp(() {
      fake = _FakeSearchMovieController();
      container = ProviderContainer(
        overrides: [
          searchMovieControllerProvider.overrideWith(() => fake),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('does not search before the debounce window elapses', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(container));

      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump(const Duration(milliseconds: 100));

      expect(fake.searchCalls, isEmpty);

      // Unmount to cancel the still-pending debounce timer.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('searches once after 300ms of inactivity', (tester) async {
      await tester.pumpWidget(_wrap(container));

      await tester.enterText(find.byType(TextField), 'inception');
      await tester.pump(const Duration(milliseconds: 300));

      expect(fake.searchCalls, ['inception']);
    });

    testWidgets('rapid typing collapses to a single search of the final text', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(container));

      // Each keystroke lands inside the previous 300ms window, so every
      // pending timer is cancelled until typing finally pauses.
      await tester.enterText(find.byType(TextField), 'i');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'in');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'inc');
      await tester.pump(const Duration(milliseconds: 100));

      expect(fake.searchCalls, isEmpty);

      await tester.pump(const Duration(milliseconds: 300));

      expect(fake.searchCalls, ['inc']);
    });

    testWidgets('clearing the field debounce-resets with an empty query', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(container));

      await tester.enterText(find.byType(TextField), 'inception');
      await tester.pump(const Duration(milliseconds: 300));
      expect(fake.searchCalls, ['inception']);

      // The clear (X) button edits the controller programmatically; the
      // controller listener still fires, so we debounce-reset to popular.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump(const Duration(milliseconds: 300));

      expect(fake.searchCalls, ['inception', '']);
    });

    testWidgets('explicit submit searches immediately and pre-empts the timer', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(container));

      await tester.enterText(find.byType(TextField), 'matrix');
      // Submit before the 300ms debounce would have fired.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      // One immediate call from the submit...
      expect(fake.searchCalls, ['matrix']);

      // ...and the cancelled debounce never adds a second.
      await tester.pump(const Duration(milliseconds: 300));
      expect(fake.searchCalls, ['matrix']);
    });
  });
}
