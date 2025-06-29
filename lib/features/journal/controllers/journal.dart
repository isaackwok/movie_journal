import 'package:flutter_riverpod/flutter_riverpod.dart';

class JournalState {
  String movieTitle = '';
  String moviePoster = '';
  String emotion = '';
  List<String> selectedScenes = [];
  List<String> selectedQuestions = [];
  String thoughts = '';

  JournalState({
    this.movieTitle = '',
    this.moviePoster = '',
    this.emotion = '',
    this.selectedScenes = const [],
    this.selectedQuestions = const [],
    this.thoughts = '',
  });

  JournalState copyWith({
    String? movieTitle,
    String? moviePoster,
    String? emotion,
    List<String>? selectedScenes,
    List<String>? selectedQuestions,
    String? thoughts,
  }) {
    return JournalState(
      movieTitle: movieTitle ?? this.movieTitle,
      moviePoster: moviePoster ?? this.moviePoster,
      emotion: emotion ?? this.emotion,
      selectedScenes: selectedScenes ?? this.selectedScenes,
      selectedQuestions: selectedQuestions ?? this.selectedQuestions,
      thoughts: thoughts ?? this.thoughts,
    );
  }
}

class JournalController extends StateNotifier<JournalState> {
  JournalController() : super(JournalState());

  bool get isReadyToSave => _isReadyToSave();

  bool _isReadyToSave() {
    return state.emotion.isNotEmpty ||
        state.selectedScenes.isNotEmpty ||
        state.thoughts.isNotEmpty;
  }

  void setMovieTitle(String title) {
    state = state.copyWith(movieTitle: title);
  }

  void setMoviePoster(String poster) {
    state = state.copyWith(moviePoster: poster);
  }

  void setEmotion(String emotion) {
    state = state.copyWith(emotion: emotion);
  }

  void setSelectedScenes(List<String> scenes) {
    state = state.copyWith(selectedScenes: scenes);
  }

  void setSelectedQuestions(List<String> questions) {
    state = state.copyWith(selectedQuestions: questions);
  }

  void setThoughts(String thoughts) {
    state = state.copyWith(thoughts: thoughts);
  }

  void addSelectedScene(String scene) {
    state = state.copyWith(selectedScenes: [...state.selectedScenes, scene]);
  }

  void addSelectedQuestion(String question) {
    state = state.copyWith(
      selectedQuestions: [...state.selectedQuestions, question],
    );
  }

  void removeSelectedQuestion(String question) {
    state = state.copyWith(
      selectedQuestions:
          state.selectedQuestions.where((e) => e != question).toList(),
    );
  }

  void addScene(String scene) {
    state = state.copyWith(selectedScenes: [...state.selectedScenes, scene]);
  }

  void removeScene(String scene) {
    state = state.copyWith(
      selectedScenes: state.selectedScenes.where((e) => e != scene).toList(),
    );
  }

  void clear() {
    state = JournalState();
  }
}

final journalControllerProvider =
    StateNotifierProvider<JournalController, JournalState>((ref) {
      return JournalController();
    });
