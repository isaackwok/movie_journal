import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';

import '../../../helpers/test_journal.dart';

// Note: journals.dart now includes an AnalyticsManager call in removeJournal().
// This is a no-op without Firebase and doesn't affect copyWith tests below.

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

  group('JournalsState value equality', () {
    test('same journals (by value) → equal, same hashCode', () {
      final t = Jiffy.parse('2026-07-30 10:00:00');
      final a = JournalsState(
        journals: [makeJournal(id: 'j1', createdAt: t, updatedAt: t)],
      );
      final b = JournalsState(
        journals: [makeJournal(id: 'j1', createdAt: t, updatedAt: t)],
      );
      expect(identical(a.journals, b.journals), isFalse);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('empty states → equal', () {
      expect(JournalsState(), equals(JournalsState()));
    });

    test('different journals → not equal', () {
      final t = Jiffy.parse('2026-07-30 10:00:00');
      final a = JournalsState(
        journals: [makeJournal(id: 'j1', createdAt: t, updatedAt: t)],
      );
      final b = JournalsState(
        journals: [makeJournal(id: 'j2', createdAt: t, updatedAt: t)],
      );
      expect(a, isNot(equals(b)));
    });

    test('different length → not equal', () {
      final t = Jiffy.parse('2026-07-30 10:00:00');
      final journal = makeJournal(id: 'j1', createdAt: t, updatedAt: t);
      final a = JournalsState(journals: [journal]);
      final b = JournalsState(journals: [journal, journal]);
      expect(a, isNot(equals(b)));
    });
  });
}
