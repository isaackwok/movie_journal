import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/firestore_manager.dart';

class JournalsState {
  final List<JournalState> journals;

  JournalsState({this.journals = const []});

  JournalsState copyWith({List<JournalState>? journals}) {
    return JournalsState(journals: journals ?? this.journals);
  }
}

// AsyncNotifier for loading journals from Firestore
class JournalsController extends AsyncNotifier<JournalsState> {
  final FirestoreManager _firestoreManager = FirestoreManager();

  @override
  Future<JournalsState> build() async {
    // Get current user from Firebase Auth
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Load journals from Firestore
    final journals = await _firestoreManager.getJournalsCollection(user.uid);
    return JournalsState(journals: journals);
  }

  Future<void> addJournal(JournalState journal) async {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedJournals = [...currentState.journals, journal];
    state = AsyncValue.data(currentState.copyWith(journals: updatedJournals));

    // TODO: Add Firestore write logic here
  }

  /// Remove a journal from both Firestore and local state
  ///
  /// This method first deletes the journal from Firestore, then updates
  /// the local state to reflect the deletion. If Firestore deletion fails,
  /// the local state is not updated.
  Future<void> removeJournal(String id) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Delete from Firestore first
    await _firestoreManager.deleteJournal(id);

    // Update local state after successful Firestore deletion
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      final journals = await _firestoreManager.getJournalsCollection(user.uid);
      return JournalsState(journals: journals);
    });
  }
}

final journalsControllerProvider =
    AsyncNotifierProvider<JournalsController, JournalsState>(
      JournalsController.new,
    );
