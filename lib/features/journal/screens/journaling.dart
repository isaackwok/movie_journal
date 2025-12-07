import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jiffy/jiffy.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/screens/journal_content.dart';
import 'package:movie_journal/features/journal/widgets/emotions_selector_button.dart';
import 'package:movie_journal/features/journal/widgets/scenes_selector.dart';
import 'package:movie_journal/features/journal/widgets/thoughts_editor.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';
import 'package:movie_journal/features/quesgen/provider.dart';
import 'package:movie_journal/features/toast/custom_toast.dart';

class SectionSeperator extends StatelessWidget {
  const SectionSeperator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Container(height: 0.1, color: Colors.white.withAlpha(76)),
    );
  }
}

class JournalingScreen extends ConsumerStatefulWidget {
  final String movieTitle;
  final String moviePosterUrl;
  const JournalingScreen({
    super.key,
    required this.movieTitle,
    required this.moviePosterUrl,
  });

  @override
  ConsumerState<JournalingScreen> createState() => _JournalingScreenState();
}

class _JournalingScreenState extends ConsumerState<JournalingScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    CustomToast.init(context);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Show title when scrolled down more than 100 pixels
    final showTitle =
        _scrollController.hasClients && _scrollController.offset > 100;
    if (showTitle != _showTitle) {
      setState(() {
        _showTitle = showTitle;
      });
    }
  }

  bool _hasUnsavedChanges() {
    final journal = ref.read(journalControllerProvider);
    return journal.emotions.isNotEmpty ||
        journal.selectedScenes.isNotEmpty ||
        journal.thoughts.isNotEmpty;
  }

  void _handleBackButton() async {
    if (!_hasUnsavedChanges()) {
      Navigator.pop(context);
      ref.read(journalControllerProvider.notifier).clear();
      ref.read(quesgenControllerProvider.notifier).clear();
      return;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => const _DiscardChangesDialog(),
    );

    if (shouldDiscard == true && mounted) {
      Navigator.pop(context);
      ref.read(journalControllerProvider.notifier).clear();
      ref.read(quesgenControllerProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final movieAsync = ref.watch(movieDetailControllerProvider);
    final movieId = movieAsync.hasValue ? movieAsync.value!.id : 0;
    final journal = ref.watch(journalControllerProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final navigator = Navigator.of(context);
        final journalNotifier = ref.read(journalControllerProvider.notifier);
        final quesgenNotifier = ref.read(quesgenControllerProvider.notifier);

        if (!_hasUnsavedChanges()) {
          navigator.pop();
          journalNotifier.clear();
          quesgenNotifier.clear();
          return;
        }

        final shouldDiscard = await showDialog<bool>(
          context: context,
          builder: (context) => const _DiscardChangesDialog(),
        );

        if (shouldDiscard == true) {
          navigator.pop();
          journalNotifier.clear();
          quesgenNotifier.clear();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              pinned: true,
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              centerTitle: true,
              title: AnimatedOpacity(
                opacity: _showTitle ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  widget.movieTitle,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              leading: IconButton(
                onPressed: _handleBackButton,
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
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ElevatedButton(
                    onPressed:
                        journal.emotions.isEmpty &&
                                journal.selectedScenes.isEmpty &&
                                journal.thoughts.isEmpty
                            ? null
                            : () {
                              ref
                                  .read(journalControllerProvider.notifier)
                                  .save()
                                  .then((value) {
                                    final savedJournalId = ref.read(journalControllerProvider).id;
                                    if (context.mounted) {
                                      CustomToast.showSuccess(
                                        'Your journal has been saved.',
                                      );
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => JournalContent(
                                                journalId: savedJournalId,
                                              ),
                                        ),
                                        (route) => route.isFirst,
                                      );
                                    }
                                    ref
                                        .read(
                                          journalControllerProvider.notifier,
                                        )
                                        .clear();
                                    ref
                                        .read(
                                          quesgenControllerProvider.notifier,
                                        )
                                        .clear();
                                  });
                            },
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      textStyle: WidgetStateProperty.all(
                        const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      overlayColor: WidgetStateProperty.all(Color(0xFFA8DADD)),
                      backgroundColor: WidgetStateProperty.all(
                        Colors.transparent,
                      ),
                      side: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.disabled)) {
                          return BorderSide(
                            color: Color(0xFFA8DADD).withAlpha(76),
                            width: 1,
                          );
                        }
                        return BorderSide(color: Color(0xFFA8DADD), width: 1);
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.disabled)) {
                          return Colors.white.withAlpha(76);
                        }
                        return Colors.white;
                      }),
                    ),
                    child: Text('Save'),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Text(
                            widget.movieTitle,
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            Jiffy.now().format(pattern: 'MMM do yyyy'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withAlpha(179),
                              fontFamily: 'AvenirNext',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    EmotionsSelectorButton(),
                    const SizedBox(height: 36),

                    // Poster Preview Button
                    // Center(
                    //   child: OutlinedButton.icon(
                    //     onPressed: () {
                    //       Navigator.push(
                    //         context,
                    //         MaterialPageRoute(
                    //           fullscreenDialog: true,
                    //           builder:
                    //               (context) => PosterPreviewModal(
                    //                 movieId: movieId,
                    //                 movieTitle: widget.movieTitle,
                    //               ),
                    //         ),
                    //       );
                    //     },
                    //     icon: Icon(Icons.palette_outlined, size: 20),
                    //     label: Text('Preview Poster Colors'),
                    //     style: OutlinedButton.styleFrom(
                    //       foregroundColor: Colors.white,
                    //       side: BorderSide(color: Color(0xFFA8DADD)),
                    //       padding: EdgeInsets.symmetric(
                    //         horizontal: 24,
                    //         vertical: 12,
                    //       ),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(16),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // const SectionSeperator(),
                    ScenesSelector(movieId: movieId),
                    const SectionSeperator(),
                    ThoughtsEditor(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscardChangesDialog extends StatelessWidget {
  const _DiscardChangesDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Color(0xFF151515),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discard Changes',
              style: const TextStyle(
                fontFamily: 'AvenirNext',
                fontSize: 24,
                fontWeight: FontWeight.w500,
                height: 32 / 24,
                color: Colors.white,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 24),
            Text(
              'Are you sure you want to discard the changes? All changes will not be saved.',
              style: const TextStyle(
                fontFamily: 'AvenirNext',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 24 / 14,
                color: Colors.white,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'AvenirNext',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Discard',
                    style: TextStyle(
                      fontFamily: 'AvenirNext',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: Color(0xFFFF615D),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
