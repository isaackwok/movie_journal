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
    final storageVersion = prefs.getString('storageVersion');
    if (journals == null) {
      await prefs.setString(StorageKey.journals.name, '[]');
    }
    if (storageVersion == null) {
      await prefs.setString(StorageKey.storageVersion.name, '1.0');
    }
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
