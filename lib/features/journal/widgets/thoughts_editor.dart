import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/screens/thoughts.dart';
import 'package:movie_journal/features/journal/widgets/questions_bottom_sheet.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';
import 'package:movie_journal/features/quesgen/provider.dart';

class SelectedQuestionItem extends StatelessWidget {
  const SelectedQuestionItem({
    super.key,
    required this.question,
    required this.onRemove,
  });

  final String question;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withAlpha(24),
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
          IconButton(
            onPressed: onRemove,
            icon: Icon(size: 24, Icons.close, color: Color(0xFFA8DADD)),
          ),
        ],
      ),
    );
  }
}

class ThoughtsEditor extends ConsumerWidget {
  const ThoughtsEditor({super.key});

  void _onGenerateButtonPressed(BuildContext context, WidgetRef ref) {
    final movie = ref.read(movieDetailControllerProvider).movie;
    final quesgenState = ref.read(quesgenControllerProvider);
    if (movie != null && quesgenState.questions.isEmpty) {
      ref
          .read(quesgenControllerProvider.notifier)
          .generateQuestions(movieId: movie.id);
    }
    if (context.mounted) {
      showModalBottomSheet(
        showDragHandle: true,
        isScrollControlled: true,
        context: context,
        backgroundColor: Color(0xFF171717),
        builder: (context) => Wrap(children: [QuestionsBottomSheet()]),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(journalControllerProvider);
    final selectedQuestions = journal.selectedQuestions;
    return InkWell(
      splashColor: Colors.transparent,
      onTap:
          () => {
            // TODO: open a new screen to enter thoughts
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ThoughtsScreen()),
            ),
          },
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Write down your thoughts and feelings.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'AvenirNext',
            ),
          ),

          // Container(
          //   alignment: Alignment.centerLeft,
          //   child: ElevatedButton.icon(
          //     icon: Icon(Icons.lightbulb_outline, color: Colors.white),
          //     label: Text(
          //       'Select Questions',
          //       style: TextStyle(color: Colors.white, fontFamily: 'AvenirNext'),
          //     ),
          //     style: ElevatedButton.styleFrom(
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(16),
          //       ),
          //       padding: const EdgeInsets.symmetric(
          //         horizontal: 16,
          //         vertical: 12,
          //       ),
          //       textStyle: const TextStyle(
          //         fontSize: 14,
          //         fontWeight: FontWeight.w500,
          //         color: Colors.white,
          //       ),
          //       overlayColor: Color(0xFFA8DADD),
          //       backgroundColor: Colors.transparent,
          //       side: BorderSide(color: Color(0xFFA8DADD), width: 1),
          //     ),
          //     onPressed: () => _onGenerateButtonPressed(context, ref),
          //   ),
          // ),
          if (selectedQuestions.isNotEmpty) ...[
            ...selectedQuestions.map(
              (question) => SelectedQuestionItem(
                question: question,
                onRemove: () {
                  ref
                      .read(journalControllerProvider.notifier)
                      .removeSelectedQuestion(question);
                },
              ),
            ),
          ],
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              journal.thoughts.isNotEmpty
                  ? journal.thoughts
                  : 'Enter your text here...',
              style:
                  journal.thoughts.isNotEmpty
                      ? GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      )
                      : GoogleFonts.nothingYouCouldDo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withAlpha(128),
                      ),
            ),
          ),
          SizedBox(height: 200),
        ],
      ),
    );
  }
}
