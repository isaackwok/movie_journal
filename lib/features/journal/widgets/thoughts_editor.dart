import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/screens/thoughts.dart';
import 'package:movie_journal/features/journal/widgets/ai_references_accordion.dart';

class ThoughtsEditor extends ConsumerWidget {
  const ThoughtsEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(journalControllerProvider);
    final selectedRefs = journal.selectedRefs;
    return InkWell(
      splashColor: Colors.transparent,
      onTap:
          () => {
            showModalBottomSheet(
              useSafeArea: true,
              enableDrag: false,
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => ThoughtsScreen(),
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
          selectedRefs.isNotEmpty
              ? AiReferencesAccordion(
                defaultExpanded: true,
                references: selectedRefs,
              )
              : SizedBox.shrink(),
          SizedBox(height: 200),
        ],
      ),
    );
  }
}
