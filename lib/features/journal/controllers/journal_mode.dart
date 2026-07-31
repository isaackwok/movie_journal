import 'package:flutter_riverpod/flutter_riverpod.dart';

enum JournalMode { create, edit }

class JournalModeNotifier extends Notifier<JournalMode> {
  @override
  JournalMode build() => JournalMode.create;

  void set(JournalMode mode) {
    state = mode;
  }
}

final journalModeProvider = NotifierProvider<JournalModeNotifier, JournalMode>(
  JournalModeNotifier.new,
);
