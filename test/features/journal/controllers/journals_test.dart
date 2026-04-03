import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';

import '../../../helpers/test_journal.dart';

void main() {
  group('JournalsState', () {
    test('defaults to empty journals list', () {
      final state = JournalsState();
      expect(state.journals, isEmpty);
    });

    test('copyWith replaces journals list', () {
      final state = JournalsState();
      final journals = [
        makeJournal(id: 'j1', movieTitle: 'Fight Club'),
        makeJournal(id: 'j2', movieTitle: 'Inception'),
      ];

      final updated = state.copyWith(journals: journals);
      expect(updated.journals.length, 2);
      expect(updated.journals[0].movieTitle, 'Fight Club');
      expect(updated.journals[1].movieTitle, 'Inception');
    });

    test('copyWith preserves journals when not provided', () {
      final journals = [makeJournal(id: 'j1')];
      final state = JournalsState(journals: journals);

      final updated = state.copyWith();
      expect(updated.journals.length, 1);
      expect(updated.journals[0].id, 'j1');
    });

    test('copyWith does not mutate original state', () {
      final original = JournalsState(journals: [makeJournal(id: 'j1')]);
      final updated = original.copyWith(
        journals: [makeJournal(id: 'j2'), makeJournal(id: 'j3')],
      );

      expect(original.journals.length, 1);
      expect(updated.journals.length, 2);
    });
  });
}
