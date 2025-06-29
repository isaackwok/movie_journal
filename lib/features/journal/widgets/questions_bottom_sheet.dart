import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
            child: Icon(
              size: 16,
              isSelected ? Icons.check_circle : Icons.add,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class QuestionsBottomSheet extends StatelessWidget {
  const QuestionsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
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
              QuestionItem(
                question:
                    'What did you think about the relationship between the parents and A-Ho?',
                isSelected: false,
                onSelect: () {},
              ),
              QuestionItem(
                question:
                    'What did you think about the relationship between the parents and A-Ho?',
                isSelected: false,
                onSelect: () {},
              ),
              QuestionItem(
                question:
                    'What did you think about the relationship between the parents and A-Ho?',
                isSelected: false,
                onSelect: () {},
              ),
            ],
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.swap_horiz),
            onPressed: () {},
            style: ElevatedButton.styleFrom(
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
