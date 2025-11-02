import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jiffy/jiffy.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/screens/journal_content.dart';
import 'package:movie_journal/features/journal/widgets/emotions_selector.dart';
import 'package:movie_journal/features/journal/widgets/scenes_selector.dart';
import 'package:movie_journal/features/journal/widgets/thoughts_editor.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';
import 'package:movie_journal/features/quesgen/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final movieAsync = ref.watch(movieDetailControllerProvider);
    final movieId = movieAsync.hasValue ? movieAsync.value!.id : 0;
    final journal = ref.watch(journalControllerProvider);
    return Scaffold(
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
              onPressed: () {
                Navigator.pop(context);
                ref.read(journalControllerProvider.notifier).clear();
                ref.read(quesgenControllerProvider.notifier).clear();
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
                                  if (context.mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => JournalContent(
                                              journalId: journal.id,
                                            ),
                                      ),
                                      (route) => route.isFirst,
                                    );
                                  }
                                  ref
                                      .read(journalControllerProvider.notifier)
                                      .clear();
                                  ref
                                      .read(quesgenControllerProvider.notifier)
                                      .clear();
                                  // TODO: Show success toast message
                                });

                            // Fluttertoast.showToast(
                            //   msg: 'Your journal has been saved',
                            //   toastLength: Toast.LENGTH_SHORT,
                            //   gravity: ToastGravity.BOTTOM,
                            //   timeInSecForIosWeb: 1,
                            //   backgroundColor: Colors.black,
                            //   textColor: Colors.white,
                            //   fontSize: 16,
                            // );
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
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
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
                      spacing: 12,
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
                          style: GoogleFonts.nothingYouCouldDo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withAlpha(179),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SectionSeperator(),
                  EmotionsSelector(),
                  const SectionSeperator(),
                  ScenesSelector(movieId: movieId),
                  const SectionSeperator(),
                  ThoughtsEditor(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
