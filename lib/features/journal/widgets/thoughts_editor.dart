import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/journal/widgets/questions_bottom_sheet.dart';

class ThoughtsEditor extends StatefulWidget {
  const ThoughtsEditor({super.key});

  @override
  State<ThoughtsEditor> createState() => _ThoughtsEditorState();
}

class _ThoughtsEditorState extends State<ThoughtsEditor> {
  List<String> generatedQuestions = [];
  List<String> selectedQuestions = [];

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
            onPressed: () {
              showModalBottomSheet(
                showDragHandle: true,
                isScrollControlled: true,
                context: context,
                builder: (context) => Wrap(children: [QuestionsBottomSheet()]),
              );
            },
          ),
        ),
        TextField(
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
