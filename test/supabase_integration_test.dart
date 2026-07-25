@Timeout(Duration(minutes: 2))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:movie_journal/features/emotion/emotion.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/quesgen/review.dart';
import 'package:movie_journal/supabase_db_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'helpers/test_journal.dart';

/// Integration tests for [SupabaseDbManager] against a LIVE local stack.
///
/// Run:
///   supabase start
///   SUPABASE_TEST=1 flutter test test/supabase_integration_test.dart
///
/// Skipped by default so `flutter test` stays hermetic and offline.
///
/// Why these exist even though the translation layer is unit-tested: those
/// tests verify the shape of the map handed to PostgREST, not that Postgres
/// accepts it. A misspelled column, a type PostgREST rejects, a filter that
/// silently matches nothing, or an RLS policy that quietly denies a write all
/// pass every unit test and fail only on a device. Nothing else in the suite
/// puts the manager in front of a real database.
///
/// Users are created with anonymous sign-in rather than email/password: email
/// auth is disabled on this project by design, and anonymous sign-in is
/// already on for the migration bridge. Anonymous users get the same
/// `authenticated` role, so they exercise exactly the same RLS policies.

/// In-memory PKCE store.
///
/// `Supabase.initialize` otherwise defaults to a shared_preferences-backed one,
/// which needs a platform channel that a test VM does not have — it fails with
/// `MissingPluginException` before any test body runs. Supplying this (as well
/// as [EmptyLocalStorage], which only covers the *session* store) is what makes
/// the real client usable outside an app.
class _InMemoryPkceStorage extends GotrueAsyncStorage {
  final _store = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _store[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    _store[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _store.remove(key);
  }
}

String _env(String key, String fallback) =>
    Platform.environment[key] ?? fallback;

/// Standard local-stack credentials; overridable for a non-default setup.
final _url = _env('SUPABASE_TEST_URL', 'http://127.0.0.1:54321');
final _key = _env(
  'SUPABASE_TEST_KEY',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
);

void main() {
  final skipReason = Platform.environment['SUPABASE_TEST'] == '1'
      ? null
      : 'set SUPABASE_TEST=1 and run `supabase start` to enable';

  group('SupabaseDbManager against a live stack', skip: skipReason, () {
    late SupabaseDbManager db;
    late String userA;

    // Unique per run so repeated runs against one stack never collide on the
    // lower(username) unique index.
    final suffix = DateTime.now().microsecondsSinceEpoch.toString();
    final username = 'itest_$suffix';

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // The binding installs an HttpOverrides that stubs EVERY request to 400
      // without touching the network — exactly what a hermetic widget test
      // wants, and fatal for an integration test. Clearing it restores the
      // real HttpClient. (The 400 is silent apart from a warning, so without
      // this the failures look like server errors rather than a test harness
      // refusing to make the call.)
      HttpOverrides.global = null;
      await Supabase.initialize(
        url: _url,
        publishableKey: _key,
        // A test VM has no platform channels and no deep links; all three
        // defaults would hang or throw outside a real app.
        authOptions: FlutterAuthClientOptions(
          localStorage: const EmptyLocalStorage(),
          pkceAsyncStorage: _InMemoryPkceStorage(),
          detectSessionInUri: false,
        ),
      );
      db = SupabaseDbManager();
      userA = (await Supabase.instance.client.auth.signInAnonymously()).user!.id;
    });

    tearDownAll(() async {
      await Supabase.instance.client.auth.signOut();
    });

    test('profile: create, read back, enforce username uniqueness', () async {
      expect(await db.userExists(userA), isFalse,
          reason: 'a fresh anonymous user has no profile yet');
      expect(await db.usernameAvailable(username), isTrue);

      await db.createUser(userId: userA, username: username);

      expect(await db.userExists(userA), isTrue);
      final profile = await db.getUser(userA);
      expect(profile?['username'], username);
      expect(profile?['firebase_uid'], isNull,
          reason: 'accounts created in the new app are not migrated');

      // The RPC must agree with the index that actually enforces uniqueness.
      expect(await db.usernameAvailable(username), isFalse);
      expect(await db.usernameAvailable(username.toUpperCase()), isFalse,
          reason: 'index is on lower(username), so the check must be too');
    });

    test('profile: updateUsername stamps updated_at', () async {
      // updated_at is the delta-sync's "the new app owns this name now" flag.
      // If it stays null the importer will overwrite the user's choice.
      expect((await db.getUser(userA))?['updated_at'], isNull);

      await db.updateUsername(userId: userA, username: '${username}_v2');

      final after = await db.getUser(userA);
      expect(after?['username'], '${username}_v2');
      expect(after?['updated_at'], isNotNull);
    });

    test('journal: insert round-trips every field, including wall time',
        () async {
      final createdAt =
          Jiffy.parseFromDateTime(DateTime(2025, 9, 29, 19, 44, 2));
      final id = await db.addJournal(
        userA,
        makeJournal(
          emotions: [emotionList[EmotionType.joyful]!],
          selectedScenes: [SceneItem(path: '/s1.jpg', caption: 'a moment')],
          selectedRefs: [Review(text: 'great', source: 'letterboxd')],
          thoughts: 'made me rethink everything',
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
      expect(id, isNotEmpty);

      final saved =
          (await db.getJournalsCollection(userA)).firstWhere((j) => j.id == id);

      expect(saved.tmdbId, 550);
      expect(saved.movieTitle, 'Fight Club');
      expect(saved.thoughts, 'made me rethink everything');
      expect(saved.emotions.single.id, 'joyful');
      expect(saved.selectedScenes.single.path, '/s1.jpg');
      expect(saved.selectedScenes.single.caption, 'a moment');
      expect(saved.selectedRefs.single.text, 'great');
      expect(saved.selectedRefs.single.source, 'letterboxd');

      // The whole point of the timestamp boundary: a local wall time written
      // to timestamptz must return as the SAME wall time. Drop the conversion
      // on either side and this is off by the UTC offset.
      expect(
        saved.createdAt.format(pattern: 'yyyy-MM-dd HH:mm:ss'),
        '2025-09-29 19:44:02',
        reason: 'wall time must survive the UTC round trip',
      );
    });

    test('journal: update persists and preserves created_at', () async {
      final id = await db.addJournal(userA, makeJournal(movieTitle: 'Se7en'));
      final original =
          (await db.getJournalsCollection(userA)).firstWhere((j) => j.id == id);

      await db.updateJournal(
        id,
        original.copyWith(thoughts: 'edited', updatedAt: Jiffy.now()),
      );

      final updated =
          (await db.getJournalsCollection(userA)).firstWhere((j) => j.id == id);
      expect(updated.thoughts, 'edited');
      expect(
        updated.createdAt.format(pattern: 'yyyy-MM-dd HH:mm:ss'),
        original.createdAt.format(pattern: 'yyyy-MM-dd HH:mm:ss'),
        reason: 'update must not reset created_at',
      );
    });

    test('journal: bulk insert returns one id per journal', () async {
      // The pre-signup SharedPreferences upload path.
      final ids = await db.addJournalsToCollection(userA, [
        makeJournal(movieTitle: 'Alien'),
        makeJournal(movieTitle: 'Arrival'),
      ]);
      expect(ids, hasLength(2));

      final titles =
          (await db.getJournalsCollection(userA)).map((j) => j.movieTitle);
      expect(titles, containsAll(['Alien', 'Arrival']));
    });

    test('journal: delete removes the row', () async {
      final id = await db.addJournal(userA, makeJournal(movieTitle: 'Dune'));
      expect((await db.getJournalsCollection(userA)).map((j) => j.id),
          contains(id));

      await db.deleteJournal(id);

      expect((await db.getJournalsCollection(userA)).map((j) => j.id),
          isNot(contains(id)));
    });

    test('RLS: a second user cannot read, modify, or delete the first\'s data',
        () async {
      final before =
          (await db.getJournalsCollection(userA)).firstWhere((j) => true);
      final victimId = before.id;

      // A SECOND client, so user A's session on the singleton stays live and
      // we can prove afterwards that their data actually survived. Signing out
      // to swap users would make that impossible: an anonymous session cannot
      // be restored once ended.
      final clientB = SupabaseClient(_url, _key);
      addTearDown(clientB.dispose);
      final userB = (await clientB.auth.signInAnonymously()).user!.id;
      expect(userB, isNot(userA));

      // Reads: explicitly asking for A's rows must still return nothing.
      // The manager's .eq() filter is belt-and-braces; RLS is the boundary.
      expect(await clientB.from('journals').select().eq('user_id', userA),
          isEmpty);
      expect(await clientB.from('profiles').select().eq('id', userA), isEmpty);

      // Writes: a denied UPDATE/DELETE affects zero rows rather than raising,
      // so asserting "it threw" would be wrong. Verify the data instead.
      await clientB
          .from('journals')
          .update({'thoughts': 'hijacked'}).eq('id', victimId);
      await clientB.from('journals').delete().eq('id', victimId);

      final after =
          (await db.getJournalsCollection(userA)).where((j) => j.id == victimId);
      expect(after, hasLength(1), reason: 'B must not be able to delete A\'s row');
      expect(after.single.thoughts, before.thoughts,
          reason: 'B must not be able to edit A\'s row');
    });
  });
}
