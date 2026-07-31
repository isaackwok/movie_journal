import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:movie_journal/features/emotion/emotion.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/quesgen/review.dart';

import '../../../helpers/test_journal.dart';

// Note: journal.dart now includes AnalyticsManager calls in save()/update().
// These are no-ops without Firebase and don't affect model/state tests below.

void main() {
  // ── JournalState (data model) ──────────────────────────────────────

  group('JournalState', () {
    test('default constructor sets UUID id, createdAt = now, updatedAt = createdAt', () {
      final before = Jiffy.now();
      final journal = JournalState();
      final after = Jiffy.now();

      // id should be a valid UUID (36 chars with dashes)
      expect(journal.id.length, 36);
      expect(journal.id.contains('-'), true);

      // createdAt should be between before and after
      expect(
        journal.createdAt.microsecondsSinceEpoch,
        greaterThanOrEqualTo(before.microsecondsSinceEpoch),
      );
      expect(
        journal.createdAt.microsecondsSinceEpoch,
        lessThanOrEqualTo(after.microsecondsSinceEpoch),
      );

      // updatedAt should equal createdAt
      expect(
        journal.updatedAt.microsecondsSinceEpoch,
        journal.createdAt.microsecondsSinceEpoch,
      );
    });

    test('copyWith() preserves unchanged fields', () {
      final journal = makeJournal(
        id: 'test-id',
        tmdbId: 550,
        movieTitle: 'Fight Club',
        thoughts: 'Great movie',
      );

      final copy = journal.copyWith(thoughts: 'Updated');

      expect(copy.id, 'test-id');
      expect(copy.tmdbId, 550);
      expect(copy.movieTitle, 'Fight Club');
      expect(copy.thoughts, 'Updated');
    });

    test('copyWith() overrides specified fields', () {
      final journal = makeJournal(tmdbId: 550, movieTitle: 'Fight Club');
      final emotions = [emotionList[EmotionType.joyful]!];

      final copy = journal.copyWith(
        tmdbId: 999,
        movieTitle: 'New Movie',
        emotions: emotions,
      );

      expect(copy.tmdbId, 999);
      expect(copy.movieTitle, 'New Movie');
      expect(copy.emotions, emotions);
    });

    test('toMap() serializes emotions as ID strings, scenes as maps, reviews as maps', () {
      final journal = makeJournal(
        emotions: [emotionList[EmotionType.joyful]!],
        selectedScenes: [SceneItem(path: '/scene.jpg', caption: 'Nice')],
        selectedRefs: [Review(text: 'Great', source: 'reddit')],
      );

      final map = journal.toMap();

      expect(map['emotions'], ['joyful']);
      expect(map['selectedScenes'], [
        {'path': '/scene.jpg', 'caption': 'Nice'},
      ]);
      expect(map['selectedRefs'], [
        {'text': 'Great', 'source': 'reddit'},
      ]);
      // toMap should NOT include id
      expect(map.containsKey('id'), false);
    });

    test('toJson() includes id field (unlike toMap())', () {
      final journal = makeJournal(id: 'my-id');
      final jsonStr = journal.toJson();
      final decoded = jsonDecode(jsonStr);

      expect(decoded['id'], 'my-id');
    });

    test('fromJson() round-trip — serialize then deserialize produces equivalent state', () {
      final original = makeJournal(
        id: 'roundtrip-id',
        tmdbId: 550,
        movieTitle: 'Fight Club',
        moviePoster: '/poster.jpg',
        emotions: [
          emotionList[EmotionType.joyful]!,
          emotionList[EmotionType.inspired]!,
        ],
        selectedScenes: [
          SceneItem(path: '/scene1.jpg', caption: 'Opening'),
          SceneItem(path: '/scene2.jpg'),
        ],
        selectedRefs: [Review(text: 'Amazing', source: 'letterboxd')],
        thoughts: 'Mind-blowing experience',
      );

      final restored = JournalState.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.tmdbId, original.tmdbId);
      expect(restored.movieTitle, original.movieTitle);
      expect(restored.moviePoster, original.moviePoster);
      expect(restored.emotions.length, original.emotions.length);
      expect(restored.emotions[0].id, original.emotions[0].id);
      expect(restored.emotions[1].id, original.emotions[1].id);
      expect(restored.selectedScenes.length, original.selectedScenes.length);
      expect(restored.selectedScenes[0].path, '/scene1.jpg');
      expect(restored.selectedScenes[0].caption, 'Opening');
      expect(restored.selectedScenes[1].caption, isNull);
      expect(restored.selectedRefs.length, 1);
      expect(restored.selectedRefs[0].text, 'Amazing');
      expect(restored.selectedRefs[0].source, 'letterboxd');
      expect(restored.thoughts, 'Mind-blowing experience');
    });

    test('fromJson() backward compat — old string-format scenes → SceneItem', () {
      final json = jsonEncode({
        'id': 'compat-id',
        'tmdbId': 550,
        'movieTitle': 'Fight Club',
        'moviePoster': '/poster.jpg',
        'emotions': <String>[],
        'selectedScenes': ['/old-scene1.jpg', '/old-scene2.jpg'],
        'selectedRefs': <String>[],
        'thoughts': '',
        'createdAt': Jiffy.now().toString(),
        'updatedAt': Jiffy.now().toString(),
      });

      final journal = JournalState.fromJson(json);

      expect(journal.selectedScenes.length, 2);
      expect(journal.selectedScenes[0].path, '/old-scene1.jpg');
      expect(journal.selectedScenes[0].caption, isNull);
      expect(journal.selectedScenes[1].path, '/old-scene2.jpg');
    });

    test('fromJson() backward compat — old string-format reviews → Review', () {
      final json = jsonEncode({
        'id': 'compat-id',
        'tmdbId': 550,
        'movieTitle': 'Fight Club',
        'moviePoster': '/poster.jpg',
        'emotions': <String>[],
        'selectedScenes': <String>[],
        'selectedRefs': ['Old review text', 'Another old review'],
        'thoughts': '',
        'createdAt': Jiffy.now().toString(),
        'updatedAt': Jiffy.now().toString(),
      });

      final journal = JournalState.fromJson(json);

      expect(journal.selectedRefs.length, 2);
      expect(journal.selectedRefs[0].text, 'Old review text');
      expect(journal.selectedRefs[0].source, 'unknown');
      expect(journal.selectedRefs[1].text, 'Another old review');
    });

    test('fromJson() handles missing/null optional fields gracefully', () {
      final json = jsonEncode({
        'tmdbId': 550,
        // no id, no movieTitle, no moviePoster, no emotions, etc.
      });

      final journal = JournalState.fromJson(json);

      expect(journal.id, '');
      expect(journal.movieTitle, '');
      expect(journal.moviePoster, '');
      expect(journal.emotions, isEmpty);
      expect(journal.selectedScenes, isEmpty);
      expect(journal.selectedRefs, isEmpty);
      expect(journal.thoughts, '');
    });

    test('fromJson() parses tmdbId from both int and string formats', () {
      final fromInt = JournalState.fromJson(jsonEncode({
        'tmdbId': 550,
        'createdAt': Jiffy.now().toString(),
        'updatedAt': Jiffy.now().toString(),
      }));
      expect(fromInt.tmdbId, 550);

      final fromString = JournalState.fromJson(jsonEncode({
        'tmdbId': '550',
        'createdAt': Jiffy.now().toString(),
        'updatedAt': Jiffy.now().toString(),
      }));
      expect(fromString.tmdbId, 550);
    });
  });

  // ── SceneItem ──────────────────────────────────────────────────────

  group('SceneItem', () {
    test('toMap() omits caption when null or empty', () {
      final scene = SceneItem(path: '/scene.jpg');
      expect(scene.toMap(), {'path': '/scene.jpg'});

      final emptyCaption = SceneItem(path: '/scene.jpg', caption: '');
      expect(emptyCaption.toMap(), {'path': '/scene.jpg'});
    });

    test('toMap() includes caption when present', () {
      final scene = SceneItem(path: '/scene.jpg', caption: 'Great shot');
      expect(scene.toMap(), {'path': '/scene.jpg', 'caption': 'Great shot'});
    });

    test('fromMap() parses path and caption', () {
      final scene = SceneItem.fromMap({
        'path': '/scene.jpg',
        'caption': 'Beautiful',
      });
      expect(scene.path, '/scene.jpg');
      expect(scene.caption, 'Beautiful');
    });

    test('fromString() creates SceneItem with null caption (backward compat)', () {
      final scene = SceneItem.fromString('/old-scene.jpg');
      expect(scene.path, '/old-scene.jpg');
      expect(scene.caption, isNull);
    });

    test('copyWith() works correctly', () {
      final scene = SceneItem(path: '/scene.jpg', caption: 'Old');
      final updated = scene.copyWith(caption: 'New');

      expect(updated.path, '/scene.jpg');
      expect(updated.caption, 'New');
    });
  });

  // ── JournalController (Riverpod state mutations) ───────────────────

  group('JournalController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('setMovie() updates tmdbId, movieTitle, moviePoster together', () {
      final controller = container.read(journalControllerProvider.notifier);
      controller.setMovie(550, 'Fight Club', '/poster.jpg');

      final state = container.read(journalControllerProvider);
      expect(state.tmdbId, 550);
      expect(state.movieTitle, 'Fight Club');
      expect(state.moviePoster, '/poster.jpg');
    });

    test('setEmotions() replaces the emotions list', () {
      final controller = container.read(journalControllerProvider.notifier);
      final emotions = [
        emotionList[EmotionType.joyful]!,
        emotionList[EmotionType.peaceful]!,
      ];
      controller.setEmotions(emotions);

      final state = container.read(journalControllerProvider);
      expect(state.emotions.length, 2);
      expect(state.emotions[0].id, 'joyful');
      expect(state.emotions[1].id, 'peaceful');
    });

    test('addSelectedScene() appends a new SceneItem', () {
      final controller = container.read(journalControllerProvider.notifier);
      controller.addSelectedScene('/scene1.jpg');
      controller.addSelectedScene('/scene2.jpg');

      final state = container.read(journalControllerProvider);
      expect(state.selectedScenes.length, 2);
      expect(state.selectedScenes[0].path, '/scene1.jpg');
      expect(state.selectedScenes[1].path, '/scene2.jpg');
    });

    test('removeScene() removes by path', () {
      final controller = container.read(journalControllerProvider.notifier);
      controller.addSelectedScene('/scene1.jpg');
      controller.addSelectedScene('/scene2.jpg');
      controller.removeScene('/scene1.jpg');

      final state = container.read(journalControllerProvider);
      expect(state.selectedScenes.length, 1);
      expect(state.selectedScenes[0].path, '/scene2.jpg');
    });

    test('addSelectedReview() appends a review', () {
      final controller = container.read(journalControllerProvider.notifier);
      final review = Review(text: 'Amazing', source: 'letterboxd');
      controller.addSelectedReview(review);

      final state = container.read(journalControllerProvider);
      expect(state.selectedRefs.length, 1);
      expect(state.selectedRefs[0].text, 'Amazing');
    });

    test('removeSelectedReview() removes by equality', () {
      final controller = container.read(journalControllerProvider.notifier);
      final r1 = Review(text: 'A', source: 'reddit');
      final r2 = Review(text: 'B', source: 'letterboxd');
      controller.addSelectedReview(r1);
      controller.addSelectedReview(r2);
      controller.removeSelectedReview(r1);

      final state = container.read(journalControllerProvider);
      expect(state.selectedRefs.length, 1);
      expect(state.selectedRefs[0].text, 'B');
    });

    test('updateSceneCaption() updates caption on matching scene, leaves others unchanged', () {
      final controller = container.read(journalControllerProvider.notifier);
      controller.addSelectedScene('/scene1.jpg');
      controller.addSelectedScene('/scene2.jpg');
      controller.updateSceneCaption('/scene1.jpg', 'Caption for scene 1');

      final state = container.read(journalControllerProvider);
      expect(state.selectedScenes[0].caption, 'Caption for scene 1');
      expect(state.selectedScenes[1].caption, isNull);
    });

    test('updateSceneCaption() with empty string passes null to copyWith', () {
      // Note: SceneItem.copyWith uses `caption ?? this.caption`, so passing
      // null (from empty string) preserves the existing caption if one exists.
      // This tests the intended path where a scene without a prior caption
      // remains null after setting empty.
      final controller = container.read(journalControllerProvider.notifier);
      controller.addSelectedScene('/scene.jpg');
      controller.updateSceneCaption('/scene.jpg', '');

      final state = container.read(journalControllerProvider);
      expect(state.selectedScenes[0].caption, isNull);
    });

    test('getSceneCaption() returns caption for existing scene', () {
      final controller = container.read(journalControllerProvider.notifier);
      controller.addSelectedScene('/scene.jpg');
      controller.updateSceneCaption('/scene.jpg', 'My caption');

      expect(controller.getSceneCaption('/scene.jpg'), 'My caption');
    });

    test('getSceneCaption() returns empty string for unknown scene', () {
      final controller = container.read(journalControllerProvider.notifier);
      expect(controller.getSceneCaption('/nonexistent.jpg'), '');
    });

    test('loadJournal() copies full journal state into controller', () {
      final journal = makeJournal(
        id: 'loaded-id',
        tmdbId: 999,
        movieTitle: 'Loaded Movie',
        thoughts: 'Loaded thoughts',
        emotions: [emotionList[EmotionType.touched]!],
      );

      final controller = container.read(journalControllerProvider.notifier);
      controller.loadJournal(journal);

      final state = container.read(journalControllerProvider);
      expect(state.id, 'loaded-id');
      expect(state.tmdbId, 999);
      expect(state.movieTitle, 'Loaded Movie');
      expect(state.thoughts, 'Loaded thoughts');
      expect(state.emotions.length, 1);
      expect(state.emotions[0].id, 'touched');
    });

    test('clear() resets to default empty state', () {
      final controller = container.read(journalControllerProvider.notifier);
      controller.setMovie(550, 'Fight Club', '/poster.jpg');
      controller.setThoughts('Some thoughts');

      controller.clear();

      final state = container.read(journalControllerProvider);
      expect(state.tmdbId, 0);
      expect(state.movieTitle, '');
      expect(state.thoughts, '');
      expect(state.emotions, isEmpty);
      expect(state.selectedScenes, isEmpty);
      expect(state.selectedRefs, isEmpty);
    });

    test('setThoughts() updates thoughts field', () {
      final controller = container.read(journalControllerProvider.notifier);
      controller.setThoughts('My deep thoughts about the movie');

      final state = container.read(journalControllerProvider);
      expect(state.thoughts, 'My deep thoughts about the movie');
    });
  });

  // ── Value equality (ISA-12 item 1) ─────────────────────────────────

  group('SceneItem value equality', () {
    test('same path + caption → equal, same hashCode', () {
      final a = SceneItem(path: '/scene.jpg', caption: 'wow');
      final b = SceneItem(path: '/scene.jpg', caption: 'wow');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('null captions on both sides → equal', () {
      expect(SceneItem(path: '/s.jpg'), equals(SceneItem(path: '/s.jpg')));
    });

    test('different caption → not equal', () {
      final a = SceneItem(path: '/scene.jpg', caption: 'wow');
      final b = SceneItem(path: '/scene.jpg', caption: 'meh');
      expect(a, isNot(equals(b)));
    });

    test('caption set vs null → not equal', () {
      final a = SceneItem(path: '/scene.jpg', caption: 'wow');
      final b = SceneItem(path: '/scene.jpg');
      expect(a, isNot(equals(b)));
    });

    test('different path → not equal', () {
      expect(
        SceneItem(path: '/a.jpg'),
        isNot(equals(SceneItem(path: '/b.jpg'))),
      );
    });
  });

  group('JournalState value equality', () {
    JournalState buildJournal() {
      final t = Jiffy.parse('2026-07-30 10:00:00');
      return makeJournal(
        id: 'fixed-id',
        tmdbId: 550,
        movieTitle: 'Fight Club',
        thoughts: 'great',
        emotions: [emotionList[EmotionType.joyful]!],
        selectedScenes: [SceneItem(path: '/s.jpg', caption: 'c')],
        selectedRefs: [Review(text: 'r', source: 'reddit')],
        createdAt: t,
        updatedAt: t,
      );
    }

    test('same field values → equal, same hashCode', () {
      final a = buildJournal();
      final b = buildJournal();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('lists are compared by value, not identity', () {
      final a = buildJournal();
      final b = buildJournal();
      expect(identical(a.selectedScenes, b.selectedScenes), isFalse);
      expect(identical(a.selectedRefs, b.selectedRefs), isFalse);
      expect(a, equals(b));
    });

    test('copyWith with no args → equal to original', () {
      final a = buildJournal();
      expect(a.copyWith(), equals(a));
    });

    test('each field difference breaks equality', () {
      final a = buildJournal();
      expect(a.copyWith(id: 'other'), isNot(equals(a)));
      expect(a.copyWith(tmdbId: 551), isNot(equals(a)));
      expect(a.copyWith(movieTitle: 'Se7en'), isNot(equals(a)));
      expect(a.copyWith(moviePoster: '/x.jpg'), isNot(equals(a)));
      expect(a.copyWith(thoughts: 'meh'), isNot(equals(a)));
      expect(
        a.copyWith(emotions: [emotionList[EmotionType.angry]!]),
        isNot(equals(a)),
      );
      expect(
        a.copyWith(selectedScenes: [SceneItem(path: '/other.jpg')]),
        isNot(equals(a)),
      );
      expect(
        a.copyWith(selectedRefs: [Review(text: 'x', source: 'letterboxd')]),
        isNot(equals(a)),
      );
      expect(
        a.copyWith(createdAt: Jiffy.parse('2020-01-01 00:00:00')),
        isNot(equals(a)),
      );
      expect(
        a.copyWith(updatedAt: Jiffy.parse('2020-01-01 00:00:00')),
        isNot(equals(a)),
      );
    });
  });

  group('notification behavior with value equality', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('assigning an equal state does not notify listeners', () {
      var notifications = 0;
      container.listen(journalControllerProvider, (_, _) => notifications++);
      final controller = container.read(journalControllerProvider.notifier);

      controller.setThoughts('hello');
      expect(notifications, 1);

      // Same value again: copyWith produces an equal state, and Riverpod's
      // default updateShouldNotify compares with ==, so no notification.
      controller.setThoughts('hello');
      expect(notifications, 1);
    });

    test('select(selectedScenes) ignores unrelated field changes', () {
      var notifications = 0;
      container.listen(
        journalControllerProvider.select((j) => j.selectedScenes),
        (_, _) => notifications++,
      );
      final controller = container.read(journalControllerProvider.notifier);

      controller.setThoughts('unrelated');
      controller.setMovieTitle('unrelated too');
      expect(notifications, 0);

      controller.addScene('/s.jpg');
      expect(notifications, 1);
    });

    test('select(thoughts) ignores scene changes', () {
      var notifications = 0;
      container.listen(
        journalControllerProvider.select((j) => j.thoughts),
        (_, _) => notifications++,
      );
      final controller = container.read(journalControllerProvider.notifier);

      controller.addScene('/s.jpg');
      expect(notifications, 0);

      controller.setThoughts('now');
      expect(notifications, 1);
    });
  });

  group('JournalState.fromMap', () {
    Map<String, dynamic> journalMap() => {
          'id': 'j1',
          'tmdbId': 550,
          'movieTitle': 'Fight Club',
          'moviePoster': '/poster.jpg',
          'emotions': ['joyful'],
          'selectedScenes': [
            {'path': '/scene.jpg', 'caption': 'the ending'},
            '/legacy_scene.jpg',
          ],
          'selectedRefs': [
            {'text': 'great movie', 'source': 'letterboxd'},
            'legacy plain-string review',
          ],
          'thoughts': 'wow',
          'createdAt': '2026-07-01 10:00:00',
          'updatedAt': '2026-07-02 11:00:00',
        };

    test('parses a decoded map identically to fromJson(encoded)', () {
      final map = journalMap();
      // jsonDecode(jsonEncode()) mirrors what fromJson used to see.
      expect(
        JournalState.fromMap(map),
        equals(JournalState.fromJson(jsonEncode(map))),
      );
    });

    test('fromJson is fromMap over the decoded string', () {
      final journal = JournalState.fromJson(jsonEncode(journalMap()));
      expect(journal.id, 'j1');
      expect(journal.selectedScenes, hasLength(2));
      expect(journal.selectedScenes[1].path, '/legacy_scene.jpg');
      expect(journal.selectedRefs, hasLength(2));
      expect(journal.selectedRefs[1].text, 'legacy plain-string review');
      expect(journal.createdAt.format(pattern: 'yyyy-MM-dd'), '2026-07-01');
    });
  });
}
