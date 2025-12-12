import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/screens/thoughts.dart';
import 'package:movie_journal/features/journal/widgets/ai_references_accordion.dart';

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
            icon: Icon(size: 24, Icons.close,
                color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

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
              fontWeight: FontWeight.w600,
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
                onRemove: (index) {
                  ref
                      .read(journalControllerProvider.notifier)
                      .removeSelectedQuestion(selectedRefs[index]);
                },
              )
              : SizedBox.shrink(),
          SizedBox(height: 200),
        ],
      ),
    );
  }
}
