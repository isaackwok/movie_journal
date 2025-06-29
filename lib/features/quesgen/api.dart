import 'package:movie_journal/core/network/quesgen_dio_client.dart';

///  name: string;
///  year: string;
///  overview?: string;
///  genres?: string[];
///  runtime?: number;
///  voteAverage?: number;
///  productionCompanies?: string[];
///  numOfQuestions?: number;
///  language?: string;
///  searchPrompt?: string;
///  questionPrompt?: string;
class QuesgenAPI {
  Future<List<String>> generateQuestions({
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
    final response = await quesgenDioClient.post(
      '/generate',
      data: {
        'name': name,
        'year': year,
        'overview': overview,
        'genres': genres,
        'runtime': runtime,
        'voteAverage': voteAverage,
        'productionCompanies': productionCompanies,
        'numOfQuestions': numOfQuestions,
        'language': language,
        'searchPrompt': searchPrompt,
        'questionPrompt': questionPrompt,
      },
    );
    return response.data['questions'].cast<String>();
  }
}
