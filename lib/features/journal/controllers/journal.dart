import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiffy/jiffy.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class JournalState {
  String id = '';
  int tmdbId = 0;
  String movieTitle = '';
  String moviePoster = '';
  String emotion = '';
  List<String> selectedScenes = [];
  List<String> selectedQuestions = [];
  String thoughts = '';
  late Jiffy createdAt;
  late Jiffy updatedAt;

  JournalState({
    String? id,
    this.tmdbId = 0,
    this.movieTitle = '',
    this.moviePoster = '',
    this.emotion = '',
    this.selectedScenes = const [],
    this.selectedQuestions = const [],
    this.thoughts = '',
    Jiffy? createdAt,
    Jiffy? updatedAt,
  }) {
    this.id = id ?? Uuid().v4();
    this.createdAt = createdAt ?? Jiffy.now();
    this.updatedAt = updatedAt ?? this.createdAt;
  }

  JournalState copyWith({
    int? tmdbId,
    String? movieTitle,
    String? moviePoster,
    String? emotion,
    List<String>? selectedScenes,
    List<String>? selectedQuestions,
    String? thoughts,
    Jiffy? createdAt,
    Jiffy? updatedAt,
  }) {
    return JournalState(
      tmdbId: tmdbId ?? this.tmdbId,
      movieTitle: movieTitle ?? this.movieTitle,
      moviePoster: moviePoster ?? this.moviePoster,
      emotion: emotion ?? this.emotion,
      selectedScenes: selectedScenes ?? this.selectedScenes,
      selectedQuestions: selectedQuestions ?? this.selectedQuestions,
      thoughts: thoughts ?? this.thoughts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String toJson() {
    return jsonEncode({
      'id': id,
      'tmdbId': tmdbId,
      'movieTitle': movieTitle,
      'moviePoster': moviePoster,
      'emotion': emotion,
      'selectedScenes': selectedScenes,
      'selectedQuestions': selectedQuestions,
      'thoughts': thoughts,
      'createdAt': createdAt.toString(),
      'updatedAt': updatedAt.toString(),
    });
  }

  static JournalState fromJson(String json) {
    // Decode a given json string and return a JournalState object
    final map = jsonDecode(json);
    return JournalState(
      id: map['id'] ?? '',
      tmdbId:
          map['tmdbId'] is int
              ? map['tmdbId']
              : int.parse(map['tmdbId'].toString()),
      movieTitle: map['movieTitle'] ?? '',
      moviePoster: map['moviePoster'] ?? '',
      emotion: map['emotion'] ?? '',
      selectedScenes: List<String>.from(map['selectedScenes'] ?? []),
      selectedQuestions: List<String>.from(map['selectedQuestions'] ?? []),
      thoughts: map['thoughts'] ?? '',
      createdAt:
          map['createdAt'] != null ? Jiffy.parse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? Jiffy.parse(map['updatedAt']) : null,
    );
  }
}

class JournalController extends StateNotifier<JournalState> {
  JournalController() : super(JournalState());

  JournalController setMovie(int tmdbId, String title, String poster) {
    state = state.copyWith(
      tmdbId: tmdbId,
      movieTitle: title,
      moviePoster: poster,
    );
    return this;
  }

  JournalController setTmdbId(int tmdbId) {
    state = state.copyWith(tmdbId: tmdbId);
    return this;
  }

  JournalController setMovieTitle(String title) {
    state = state.copyWith(movieTitle: title);
    return this;
  }

  JournalController setMoviePoster(String poster) {
    state = state.copyWith(moviePoster: poster);
    return this;
  }

  JournalController setEmotion(String emotion) {
    state = state.copyWith(emotion: emotion);
    return this;
  }

  JournalController setSelectedScenes(List<String> scenes) {
    state = state.copyWith(selectedScenes: scenes);
    return this;
  }

  JournalController setSelectedQuestions(List<String> questions) {
    state = state.copyWith(selectedQuestions: questions);
    return this;
  }

  JournalController setThoughts(String thoughts) {
    state = state.copyWith(thoughts: thoughts);
    return this;
  }

  JournalController addSelectedScene(String scene) {
    state = state.copyWith(selectedScenes: [...state.selectedScenes, scene]);
    return this;
  }

  JournalController addSelectedQuestion(String question) {
    state = state.copyWith(
      selectedQuestions: [...state.selectedQuestions, question],
    );
    return this;
  }

  JournalController removeSelectedQuestion(String question) {
    state = state.copyWith(
      selectedQuestions:
          state.selectedQuestions.where((e) => e != question).toList(),
    );
    return this;
  }

  JournalController addScene(String scene) {
    state = state.copyWith(selectedScenes: [...state.selectedScenes, scene]);
    return this;
  }

  JournalController removeScene(String scene) {
    state = state.copyWith(
      selectedScenes: state.selectedScenes.where((e) => e != scene).toList(),
    );
    return this;
  }

  JournalController clear() {
    state = JournalState();
    return this;
  }

  Future<JournalController> save(WidgetRef ref) async {
    final json = state.toJson();
    final journal = JournalState.fromJson(json);
    final journalsController = ref.read(journalsControllerProvider.notifier);
    journalsController.addJournal(journal);
    return this;
  }
}

final journalControllerProvider =
    StateNotifierProvider<JournalController, JournalState>((ref) {
      return JournalController();
    });
