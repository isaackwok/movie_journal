import 'dart:convert';

import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Data access for `profiles` and `journals`, replacing `FirestoreManager`
/// method-for-method.
///
/// `JournalState` is deliberately left untouched — `toMap()` / `fromJson()`
/// remain the serialization seam, and all snake_case ↔ camelCase translation
/// happens here. That keeps a schema change from rippling into the widget tree.
///
/// RLS enforces ownership in the database, so every query here is additionally
/// scoped by the caller's own id; the filters are belt-and-braces, not the
/// security boundary.
class SupabaseDbManager {
  SupabaseClient get _db => Supabase.instance.client;

  // ------------------------------------------------------------- timestamps

  /// Postgres returns `timestamptz` as ISO-8601 **with an offset**
  /// (`2025-09-29T11:44:02.131+00:00`). `JournalState.fromJson` feeds that
  /// straight into `Jiffy.parse`, which would then hold a UTC instant and
  /// render 11:44 for a journal the user wrote at 19:44 — an 8-hour display
  /// regression on every screen.
  ///
  /// Converting to local first and emitting a NAIVE string reproduces exactly
  /// what Jiffy saw before the migration, so display code is unaffected. The
  /// database keeps the correct absolute instant; only this boundary is naive.
  static String pgTimestampToLocalNaive(String pg) {
    final local = DateTime.parse(pg).toLocal();
    return local.toIso8601String();
  }

  /// Inverse: a Jiffy (local wall time) becomes an absolute UTC instant.
  ///
  /// Never `jiffy.toString()` — that emits a naive local string with no zone,
  /// which is precisely the bug this migration exists to retire. Postgres would
  /// read it as UTC and silently shift every timestamp by 8 hours.
  static String jiffyToUtcIso(dynamic jiffy) {
    return (jiffy.dateTime as DateTime).toUtc().toIso8601String();
  }

  // ------------------------------------------------------------ translation

  /// Postgres row -> the exact camelCase map `JournalState.fromJson` expects.
  static JournalState rowToJournal(Map<String, dynamic> row) {
    return JournalState.fromJson(
      jsonEncode({
        'id': row['id'],
        'tmdbId': row['tmdb_id'],
        'movieTitle': row['movie_title'] ?? '',
        'moviePoster': row['movie_poster'] ?? '',
        // text[] arrives as List<dynamic>; jsonb columns as decoded JSON.
        // fromJson already handles the legacy string-vs-object shapes for
        // scenes and refs, so they are passed through untouched.
        'emotions': row['emotions'] ?? const [],
        'selectedScenes': row['selected_scenes'] ?? const [],
        'selectedRefs': row['selected_refs'] ?? const [],
        'thoughts': row['thoughts'] ?? '',
        'createdAt': row['created_at'] == null
            ? null
            : pgTimestampToLocalNaive(row['created_at'] as String),
        'updatedAt': row['updated_at'] == null
            ? null
            : pgTimestampToLocalNaive(row['updated_at'] as String),
      }),
    );
  }

  /// JournalState -> snake_case column map. Timestamps are absolute UTC.
  ///
  /// `firestore_id` is intentionally never written: rows created in the new app
  /// must keep it NULL so the delta-sync leaves them alone (it only manages
  /// rows that came from Firestore).
  static Map<String, dynamic> journalToRow(
    JournalState journal, {
    required String userId,
    bool includeCreatedAt = true,
  }) {
    return {
      'user_id': userId,
      'tmdb_id': journal.tmdbId,
      'movie_title': journal.movieTitle,
      'movie_poster': journal.moviePoster,
      'emotions': journal.emotions.map((e) => e.id).toList(),
      'selected_scenes': journal.selectedScenes.map((s) => s.toMap()).toList(),
      'selected_refs': journal.selectedRefs.map((r) => r.toMap()).toList(),
      'thoughts': journal.thoughts,
      if (includeCreatedAt) 'created_at': jiffyToUtcIso(journal.createdAt),
      'updated_at': jiffyToUtcIso(journal.updatedAt),
    };
  }

  // --------------------------------------------------------------- journals

  Future<List<JournalState>> getJournalsCollection(String userId) async {
    final rows = await _db
        .from('journals')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => rowToJournal(r as Map<String, dynamic>))
        .toList();
  }

  /// Returns the new row's uuid, replacing Firestore's DocumentReference.
  Future<String> addJournal(String userId, JournalState journal) async {
    final row = await _db
        .from('journals')
        .insert(journalToRow(journal, userId: userId))
        .select('id')
        .single();
    return row['id'] as String;
  }

  /// One round trip, unlike the Firestore version's per-document loop. Used by
  /// the pre-signup SharedPreferences upload, where a partial failure would
  /// leave the local cache and the server disagreeing.
  Future<List<String>> addJournalsToCollection(
    String userId,
    List<JournalState> journals,
  ) async {
    if (journals.isEmpty) return [];
    final rows = await _db
        .from('journals')
        .insert(journals.map((j) => journalToRow(j, userId: userId)).toList())
        .select('id');
    return (rows as List).map((r) => r['id'] as String).toList();
  }

  /// Preserves `created_at`, matching the Firestore `.update()` behaviour.
  Future<void> updateJournal(String journalId, JournalState journal) async {
    await _db
        .from('journals')
        .update(journalToRow(
          journal,
          userId: _requireUserId(),
          includeCreatedAt: false,
        ))
        .eq('id', journalId);
  }

  Future<void> deleteJournal(String journalId) async {
    await _db.from('journals').delete().eq('id', journalId);
  }

  // --------------------------------------------------------------- profiles

  /// 23505 is the unique violation on `profiles_username_lower_key`; it is
  /// surfaced as a friendly message because it is a normal outcome of two
  /// people choosing the same name, not an error condition.
  Future<void> createUser({
    required String userId,
    required String username,
  }) async {
    try {
      await _db.from('profiles').insert({'id': userId, 'username': username});
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw Exception('Username is already taken');
      rethrow;
    }
  }

  Future<bool> userExists(String userId) async {
    final row = await _db
        .from('profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();
    return row != null;
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    return await _db
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  /// Sets `updated_at`, which is the delta-sync's signal that the new app owns
  /// this username now — the importer must never overwrite it afterwards.
  Future<void> updateUsername({
    required String userId,
    required String username,
  }) async {
    try {
      await _db.from('profiles').update({
        'username': username,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw Exception('Username is already taken');
      rethrow;
    }
  }

  /// RLS stops clients from scanning `profiles`, so availability goes through a
  /// SECURITY DEFINER RPC that leaks only a boolean.
  Future<bool> usernameAvailable(String username) async {
    final result = await _db.rpc(
      'username_available',
      params: {'p_username': username},
    );
    return result as bool;
  }

  /// Safety net for when email auto-linking did not attach a sign-in to the
  /// pre-created migrated account. A no-op in the normal case.
  Future<Map<String, dynamic>> claimMigratedData() async {
    final result = await _db.rpc('claim_migrated_data');
    return Map<String, dynamic>.from(result as Map);
  }

  String _requireUserId() {
    final id = Supabase.instance.client.auth.currentUser?.id;
    if (id == null) throw StateError('No authenticated user');
    return id;
  }
}
