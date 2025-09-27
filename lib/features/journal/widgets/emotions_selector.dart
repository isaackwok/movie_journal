import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/emotion/emotion.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';

class EmotionButton extends StatefulWidget {
  final String? text;
  final Emotion emotion;
  final bool isSelected;
  final double? size;
  final Function(String) onTap;
  const EmotionButton({
    super.key,
    this.text,
    required this.isSelected,
    required this.onTap,
    required this.emotion,
    this.size,
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
    widget.onTap(widget.text ?? '');
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
                Stack(
                  children: [
                    Container(
                      width: widget.size ?? 48,
                      height: widget.size ?? 48,
                      decoration: BoxDecoration(
                        // color:
                        //     widget.isSelected
                        //         ? Theme.of(context).primaryColor
                        //         : Color(0xFFD9D9D9),
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: widget.emotion.colors,
                        ),
                        shape: BoxShape.circle,
                        border:
                            widget.isSelected
                                ? Border.all(color: Colors.white, width: 4)
                                : Border.all(
                                  color: Colors.transparent,
                                  width: 4,
                                ),
                      ),
                    ),
                    if (widget.isSelected)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Icon(Icons.check, size: 24, color: Colors.white),
                      ),
                  ],
                ),
                if (widget.text != null)
                  Text(
                    widget.text!,
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

  @override
  ConsumerState<EmotionsSelector> createState() => _EmotionsSelectorState();
}

class _EmotionsSelectorState extends ConsumerState<EmotionsSelector>
    with SingleTickerProviderStateMixin {
  String? selectedEmotion;
  late final TabController _tabController;
  final emotionGroups = {
    "Pleasant":
        emotionList.entries.where((e) => e.value.group == "Pleasant").toList(),
    "Unpleasant":
        emotionList.entries
            .where((e) => e.value.group == "Unpleasant")
            .toList(),
    "Others":
        emotionList.entries.where((e) => e.value.group == "Others").toList(),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journal = ref.watch(journalControllerProvider);
    final selectedEmotions = journal.emotions;
    return Column(
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
        SizedBox(height: 8),
        Text(
          '${selectedEmotions.length} selected',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'AvenirNext',
            fontWeight: FontWeight.w500,
            color: Color(0xFFC5C5C5),
          ),
        ),
        SizedBox(height: 16),
        TabBar(
          indicatorPadding: EdgeInsets.zero,
          labelPadding: EdgeInsets.only(right: 8),
          isScrollable: true,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.label,
          unselectedLabelColor: Colors.white,
          tabAlignment: TabAlignment.start,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'AvenirNext',
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'AvenirNext',
          ),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: Color(0xFF434343),
            border: Border.all(color: Colors.white, width: 1),
          ),
          controller: _tabController,
          tabs: [
            Tab(
              height: 30,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Color(0xFF434343).withAlpha(100),
                ),
                child: SizedBox(
                  height: 30,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Pleasant',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'AvenirNext',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Tab(
              height: 30,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Color(0xFF434343).withAlpha(100),
                ),
                child: SizedBox(
                  height: 30,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Unpleasant',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'AvenirNext',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Tab(
              height: 30,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Color(0xFF434343).withAlpha(100),
                ),
                child: SizedBox(
                  height: 30,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Others',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'AvenirNext',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          // onTap: (index) {
          //   _tabController.animateTo(index);
          // },
        ),
        SizedBox(
          height: 230,
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: TabBarView(
              controller: _tabController,
              children:
                  <Widget>[
                    ...emotionGroups.entries.map(
                      (group) => GridView.builder(
                        padding: EdgeInsets.all(0),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            emotionList.entries
                                .where((e) => e.value.group == group.key)
                                .length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1.0,
                          mainAxisSpacing: 16,
                        ),
                        itemBuilder:
                            (context, index) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 8,
                              children: [
                                EmotionButton(
                                  emotion:
                                      emotionGroups[group.key]![index].value,
                                  isSelected: selectedEmotions.contains(
                                    emotionGroups[group.key]![index].value,
                                  ),
                                  onTap: (e) {
                                    if (selectedEmotions.contains(
                                      emotionGroups[group.key]![index].value,
                                    )) {
                                      ref
                                          .read(
                                            journalControllerProvider.notifier,
                                          )
                                          .setEmotions([
                                            ...selectedEmotions.where(
                                              (e) =>
                                                  e !=
                                                  emotionGroups[group
                                                          .key]![index]
                                                      .value,
                                            ),
                                          ]);
                                    } else {
                                      ref
                                          .read(
                                            journalControllerProvider.notifier,
                                          )
                                          .setEmotions([
                                            ...selectedEmotions,
                                            emotionGroups[group.key]![index]
                                                .value,
                                          ]);
                                    }
                                  },
                                ),
                                Text(
                                  emotionGroups[group.key]![index].value.name,
                                  style: GoogleFonts.nothingYouCouldDo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                      ),
                    ),
                  ].toList(),
            ),
          ),
        ),
      ],
    );
  }
}
