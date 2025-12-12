import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:movie_journal/features/emotion/emotion.dart';
import 'package:movie_journal/features/journal/widgets/emotions_selector_bottom_sheet.dart';

class EmotionsSelectorButton extends StatelessWidget {
  final List<Emotion> emotions;
  final Function(List<Emotion>)? onSave;
  final bool readonly;

  const EmotionsSelectorButton({
    super.key,
    required this.emotions,
    this.onSave,
    this.readonly = false,
  });

  // Configuration map for button states
  static const Map<String, dynamic> _buttonConfig = {
    'empty': {
      'svgPath': 'assets/images/emotion_face.svg',
      'icon': Icons.arrow_forward,
      'iconOpacity': 0.3,
    },
    'selected': {
      'svgPath': 'assets/images/emotion_face.svg',
      'icon': Icons.edit,
      'iconOpacity': 1.0,
    },
  };

  /// Determines the gradient colors based on the energy mix of selected emotions
  LinearGradient _getEnergyGradientColors(List<Emotion> selectedEmotions) {
    if (selectedEmotions.isEmpty) {
      // Default colors when no emotions are selected
      return LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF545454), Color(0xFF545454)],
      );
    }

    final hasHighEnergy = selectedEmotions.any((e) => e.energyLevel == 'high');
    final hasLowEnergy = selectedEmotions.any((e) => e.energyLevel == 'low');

    if (hasHighEnergy && !hasLowEnergy) {
      // All High Energy: Pink/salmon gradient
      return LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFFFADD9E), Color(0xFFFF8784)],
        stops: [0.1, 0.9],
      );
    } else if (!hasHighEnergy && hasLowEnergy) {
      // All Low Energy: Teal/cyan gradient
      return LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF87C997), Color(0xFF9ADCFF)],
        stops: [0.1, 0.9],
      );
    } else {
      // Mixed Energy: Yellow/green gradient
      return LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0xFFFF8784),
          Color(0xFFFADD9E),
          Color(0xFFE1E9B1),
          Color(0xFFA4E5B4),
          Color(0xFF9ADCFF),
        ],
        stops: [0.15, 0.35, 0.5, 0.7, 0.9],
      );
    }
  }

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
  Widget build(BuildContext context) {
    final hasSelection = emotions.isNotEmpty;

    // Get config based on state
    final config =
        hasSelection ? _buttonConfig['selected']! : _buttonConfig['empty']!;
    final color = Theme.of(context).colorScheme.primary;
    final buttonText = _getButtonText(emotions);
    final gradientColors = _getEnergyGradientColors(emotions);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            readonly
                ? null
                : () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder:
                        (context) => EmotionsSelectorBottomSheet(
                          initialEmotions: emotions,
                          onSave: onSave,
                        ),
                  );
                },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Color(0xFF151515),
            border: Border.all(
              color: readonly ? Colors.transparent : color,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Emotion icon with gradient background
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: gradientColors,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    config['svgPath'] as String,
                    width: 40,
                    height: 40,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Text
              Expanded(child: buttonText),
              if (!readonly) ...[
                const SizedBox(width: 12),
                // Icon (arrow or pen)
                Icon(config['icon'] as IconData, color: color, size: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
