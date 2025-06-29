import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';
import 'package:movie_journal/features/quesgen/provider.dart';

class QuestionItem extends StatelessWidget {
  const QuestionItem({
    super.key,
    required this.question,
    required this.isSelected,
    required this.onSelect,
  });

  final String question;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(76), width: 1),
      ),
      child: Row(
        spacing: 8,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              question,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ),
          InkWell(
            onTap: onSelect,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFFA8DADD) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                size: 16,
                isSelected ? Icons.check : Icons.add,
                color: isSelected ? Colors.black : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuestionsBottomSheet extends ConsumerWidget {
  const QuestionsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quesgenState = ref.watch(quesgenControllerProvider);
    final questions = quesgenState.questions;
    final isLoading = quesgenState.isLoading;
    final journal = ref.watch(journalControllerProvider);
    final selectedQuestions = journal.selectedQuestions;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0XFF171717),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Questions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              fontFamily: 'AvenirNext',
            ),
          ),
          Text(
            'Select one or more questions to answer',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'AvenirNext',
              color: Colors.white.withAlpha(153),
            ),
          ),
          SizedBox(height: 16),

          Column(
            spacing: 12,
            children: [
              ...isLoading
                  ? [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFA8DADD),
                        ),
                      ),
                    ),
                  ]
                  : questions.isNotEmpty
                  ? questions.map(
                    (question) => QuestionItem(
                      question: question,
                      isSelected: selectedQuestions.contains(question),
                      onSelect: () {
                        if (selectedQuestions.contains(question)) {
                          ref
                              .read(journalControllerProvider.notifier)
                              .removeSelectedQuestion(question);
                        } else {
                          ref
                              .read(journalControllerProvider.notifier)
                              .addSelectedQuestion(question);
                        }
                      },
                    ),
                  )
                  : [
                    Text(
                      'No questions generated',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
            ],
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.swap_horiz),
            onPressed:
                isLoading
                    ? null
                    : () {
                      final movie =
                          ref.read(movieDetailControllerProvider).movie;
                      if (movie != null) {
                        ref
                            .read(quesgenControllerProvider.notifier)
                            .generateQuestions(
                              name: movie.title,
                              year: movie.year,
                              overview: movie.overview,
                              genres: movie.genres.map((e) => e.name).toList(),
                              runtime: movie.runtime,
                            );
                      }
                    },
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: Colors.transparent,
              iconSize: 20,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              foregroundColor: Colors.white,
              iconColor: Colors.white,
              overlayColor: Colors.white,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              textStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontFamily: 'AvenirNext',
              ),
            ),
            label: Text('Regenerate'),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
