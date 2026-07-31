import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/analytics_manager.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/supabase_auth_manager.dart';
import 'package:movie_journal/supabase_db_manager.dart';

class JournalsState {
  final List<JournalState> journals;

  JournalsState({this.journals = const []});

  JournalsState copyWith({List<JournalState>? journals}) {
    return JournalsState(journals: journals ?? this.journals);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalsState &&
          runtimeType == other.runtimeType &&
          listEquals(journals, other.journals);

  @override
  int get hashCode => Object.hashAll(journals);
}

// AsyncNotifier for loading journals from Supabase
class JournalsController extends AsyncNotifier<JournalsState> {
  final SupabaseDbManager _dbManager = SupabaseDbManager();

  @override
  Future<JournalsState> build() async {
    // Get current user from Supabase Auth
    final user = SupabaseAuthManager.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Load journals from Supabase
    final journals = await _dbManager.getJournalsCollection(user.id);
    return JournalsState(journals: journals);
  }

  /// Remove a journal from both Supabase and local state
  ///
  /// This method first deletes the journal from Supabase, then updates
  /// the local state to reflect the deletion. If the delete fails,
  /// the local state is not updated.
  Future<void> removeJournal(String id) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Delete from Supabase first
    await _dbManager.deleteJournal(id);
    unawaited(AnalyticsManager.logJournalDeleted(journalId: id));

    // Update local state after successful deletion
    final updatedJournals =
        currentState.journals.where((j) => j.id != id).toList();
    state = AsyncValue.data(currentState.copyWith(journals: updatedJournals));
  }

  Future<void> refreshJournals() async {
    // Keep the current data while loading to prevent UI flicker
    state = await AsyncValue.guard(() async {
      final user = SupabaseAuthManager.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      final journals = await _dbManager.getJournalsCollection(user.id);
      return JournalsState(journals: journals);
    });
  }
}

final journalsControllerProvider =
    AsyncNotifierProvider<JournalsController, JournalsState>(
      JournalsController.new,
    );

/// Journals grouped by month ('yyyy-MM'), groups newest-first and entries
/// within each group newest-first. Derived here once per journals change
/// instead of re-grouping and re-sorting on every JournalsList rebuild.
/// Empty while the journals are still loading (or errored).
final groupedJournalsProvider = Provider<
  List<MapEntry<String, List<JournalState>>>
>((ref) {
  final journals =
      ref.watch(journalsControllerProvider.select((s) => s.value?.journals)) ??
      const [];

  final grouped = <String, List<JournalState>>{};
  for (final journal in journals) {
    grouped
        .putIfAbsent(journal.createdAt.format(pattern: 'yyyy-MM'), () => [])
        .add(journal);
  }
  for (final group in grouped.values) {
    group.sort((a, b) => b.createdAt.dateTime.compareTo(a.createdAt.dateTime));
  }
  return grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
});
