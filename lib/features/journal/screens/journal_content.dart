import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/analytics_manager.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';
import 'package:movie_journal/features/journal/widgets/ai_references_accordion.dart';
import 'package:movie_journal/features/journal/widgets/emotions_selector_button.dart';
import 'package:movie_journal/features/journal/widgets/journal_content_more_menu.dart';
import 'package:movie_journal/features/journal/widgets/scene_card.dart';
import 'package:movie_journal/features/share/screens/share_ticket_screen.dart';
import 'package:movie_journal/features/share/screens/ticket_poster_picker_screen.dart';
import 'package:movie_journal/shared_widgets/circled_icon_button.dart';

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
    AnalyticsManager.logScreenView('JournalContent');
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

    // Try to find the journal, if not found (deleted), navigate back
    final journalIndex = journals.indexWhere((j) => j.id == widget.journalId);
    if (journalIndex == -1) {
      // Journal was deleted, navigate back after this frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      });
      // Return empty scaffold while waiting for navigation
      return const Scaffold(body: SizedBox.shrink());
    }

    final journal = journals[journalIndex];

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
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TicketPosterPickerScreen(
                        journal: journal,
                        entry: ShareTicketEntry.journalContent,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.ios_share, color: Colors.white),
              ),
              JournalContentMoreMenu(journalId: widget.journalId),
            ],
            leading: CircledIconButton(
              icon: Icons.arrow_back_ios_new,
              onPressed: () => Navigator.pop(context),
              outerPadding: const EdgeInsets.only(left: 16),
            ),
            leadingWidth: 40 + 16,
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

                  if (journal.emotions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: EmotionsSelectorButton(
                        emotions: journal.emotions,
                        readonly: true,
                      ),
                    ),
                  if (journal.emotions.isNotEmpty) SizedBox(height: 24),
                  journal.selectedScenes.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                        children: [
                          SizedBox(
                            height: 235,
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
