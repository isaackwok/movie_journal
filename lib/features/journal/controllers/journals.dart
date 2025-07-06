import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JournalsState {
  List<JournalState> journals = [];

  JournalsState({List<JournalState>? journals}) {
    SharedPreferences.getInstance().then((prefs) {
      if (journals != null) {
        this.journals = journals;
      } else {
        final journals = prefs.getString('journals') ?? '[]';
        final journalsList = jsonDecode(journals) as List<dynamic>;
        this.journals =
            journalsList.map((j) => JournalState.fromJson(j)).toList();
      }
    });
  }

  JournalsState copyWith({List<JournalState>? journals}) {
    return JournalsState(journals: journals);
  }
}

class JournalsController extends StateNotifier<JournalsState> {
  JournalsController() : super(JournalsState(journals: []));

  JournalsController addJournal(JournalState journal) {
    state = state.copyWith(journals: [...state.journals, journal]);
    saveJournals();
    return this;
  }

  JournalsController removeJournal(String id) {
    state = state.copyWith(
      journals: state.journals.where((j) => j.id != id).toList(),
    );
    saveJournals();
    return this;
  }

  JournalsController setJournals(List<JournalState> journals) {
    state = state.copyWith(journals: journals);
    saveJournals();
    return this;
  }

  Future<JournalsController> saveJournals() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('journals', jsonEncode(state.journals));
    return this;
  }
}

final journalsControllerProvider =
    StateNotifierProvider<JournalsController, JournalsState>((ref) {
      return JournalsController();
    });
