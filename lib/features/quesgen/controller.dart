import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/quesgen/api.dart';

class QuesgenState {
  final List<String> questions;
  final bool isLoading;
  final bool isError;

  QuesgenState({
    required this.questions,
    required this.isLoading,
    required this.isError,
  });

  QuesgenState copyWith({
    List<String>? questions,
    bool? isLoading,
    bool? isError,
  }) {
    return QuesgenState(
      questions: questions ?? this.questions,
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
    );
  }
}

class QuesgenController extends StateNotifier<QuesgenState> {
  final QuesgenAPI api;

  QuesgenController(this.api)
    : super(QuesgenState(questions: [], isLoading: false, isError: false));

  Future<void> generateQuestions({
    required String name,
    required String year,
    String? overview,
    List<String>? genres,
    int? runtime,
    double? voteAverage,
    List<String>? productionCompanies,
    int? numOfQuestions,
    String? language,
    String? searchPrompt,
    String? questionPrompt,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final newQuestions = await api.generateQuestions(
        name: name,
        year: year,
        overview: overview,
        genres: genres,
        runtime: runtime,
        voteAverage: voteAverage,
        productionCompanies: productionCompanies,
        numOfQuestions: numOfQuestions ?? 3,
        language: language ?? 'Traditional Chinese(Taiwan)',
        searchPrompt: searchPrompt,
        questionPrompt: questionPrompt,
      );
      state = state.copyWith(questions: newQuestions, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, isError: true);
    }
  }

  void clear() {
    state = state.copyWith(questions: [], isLoading: false, isError: false);
  }
}
