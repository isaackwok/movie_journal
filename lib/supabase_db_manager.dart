import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Postgres wrapper. Mirrors the method shapes of the former
/// FirestoreManager so call sites only change the type name. Creation methods
/// return the new row's `id` as a `String` instead of a `DocumentReference`.
class SupabaseDbManager {
  SupabaseClient get _client => Supabase.instance.client;

  // -------- Journals --------

  Future<List<JournalState>> getJournalsCollection(String userId) async {
    final rows = await _client
        .from('journals')
        .select()
        .eq('user_id', userId);

    return rows
        .map<JournalState>(
          (row) => JournalState.fromJson(
            jsonEncode(rowToJournalJson(row)),
          ),
        )
        .toList();
  }

  /// Bulk insert. Returns the new row ids in insert order.
  Future<List<String>> addJournalsToCollection(
    String userId,
    List<JournalState> journals,
  ) async {
    if (journals.isEmpty) return const [];

    final payload = journals
        .map((j) => {...journalToRow(j), 'user_id': userId})
        .toList();

    final rows = await _client
        .from('journals')
        .insert(payload)
        .select('id');

    return rows.map<String>((row) => row['id'] as String).toList();
  }

  /// Insert a single journal. Returns the new row's id.
  Future<String> addJournal(String userId, JournalState journal) async {
    final payload = {...journalToRow(journal), 'user_id': userId};
    final row = await _client
        .from('journals')
        .insert(payload)
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> updateJournal(String journalId, JournalState journal) async {
    await _client
        .from('journals')
        .update(journalToRow(journal))
        .eq('id', journalId);
  }

  Future<void> deleteJournal(String journalId) async {
    await _client.from('journals').delete().eq('id', journalId);
  }

  // -------- Users --------

  Future<void> createUser({
    required String userId,
    required String username,
  }) async {
    await _client.from('users').insert({
      'id': userId,
      'username': username,
    });
  }

  Future<bool> userExists(String userId) async {
    final row = await _client
        .from('users')
        .select('id')
        .eq('id', userId)
        .maybeSingle();
    return row != null;
  }

  /// Returns the user row, shaped to match the old Firestore payload
  /// (`{userId, username, ...}`), or null if no row exists.
  Future<Map<String, dynamic>?> getUser(String userId) async {
    final row = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return {
      'userId': row['id'],
      'username': row['username'],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    };
  }

  /// True if any row in `public.users` has this username. Used by the
  /// CreateUser uniqueness check.
  Future<bool> usernameExists(String username) async {
    final row = await _client
        .from('users')
        .select('id')
        .eq('username', username)
        .maybeSingle();
    return row != null;
  }

  Future<void> updateUsername({
    required String userId,
    required String username,
  }) async {
    await _client
        .from('users')
        .update({
          'username': username,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId);
  }

  /// Cascading delete: removes all journals for the user, then the user row.
  /// Returns the list of journal ids that were removed, so the caller can log
  /// per-journal analytics events.
  Future<List<String>> deleteUser(String userId) async {
    final journals = await _client
        .from('journals')
        .select('id')
        .eq('user_id', userId);
    final deletedIds =
        journals.map<String>((row) => row['id'] as String).toList();

    await _client.from('journals').delete().eq('user_id', userId);
    await _client.from('users').delete().eq('id', userId);
    return deletedIds;
  }

  // -------- Row <-> JournalState adapters --------

  /// Converts a JournalState to a Postgres row. Uses snake_case column names
  /// and leaves `JournalState.toMap()` as the single source of truth for
  /// field values — we only re-key here.
  @visibleForTesting
  Map<String, dynamic> journalToRow(JournalState journal) {
    final m = journal.toMap();
    return {
      'tmdb_id': m['tmdbId'],
      'movie_title': m['movieTitle'],
      'movie_poster': m['moviePoster'],
      'emotions': m['emotions'],
      'selected_scenes': m['selectedScenes'],
      'selected_refs': m['selectedRefs'],
      'thoughts': m['thoughts'],
      'created_at': m['createdAt'],
      'updated_at': m['updatedAt'],
    };
  }

  /// Inverse: turns a Postgres row into the JSON shape that
  /// `JournalState.fromJson` expects. Drops `user_id`.
  @visibleForTesting
  Map<String, dynamic> rowToJournalJson(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'tmdbId': row['tmdb_id'],
      'movieTitle': row['movie_title'],
      'moviePoster': row['movie_poster'] ?? '',
      'emotions': row['emotions'] ?? const [],
      'selectedScenes': row['selected_scenes'] ?? const [],
      'selectedRefs': row['selected_refs'] ?? const [],
      'thoughts': row['thoughts'] ?? '',
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    };
  }
}
