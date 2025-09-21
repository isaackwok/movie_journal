import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JournalsState {
  final List<JournalState> journals;

  JournalsState({this.journals = const []});

  JournalsState copyWith({List<JournalState>? journals}) {
    return JournalsState(journals: journals ?? this.journals);
  }
}

class JournalsController extends StateNotifier<JournalsState> {
  JournalsController() : super(JournalsState()) {
    _loadJournals();
  }

  Future<void> _loadJournals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final journalsJson = prefs.getString('journals') ?? '[]';
      // print('Loading journals from SharedPreferences: $journalsJson');

      final journalsList = jsonDecode(journalsJson) as List<dynamic>;
      // print('Decoded journals list length: ${journalsList.length}');

      final journals =
          journalsList
              .map(
                (journalJson) => JournalState.fromJson(journalJson.toString()),
              )
              .toList();

      print('Loaded ${journals.length} journals');
      state = state.copyWith(journals: journals);
    } catch (e) {
      // print('Error loading journals: $e');
      state = state.copyWith(journals: []);
    }
  }

  Future<void> addJournal(JournalState journal) async {
    print('Adding journal: ${journal.movieTitle} (ID: ${journal.id})');
    final updatedJournals = [...state.journals, journal];
    state = state.copyWith(journals: updatedJournals);
    await _saveJournals(updatedJournals);
    print(
      'Journal added successfully. Total journals: ${state.journals.length}',
    );
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
      final prefs = await SharedPreferences.getInstance();
      final journalsJsonList =
          journals.map((journal) => journal.toJson()).toList();
      final jsonString = jsonEncode(journalsJsonList);
      print('Saving journals to SharedPreferences: $jsonString');
      await prefs.setString('journals', jsonString);
      print('Successfully saved ${journals.length} journals');
    } catch (e) {
      print('Error saving journals: $e');
    }
  }

  Future<void> refreshJournals() async {
    await _loadJournals();
  }
}

final journalsControllerProvider =
    StateNotifierProvider<JournalsController, JournalsState>((ref) {
      return JournalsController();
    });
