import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';
import 'package:movie_journal/features/share/controllers/ticket_number.dart';

import '../../../helpers/test_journal.dart';

/// Serves a fixed list without touching Supabase auth or the database.
class _FakeJournalsController extends JournalsController {
  _FakeJournalsController(this._journals);
  final List<JournalState> _journals;

  @override
  Future<JournalsState> build() async => JournalsState(journals: _journals);
}

void main() {
  ProviderContainer containerWith(List<JournalState> journals) {
    final container = ProviderContainer(
      overrides: [
        journalsControllerProvider.overrideWith(
          () => _FakeJournalsController(journals),
        ),
      ],
    );
    addTearDown(container.dispose);
    // Riverpod 3 auto-disposes unlistened providers mid-flight; keep the
    // element alive or `.future` never completes (see CLAUDE.md).
    container.listen(journalsControllerProvider, (_, _) {});
    return container;
  }

  JournalState journalOn(String id, String date) {
    final t = Jiffy.parse('$date 10:00:00');
    return makeJournal(id: id, createdAt: t, updatedAt: t);
  }

  group('ticketNumberProvider', () {
    test(
      'is the 1-based chronological position, whatever the list order',
      () async {
        final container = containerWith([
          journalOn('third', '2026-07-20'),
          journalOn('first', '2026-05-01'),
          journalOn('second', '2026-06-10'),
        ]);
        await container.read(journalsControllerProvider.future);

        expect(container.read(ticketNumberProvider('first')), 1);
        expect(container.read(ticketNumberProvider('second')), 2);
        expect(container.read(ticketNumberProvider('third')), 3);
      },
    );

    test('unknown id → 0', () async {
      final container = containerWith([journalOn('j1', '2026-07-01')]);
      await container.read(journalsControllerProvider.future);

      expect(container.read(ticketNumberProvider('nope')), 0);
    });

    test('0 while journals are still loading', () {
      final container = containerWith([journalOn('j1', '2026-07-01')]);
      // No await: the fake build() has not resolved yet.
      expect(container.read(ticketNumberProvider('j1')), 0);
    });
  });
}
