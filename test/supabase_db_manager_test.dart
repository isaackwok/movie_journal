import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:movie_journal/features/emotion/emotion.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/quesgen/review.dart';
import 'package:movie_journal/supabase_db_manager.dart';

import 'helpers/test_journal.dart';

void main() {
  group('SupabaseDbManager.journalToRow', () {
    final manager = SupabaseDbManager();

    test('maps camelCase JournalState fields to snake_case row columns', () {
      final journal = makeJournal(
        tmdbId: 27205,
        movieTitle: 'Inception',
        moviePoster: '/inception.jpg',
        emotions: [emotionList[EmotionType.mindBlown]!],
        selectedScenes: [
          SceneItem(path: '/scene1.jpg', caption: 'dream collapse'),
        ],
        selectedRefs: [Review(text: 'great', source: 'letterboxd')],
        thoughts: 'loved it',
      );

      final row = manager.journalToRow(journal);

      expect(row['tmdb_id'], 27205);
      expect(row['movie_title'], 'Inception');
      expect(row['movie_poster'], '/inception.jpg');
      expect(row['emotions'], isA<List>());
      expect(row['selected_scenes'], isA<List>());
      expect(row['selected_refs'], isA<List>());
      expect(row['thoughts'], 'loved it');
      expect(row['created_at'], isA<String>());
      expect(row['updated_at'], isA<String>());
      // No raw Firestore fields leak through.
      expect(row.containsKey('tmdbId'), isFalse);
      expect(row.containsKey('movieTitle'), isFalse);
    });

    test('does NOT include user_id (caller adds it separately)', () {
      final row = manager.journalToRow(makeJournal());
      expect(row.containsKey('user_id'), isFalse);
    });
  });

  group('SupabaseDbManager.rowToJournalJson', () {
    final manager = SupabaseDbManager();

    test('maps snake_case row columns back to camelCase JSON keys', () {
      final row = {
        'id': 'abc-123',
        'tmdb_id': 550,
        'movie_title': 'Fight Club',
        'movie_poster': '/poster.jpg',
        'emotions': ['joyful'],
        'selected_scenes': [
          {'path': '/s1.jpg'}
        ],
        'selected_refs': [
          {'text': 'good', 'source': 'reddit'}
        ],
        'thoughts': 'hello',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-02T00:00:00.000Z',
        'user_id': 'user-xyz',
      };

      final json = manager.rowToJournalJson(row);

      expect(json['id'], 'abc-123');
      expect(json['tmdbId'], 550);
      expect(json['movieTitle'], 'Fight Club');
      expect(json['moviePoster'], '/poster.jpg');
      expect(json['thoughts'], 'hello');
      expect(json.containsKey('userId'), isFalse);
      expect(json.containsKey('user_id'), isFalse);
    });

    test('provides defaults when nullable columns are missing', () {
      final json = manager.rowToJournalJson({
        'id': 'x',
        'tmdb_id': 1,
        'movie_title': 'T',
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      expect(json['moviePoster'], '');
      expect(json['emotions'], isEmpty);
      expect(json['selectedScenes'], isEmpty);
      expect(json['selectedRefs'], isEmpty);
      expect(json['thoughts'], '');
    });

    test('round-trips through JournalState.fromJson', () {
      // Round-trip simulating what getJournalsCollection does:
      // row → rowToJournalJson → jsonEncode → JournalState.fromJson.
      final row = manager.journalToRow(
        makeJournal(
          id: 'journal-1',
          tmdbId: 27205,
          movieTitle: 'Inception',
          moviePoster: '/inception.jpg',
          emotions: [emotionList[EmotionType.mindBlown]!],
          selectedScenes: [SceneItem(path: '/s.jpg')],
          selectedRefs: [Review(text: 't', source: 'letterboxd')],
          thoughts: 'loved it',
          createdAt: Jiffy.parseFromDateTime(DateTime.utc(2024, 1, 1)),
          updatedAt: Jiffy.parseFromDateTime(DateTime.utc(2024, 1, 2)),
        ),
      );
      // Simulate what Supabase returns: row columns plus `id`.
      final rowWithId = {...row, 'id': 'journal-1'};
      final parsed = JournalState.fromJson(
        jsonEncode(manager.rowToJournalJson(rowWithId)),
      );

      expect(parsed.id, 'journal-1');
      expect(parsed.tmdbId, 27205);
      expect(parsed.movieTitle, 'Inception');
      expect(parsed.moviePoster, '/inception.jpg');
      expect(parsed.thoughts, 'loved it');
      expect(parsed.emotions.length, 1);
      expect(parsed.emotions.first.id, 'mindBlown');
      expect(parsed.selectedScenes.length, 1);
      expect(parsed.selectedScenes.first.path, '/s.jpg');
      expect(parsed.selectedRefs.length, 1);
      expect(parsed.selectedRefs.first.text, 't');
    });
  });
}
