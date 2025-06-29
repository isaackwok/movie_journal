import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

class ThoughtsEditor extends ConsumerStatefulWidget {
  const ThoughtsEditor({super.key});

  @override
  ConsumerState<ThoughtsEditor> createState() => _ThoughtsEditorState();
}

class _ThoughtsEditorState extends ConsumerState<ThoughtsEditor> {
  final List<String> selectedQuestions = [];

  void _onButtonPressed(BuildContext context) {
    final movie = ref.read(movieDetailControllerProvider).movie;
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
    if (context.mounted) {
      showModalBottomSheet(
        showDragHandle: true,
        isScrollControlled: true,
        context: context,
        builder:
            (context) => StatefulBuilder(
              builder:
                  (context, setModalState) => Wrap(
                    children: [
                      QuestionsBottomSheet(
                        selectedQuestions: selectedQuestions,
                        onSelectQuestion: (question) {
                          setState(() {
                            if (selectedQuestions.contains(question)) {
                              selectedQuestions.remove(question);
                            } else {
                              selectedQuestions.add(question);
                            }
                          });
                          // Force the modal to rebuild
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Container(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            icon: Icon(Icons.lightbulb_outline, color: Colors.white),
            label: Text(
              'Select Questions',
              style: TextStyle(color: Colors.white, fontFamily: 'AvenirNext'),
            ),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              overlayColor: Color(0xFFA8DADD),
              backgroundColor: Colors.transparent,
              side: BorderSide(color: Color(0xFFA8DADD), width: 1),
            ),
            onPressed: () => _onButtonPressed(context),
          ),
        ),

        if (selectedQuestions.isNotEmpty) ...[
          ...selectedQuestions.map(
            (question) => SelectedQuestionItem(
              question: question,
              onRemove: () {
                setState(() {
                  selectedQuestions.remove(question);
                });
              },
            ),
          ),
        ],
        TextField(
          maxLines: 10,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            hintText: 'Enter your text here...',
            hintStyle: GoogleFonts.nothingYouCouldDo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white.withAlpha(128),
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            fillColor: Colors.transparent,
          ),
        ),
      ],
    );
  }
}
