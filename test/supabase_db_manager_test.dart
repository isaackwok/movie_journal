import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:movie_journal/features/emotion/emotion.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/quesgen/review.dart';
import 'package:movie_journal/supabase_db_manager.dart';

import 'helpers/test_journal.dart';

/// Translation-layer tests for the Firestore -> Supabase migration.
///
/// These are deliberately zone-relative rather than hardcoding +08:00: CI and
/// developer machines run in different zones, and a test that only passes in
/// Asia/Taipei would be worse than no test. The invariants asserted hold in
/// every zone.
void main() {
  group('pgTimestampToLocalNaive', () {
    test('converts a Postgres timestamptz to the equivalent LOCAL wall time', () {
      // The bug this guards: JournalState.fromJson feeds this string straight
      // into Jiffy.parse. Handing Jiffy a UTC instant makes every screen render
      // the journal 8 hours early for a Taipei user.
      const pg = '2025-09-29T11:44:02.131+00:00';
      final out = SupabaseDbManager.pgTimestampToLocalNaive(pg);

      expect(
        DateTime.parse(out).isUtc,
        isFalse,
        reason: 'must be naive/local so Jiffy reads it as wall time',
      );
      expect(
        DateTime.parse(out),
        DateTime.parse(pg).toLocal(),
        reason: 'must denote the same instant, expressed locally',
      );
    });

    test('Jiffy.parse of the result yields local wall time, not UTC', () {
      const pg = '2025-09-29T11:44:02.131+00:00';
      final jiffy = Jiffy.parse(SupabaseDbManager.pgTimestampToLocalNaive(pg));
      final expectedLocal = DateTime.parse(pg).toLocal();

      expect(jiffy.hour, expectedLocal.hour);
      expect(jiffy.date, expectedLocal.day);
    });

    test('handles a non-UTC offset', () {
      const pg = '2025-09-29T19:44:02.131+08:00';
      expect(
        DateTime.parse(SupabaseDbManager.pgTimestampToLocalNaive(pg)),
        DateTime.parse(pg).toLocal(),
      );
    });
  });

  group('jiffyToUtcIso', () {
    test('emits an absolute UTC instant, never a naive local string', () {
      final local = DateTime(2025, 9, 29, 19, 44, 2);
      final out = SupabaseDbManager.jiffyToUtcIso(Jiffy.parseFromDateTime(local));

      expect(out, endsWith('Z'), reason: 'must carry a zone marker');
      expect(DateTime.parse(out).isUtc, isTrue);
      expect(DateTime.parse(out), local.toUtc());
    });

    test('differs from Jiffy.toString(), the naive-local bug being retired', () {
      final jiffy = Jiffy.parseFromDateTime(DateTime(2025, 9, 29, 19, 44, 2));
      final naive = jiffy.toString();
      final utc = SupabaseDbManager.jiffyToUtcIso(jiffy);

      // Identical only in a UTC+0 zone; asserting inequality there would be a
      // false failure, so the meaningful claim is that `utc` is zone-marked.
      if (DateTime.now().timeZoneOffset != Duration.zero) {
        expect(utc, isNot(equals(naive)));
      }
      expect(naive, isNot(endsWith('Z')));
    });

    test('round-trips local -> UTC -> local without drift', () {
      final local = DateTime(2025, 3, 14, 1, 59, 26);
      final utc = SupabaseDbManager.jiffyToUtcIso(Jiffy.parseFromDateTime(local));
      final back = SupabaseDbManager.pgTimestampToLocalNaive(utc);

      expect(DateTime.parse(back), local);
    });
  });

  group('rowToJournal', () {
    Map<String, dynamic> baseRow({
      Object? scenes,
      Object? refs,
      Object? emotions,
    }) => {
      'id': 'a1b2c3d4-0000-0000-0000-000000000001',
      'tmdb_id': 550,
      'movie_title': 'Fight Club',
      'movie_poster': '/poster.jpg',
      'emotions': emotions ?? const ['joyful'],
      'selected_scenes': scenes ?? const [],
      'selected_refs': refs ?? const [],
      'thoughts': 'a note',
      'created_at': '2025-09-29T11:44:02.131+00:00',
      'updated_at': '2025-09-30T11:44:02.131+00:00',
    };

    test('maps snake_case columns onto JournalState', () {
      final j = SupabaseDbManager.rowToJournal(baseRow());

      expect(j.id, 'a1b2c3d4-0000-0000-0000-000000000001');
      expect(j.tmdbId, 550);
      expect(j.movieTitle, 'Fight Club');
      expect(j.moviePoster, '/poster.jpg');
      expect(j.thoughts, 'a note');
      expect(j.emotions.single.id, 'joyful');
    });

    test('parses the modern object shape for scenes and refs', () {
      final j = SupabaseDbManager.rowToJournal(baseRow(
        scenes: [
          {'path': '/s1.jpg', 'caption': 'the fight'},
          {'path': '/s2.jpg'},
        ],
        refs: [
          {'text': 'great film', 'source': 'letterboxd'},
        ],
      ));

      expect(j.selectedScenes.length, 2);
      expect(j.selectedScenes[0].path, '/s1.jpg');
      expect(j.selectedScenes[0].caption, 'the fight');
      expect(j.selectedScenes[1].caption, isNull);
      expect(j.selectedRefs.single.text, 'great film');
      expect(j.selectedRefs.single.source, 'letterboxd');
    });

    test('parses the LEGACY plain-string shape for scenes and refs', () {
      // 87 scene entries and 30 ref entries in the production export are still
      // bare strings, so this path is load-bearing, not hypothetical.
      final j = SupabaseDbManager.rowToJournal(baseRow(
        scenes: ['/legacy1.jpg', '/legacy2.jpg'],
        refs: ['an old review'],
      ));

      expect(j.selectedScenes.map((s) => s.path), ['/legacy1.jpg', '/legacy2.jpg']);
      expect(j.selectedScenes.every((s) => s.caption == null), isTrue);
      expect(j.selectedRefs.single.text, 'an old review');
    });

    test('renders timestamps as local wall time', () {
      final j = SupabaseDbManager.rowToJournal(baseRow());
      final expected = DateTime.parse('2025-09-29T11:44:02.131+00:00').toLocal();

      expect(j.createdAt.hour, expected.hour);
      expect(j.createdAt.date, expected.day);
    });

    test('tolerates null jsonb/array columns', () {
      final row = baseRow()
        ..['emotions'] = null
        ..['selected_scenes'] = null
        ..['selected_refs'] = null;
      final j = SupabaseDbManager.rowToJournal(row);

      expect(j.emotions, isEmpty);
      expect(j.selectedScenes, isEmpty);
      expect(j.selectedRefs, isEmpty);
    });
  });

  group('journalToRow', () {
    test('produces snake_case columns with UTC timestamps', () {
      final journal = makeJournal(
        tmdbId: 680,
        movieTitle: 'Pulp Fiction',
        thoughts: 'wow',
        emotions: [emotionList[EmotionType.joyful]!],
        selectedScenes: [SceneItem(path: '/p.jpg', caption: 'diner')],
        selectedRefs: [Review(text: 'r', source: 'reddit')],
        createdAt: Jiffy.parseFromDateTime(DateTime(2025, 1, 2, 3, 4, 5)),
        updatedAt: Jiffy.parseFromDateTime(DateTime(2025, 1, 3, 4, 5, 6)),
      );

      final row = SupabaseDbManager.journalToRow(journal, userId: 'u-1');

      expect(row['user_id'], 'u-1');
      expect(row['tmdb_id'], 680);
      expect(row['movie_title'], 'Pulp Fiction');
      expect(row['thoughts'], 'wow');
      expect(row['emotions'], ['joyful']);
      expect(row['selected_scenes'], [
        {'path': '/p.jpg', 'caption': 'diner'},
      ]);
      expect((row['selected_refs'] as List).single['source'], 'reddit');
      expect(row['created_at'], endsWith('Z'));
      expect(row['updated_at'], endsWith('Z'));
    });

    test('never writes firestore_id — new-app rows must stay NULL', () {
      // The delta-sync only manages rows that came from Firestore. A new-app
      // journal that acquired a firestore_id could be deleted by the
      // deletion-propagation pass as "absent from the export".
      final row = SupabaseDbManager.journalToRow(makeJournal(), userId: 'u-1');
      expect(row.containsKey('firestore_id'), isFalse);
      expect(row.containsKey('raw'), isFalse);
      expect(row.containsKey('migrated_updated_at'), isFalse);
    });

    test('omits created_at on update so it is preserved', () {
      final row = SupabaseDbManager.journalToRow(
        makeJournal(),
        userId: 'u-1',
        includeCreatedAt: false,
      );
      expect(row.containsKey('created_at'), isFalse);
      expect(row.containsKey('updated_at'), isTrue);
    });
  });

  group('round trip', () {
    test('journal -> row -> journal preserves user-visible fields', () {
      final original = makeJournal(
        tmdbId: 13,
        movieTitle: 'Forrest Gump',
        moviePoster: '/fg.jpg',
        thoughts: 'run',
        emotions: [emotionList[EmotionType.touched]!],
        selectedScenes: [SceneItem(path: '/a.jpg', caption: 'bench')],
        selectedRefs: [Review(text: 'classic', source: 'letterboxd')],
        createdAt: Jiffy.parseFromDateTime(DateTime(2025, 6, 1, 12, 0, 0)),
        updatedAt: Jiffy.parseFromDateTime(DateTime(2025, 6, 2, 13, 30, 0)),
      );

      final row = SupabaseDbManager.journalToRow(original, userId: 'u-1');
      final restored = SupabaseDbManager.rowToJournal({
        ...row,
        'id': 'uuid-1',
        // Postgres echoes timestamptz back with an offset rather than a Z.
        'created_at': DateTime.parse(row['created_at'] as String)
            .toIso8601String()
            .replaceAll('Z', '+00:00'),
        'updated_at': DateTime.parse(row['updated_at'] as String)
            .toIso8601String()
            .replaceAll('Z', '+00:00'),
      });

      expect(restored.tmdbId, original.tmdbId);
      expect(restored.movieTitle, original.movieTitle);
      expect(restored.moviePoster, original.moviePoster);
      expect(restored.thoughts, original.thoughts);
      expect(restored.emotions.single.id, original.emotions.single.id);
      expect(restored.selectedScenes.single.path, '/a.jpg');
      expect(restored.selectedScenes.single.caption, 'bench');
      expect(restored.selectedRefs.single.text, 'classic');
      expect(
        restored.createdAt.dateTime,
        original.createdAt.dateTime,
        reason: 'timestamps must survive the local->UTC->local round trip',
      );
    });
  });
}
