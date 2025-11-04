import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/shared_preferences_manager.dart';

class JournalsState {
  final List<JournalState> journals;

  JournalsState({this.journals = const []});

  JournalsState copyWith({List<JournalState>? journals}) {
    return JournalsState(journals: journals ?? this.journals);
  }
}

class JournalsController extends Notifier<JournalsState> {
  @override
  JournalsState build() {
    // Initialize the state and load data asynchronously
    Future.microtask(() => _loadJournals());
    return JournalsState();
  }

  Future<void> _loadJournals() async {
    try {
      final journals = SharedPreferencesManager.getJournals();
      state = state.copyWith(journals: journals);
    } catch (e) {
      state = state.copyWith(journals: []);
    }
  }

  Future<void> addJournal(JournalState journal) async {
    final updatedJournals = [...state.journals, journal];
    state = state.copyWith(journals: updatedJournals);
    await _saveJournals(updatedJournals);
  }

  Future<void> removeJournal(String id) async {
    final updatedJournals = state.journals.where((j) => j.id != id).toList();
    state = state.copyWith(journals: updatedJournals);
    await _saveJournals(updatedJournals);
  }

  Future<void> setJournals(List<JournalState> journals) async {
    state = state.copyWith(journals: journals);
    await _saveJournals(journals);
  }

  Future<void> _saveJournals(List<JournalState> journals) async {
    try {
      await SharedPreferencesManager.saveJournals(journals);
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<void> refreshJournals() async {
    await _loadJournals();
  }
}

final journalsControllerProvider =
    NotifierProvider<JournalsController, JournalsState>(JournalsController.new);
