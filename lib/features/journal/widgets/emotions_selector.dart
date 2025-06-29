import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';

class EmotionButton extends StatefulWidget {
  final String svgPath;
  final String text;
  final bool isSelected;
  final Function(String) onTap;
  const EmotionButton({
    super.key,
    required this.svgPath,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<EmotionButton> createState() => _EmotionButtonState();
}

class _EmotionButtonState extends State<EmotionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onTap(widget.text);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color:
                        widget.isSelected
                            ? Theme.of(context).primaryColor
                            : Color(0xFFD9D9D9),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(widget.svgPath),
                ),
                Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'AvenirNext',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class EmotionsSelector extends ConsumerStatefulWidget {
  const EmotionsSelector({super.key});
  static const List<String> emotions = [
    'Joyful',
    'Exciting',
    'Funny',
    'Sad',
    'Boring',
    'Furious',
    'Terrified',
    'Confused',
    'Shocked',
  ];

  @override
  ConsumerState<EmotionsSelector> createState() => _EmotionsSelectorState();
}

class _EmotionsSelectorState extends ConsumerState<EmotionsSelector> {
  String? selectedEmotion;

  @override
  Widget build(BuildContext context) {
    final journal = ref.watch(journalControllerProvider);
    final selectedEmotion = journal.emotion;
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What emotions do you feel during this movie?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'AvenirNext',
          ),
        ),
        SizedBox(height: 16),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.0,
          ),
          children:
              EmotionsSelector.emotions
                  .map(
                    (e) => EmotionButton(
                      svgPath: 'assets/images/emotions/$e.svg',
                      text: e,
                      isSelected: selectedEmotion == e,
                      onTap: (e) {
                        ref
                            .read(journalControllerProvider.notifier)
                            .setEmotion(e);
                      },
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}
