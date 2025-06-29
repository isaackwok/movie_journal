import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/journal/widgets/questions_bottom_sheet.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';
import 'package:movie_journal/features/quesgen/provider.dart';

class ThoughtsEditor extends ConsumerWidget {
  ThoughtsEditor({super.key});

  final TextEditingController _controller = TextEditingController();

  void _onButtonPressed(BuildContext context, WidgetRef ref) {
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
        builder: (context) => Wrap(children: [QuestionsBottomSheet()]),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onPressed: () => _onButtonPressed(context, ref),
          ),
        ),
        TextField(
          controller: _controller,
          maxLines: 10,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            hintText: 'Enter your text here...',
            hintStyle: GoogleFonts.nothingYouCouldDo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
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
