import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';
import 'package:movie_journal/features/journal/widgets/ai_references_accordion.dart';
import 'package:movie_journal/features/journal/widgets/emotions_selector.dart';
import 'package:movie_journal/features/journal/widgets/scene_card.dart';

class JournalContent extends ConsumerStatefulWidget {
  final String journalId;
  const JournalContent({super.key, required this.journalId});

  @override
  ConsumerState<JournalContent> createState() => _JournalContentState();
}

class _JournalContentState extends ConsumerState<JournalContent> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final journalsAsync = ref.watch(journalsControllerProvider);

    // Handle loading and error states
    if (journalsAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (journalsAsync.hasError) {
      return Scaffold(
        body: Center(child: Text('Error: ${journalsAsync.error}')),
      );
    }

    final journals = journalsAsync.value?.journals ?? [];
    final journal = journals.firstWhere(
      (journal) => journal.id == widget.journalId,
      orElse: () => throw Exception('Journal not found'),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            pinned: true,
            floating: true,
            snap: true,
            automaticallyImplyLeading: false,
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.edit_outlined, color: Colors.white),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.ios_share, color: Colors.white),
              ),
            ],
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16,
              ),
              disabledColor: Colors.white.withAlpha(76),
              style: IconButton.styleFrom(
                shape: CircleBorder(),
                side: BorderSide(color: Color(0xFFA8DADD)),
                alignment: Alignment.center,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      journal.movieTitle,
                      style: GoogleFonts.inter(fontSize: 32),
                    ),
                  ),
                  SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      journal.updatedAt.format(pattern: 'MMM do yyyy'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withAlpha(178),
                        fontFamily: 'AvenirNext',
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      children:
                          journal.emotions
                              .map(
                                (emotion) => Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 8,
                                    children: [
                                      EmotionButton(
                                        size: 40,
                                        emotion: emotion,
                                        isSelected: false,
                                        onTap: (e) {},
                                      ),
                                      Text(
                                        emotion.name,
                                        style: GoogleFonts.nothingYouCouldDo(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  SizedBox(height: 24),
                  journal.selectedScenes.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                        children: [
                          SizedBox(
                            height: 260,
                            child: PageView.builder(
                              controller: _pageController,
                              onPageChanged: _onPageChanged,
                              itemCount: journal.selectedScenes.length,
                              itemBuilder: (context, index) {
                                final scene = journal.selectedScenes[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: SceneCard(
                                    imagePath: scene.path,
                                    caption: scene.caption,
                                    isEditable: false,
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: 24,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Centered dots
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 4,
                                  children: List.generate(
                                    journal.selectedScenes.length,
                                    (index) => Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            index == _currentPage
                                                ? Colors.white
                                                : Colors.white.withAlpha(77),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      journal.thoughts,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child:
                        journal.selectedRefs.isEmpty
                            ? const SizedBox.shrink()
                            : AiReferencesAccordion(
                              references: journal.selectedRefs,
                              onRemove: (index) {},
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
