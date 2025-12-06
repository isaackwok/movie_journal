import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/widgets/emotions_selector_bottom_sheet.dart';

class EmotionsSelectorButton extends ConsumerWidget {
  const EmotionsSelectorButton({super.key});

  // Configuration map for button states
  static const Map<String, dynamic> _buttonConfig = {
    'empty': {
      'svgPath': 'assets/images/emotion_empty.svg',
      'icon': Icons.arrow_forward,
      'iconOpacity': 0.3,
    },
    'selected': {
      'svgPath': 'assets/images/emotion_selected.svg',
      'icon': Icons.edit,
      'iconOpacity': 1.0,
    },
  };

  Widget _getButtonText(List selectedEmotions) {
    if (selectedEmotions.isEmpty) {
      return Text(
        'What are your feelings about this movie?',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'AvenirNext',
        ),
      );
    }

    final emotionNames =
        selectedEmotions.map((e) => e.name.toLowerCase()).toList();

    if (emotionNames.length == 1) {
      return Text.rich(
        TextSpan(
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'AvenirNext',
          ),
          children: [
            TextSpan(text: 'You felt '),
            TextSpan(
              text: emotionNames[0],
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ' by this movie.'),
          ],
        ),
      );
    } else if (emotionNames.length == 2) {
      return Text.rich(
        TextSpan(
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'AvenirNext',
          ),
          children: [
            TextSpan(text: 'You felt '),
            TextSpan(
              text: emotionNames[0],
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ' and '),
            TextSpan(
              text: emotionNames[1],
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ' by this movie.'),
          ],
        ),
      );
    } else {
      // 3 emotions
      return Text.rich(
        TextSpan(
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'AvenirNext',
          ),
          children: [
            TextSpan(text: 'You felt '),
            TextSpan(
              text: emotionNames[0],
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ', '),
            TextSpan(
              text: emotionNames[1],
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ' and '),
            TextSpan(
              text: emotionNames[2],
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ' by this movie.'),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(journalControllerProvider);
    final selectedEmotions = journal.emotions;
    final hasSelection = selectedEmotions.isNotEmpty;

    // Get config based on state
    final config =
        hasSelection ? _buttonConfig['selected']! : _buttonConfig['empty']!;
    final color = Color(0xFFA8DADD);
    final buttonText = _getButtonText(selectedEmotions);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => EmotionsSelectorBottomSheet(),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Emotion icon
              SvgPicture.asset(
                config['svgPath'] as String,
                width: 40,
                height: 40,
              ),
              const SizedBox(width: 12),
              // Text
              Expanded(child: buttonText),
              const SizedBox(width: 12),
              // Icon (arrow or pen)
              Icon(config['icon'] as IconData, color: color, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
