import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/emotion/emotion.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';

class EmotionsSelectorBottomSheet extends ConsumerStatefulWidget {
  final int maxSelectionLimit = 3;

  const EmotionsSelectorBottomSheet({super.key});

  @override
  ConsumerState<EmotionsSelectorBottomSheet> createState() =>
      _EmotionsSelectorBottomSheetState();
}

class _EmotionsSelectorBottomSheetState
    extends ConsumerState<EmotionsSelectorBottomSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PageController _pageController;
  int _currentPageIndex = 0;

  // Temporary state for selected emotions (only saved when Done is clicked)
  late List<Emotion> _tempSelectedEmotions;

  // Two pages with two sections each
  static final List<Map<String, dynamic>> emotionPages = [
    // Page 1: High Energy
    {
      "title": "High Energy",
      "sections": [
        {
          "label": "Uplifting",
          "color": Color(0xFFFADD9E),
          "emotions": [
            EmotionType.joyful,
            EmotionType.funny,
            EmotionType.inspired,
            EmotionType.mindBlown,
            EmotionType.hopeful,
            EmotionType.fulfilling,
          ],
        },
        {
          "label": "Intense",
          "color": Color(0xFFFC8885),
          "emotions": [
            EmotionType.shocked,
            EmotionType.angry,
            EmotionType.terrified,
            EmotionType.anxious,
            EmotionType.overwhelmed,
            EmotionType.disturbed,
          ],
        },
      ],
    },
    // Page 2: Low Energy
    {
      "title": "Low Energy",
      "sections": [
        {
          "label": "Soothing",
          "color": Color(0xFFFADD9E),
          "emotions": [
            EmotionType.heartwarming,
            EmotionType.touched,
            EmotionType.peaceful,
            EmotionType.therapeutic,
            EmotionType.nostalgic,
            EmotionType.cozy,
          ],
        },
        {
          "label": "Quiet",
          "color": Color(0xFFFC8885),
          "emotions": [
            EmotionType.melancholic,
            EmotionType.confused,
            EmotionType.thoughtProvoking,
            EmotionType.bittersweet,
            EmotionType.powerless,
            EmotionType.lonely,
          ],
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    // Initialize temp state with current emotions
    final journal = ref.read(journalControllerProvider);
    _tempSelectedEmotions = List.from(journal.emotions);

    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController();

    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPageIndex) {
        setState(() {
          _currentPageIndex = page;
        });
      }
    });

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handleEmotionTap(Emotion emotion) {
    setState(() {
      if (_tempSelectedEmotions.contains(emotion)) {
        // Deselect
        _tempSelectedEmotions =
            _tempSelectedEmotions.where((e) => e != emotion).toList();
      } else {
        // Select if under limit
        if (_tempSelectedEmotions.length < widget.maxSelectionLimit) {
          _tempSelectedEmotions = [..._tempSelectedEmotions, emotion];
        }
      }
    });
  }

  void _handleDone() {
    // Save the temporary selections to the actual state
    ref
        .read(journalControllerProvider.notifier)
        .setEmotions(_tempSelectedEmotions);
    Navigator.of(context).pop();
  }

  void _handleCancel() {
    // Discard changes and close
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  _handleCancel();
                }
              },
              child: Container(
                margin: EdgeInsets.only(top: 12, bottom: 16),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(153),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What are your feelings about this movie?',
                          style: TextStyle(
                            fontFamily: 'AvenirNext',
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'select up to ${widget.maxSelectionLimit} (${_tempSelectedEmotions.length}/${widget.maxSelectionLimit})',
                          style: TextStyle(
                            fontFamily: 'AvenirNext',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            color: Colors.white.withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _handleCancel,
                    icon: Icon(Icons.close, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Content with horizontal scroll - two pages
            SizedBox(
              height: 450,
              child: PageView.builder(
                controller: _pageController,
                itemCount: 2,
                itemBuilder: (context, pageIndex) {
                  final page = emotionPages[pageIndex];
                  final pageTitle = page["title"] as String;
                  final sectionsRaw = page["sections"];
                  final sections =
                      (sectionsRaw as List).cast<Map<String, dynamic>>();

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withAlpha(77), // 30% opacity
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Page title (e.g., "High Energy")
                          Text(
                            pageTitle,
                            style: TextStyle(
                              fontFamily: 'AvenirNext',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 20),

                          // Sections
                          ...sections.asMap().entries.map((entry) {
                            final index = entry.key;
                            final section = entry.value;
                            final sectionLabel = section["label"] as String;
                            final sectionColor = section["color"] as Color;
                            final emotions =
                                section["emotions"] as List<EmotionType>;
                            final isLastSection = index == sections.length - 1;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sectionLabel,
                                  style: TextStyle(
                                    fontFamily: 'AvenirNext',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: sectionColor,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      emotions.map((emotionType) {
                                        final emotion =
                                            emotionList[emotionType]!;
                                        final isSelected = _tempSelectedEmotions
                                            .contains(emotion);

                                        return GestureDetector(
                                          onTap:
                                              () => _handleEmotionTap(emotion),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isSelected
                                                      ? sectionColor.withAlpha(
                                                        102,
                                                      ) // 40% opacity
                                                      : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: sectionColor.withAlpha(
                                                  179,
                                                ), // 70% opacity
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              emotion.name,
                                              style: TextStyle(
                                                fontFamily: 'AvenirNext',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                                if (!isLastSection) ...[
                                  SizedBox(height: 16),
                                  Divider(
                                    color: Colors.white.withAlpha(
                                      77,
                                    ), // 30% opacity
                                    thickness: 1,
                                  ),
                                  SizedBox(height: 16),
                                ],
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Page indicator
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                2,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _currentPageIndex == index
                            ? Colors.white
                            : Colors.white.withAlpha(77),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Done button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: TextButton(
                  style: TextButton.styleFrom(
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'AvenirNext',
                    ),
                    backgroundColor: Color(0xFFA8DADD),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: _handleDone,
                  child: const Text('Done'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
