import 'dart:convert';

import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StorageKey { journals, storageVersion }

class SharedPreferencesManager {
  static late SharedPreferences prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();

    // Initialize default values if they do not exist
    final journals = prefs.getString(StorageKey.journals.name);

    String migratedJournals = journals ?? '[]';

    // Migrate 'selectedQuestions' to 'selectedRefs' if needed
    // TODO: remove this migration logic once all users have updated
    migratedJournals = migratedJournals.replaceAll(
      'selectedQuestions',
      'selectedRefs',
    );

    await prefs.setString(StorageKey.journals.name, migratedJournals);
  }

  static List<JournalState> getJournals() {
    final journalsJson = prefs.getString(StorageKey.journals.name) ?? '[]';
    final journalsList = jsonDecode(journalsJson) as List<dynamic>;
    final journals =
        journalsList
            .map((journalJson) => JournalState.fromJson(journalJson.toString()))
            .toList();
    return journals;
  }

  static Future<void> saveJournals(List<JournalState> journals) async {
    final journalsJson = jsonEncode(journals.map((j) => j.toJson()).toList());
    await prefs.setString(StorageKey.journals.name, journalsJson);
  }
}
