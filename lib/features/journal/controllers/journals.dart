import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/analytics_manager.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/supabase_db_manager.dart';
import 'package:movie_journal/supabase_manager.dart';

class JournalsState {
  final List<JournalState> journals;

  JournalsState({this.journals = const []});

  JournalsState copyWith({List<JournalState>? journals}) {
    return JournalsState(journals: journals ?? this.journals);
  }
}

// AsyncNotifier for loading journals from Supabase
class JournalsController extends AsyncNotifier<JournalsState> {
  final SupabaseDbManager _dbManager = SupabaseDbManager();

  @override
  Future<JournalsState> build() async {
    final user = SupabaseManager().currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final journals = await _dbManager.getJournalsCollection(user.id);
    return JournalsState(journals: journals);
  }

  Future<void> addJournal(JournalState journal) async {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedJournals = [...currentState.journals, journal];
    state = AsyncValue.data(currentState.copyWith(journals: updatedJournals));
  }

  /// Remove a journal from both Supabase and local state.
  ///
  /// Deletes the row in Supabase first; if that fails, the local state is
  /// left unchanged so the UI stays consistent with the database.
  Future<void> removeJournal(String id) async {
    final currentState = state.value;
    if (currentState == null) return;

    await _dbManager.deleteJournal(id);
    AnalyticsManager.logJournalDeleted(journalId: id);

    // Update local state after successful Supabase deletion
    final updatedJournals =
        currentState.journals.where((j) => j.id != id).toList();
    state = AsyncValue.data(currentState.copyWith(journals: updatedJournals));
  }

  Future<void> setJournals(List<JournalState> journals) async {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(journals: journals));
  }

  Future<void> refreshJournals() async {
    // Keep the current data while loading to prevent UI flicker
    state = await AsyncValue.guard(() async {
      final user = SupabaseManager().currentUser;
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
