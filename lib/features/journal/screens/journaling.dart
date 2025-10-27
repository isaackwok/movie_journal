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

class JournalingScreen extends ConsumerWidget {
  final String movieTitle;
  final String moviePosterUrl;
  const JournalingScreen({
    super.key,
    required this.movieTitle,
    required this.moviePosterUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movieId = ref.watch(movieDetailControllerProvider).movie?.id;
    final journal = ref.watch(journalControllerProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            pinned: true,
            floating: true,
            snap: true,
            automaticallyImplyLeading: false,
            centerTitle: true,
            // title: Text(
            //   movieTitle,
            //   style: GoogleFonts.inter(
            //     fontSize: 28,
            //     fontWeight: FontWeight.w500,
            //   ),
            // ),
            // title: Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   spacing: 12,
            //   children: [
            //     Text(
            //       movieTitle,
            //       style: GoogleFonts.inter(
            //         fontSize: 28,
            //         fontWeight: FontWeight.w500,
            //       ),
            //     ),
            //     Text(
            //       Jiffy.now().format(pattern: 'MMM do yyyy'),
            //       style: GoogleFonts.nothingYouCouldDo(
            //         fontSize: 12,
            //         fontWeight: FontWeight.bold,
            //         color: Colors.white.withAlpha(179),
            //       ),
            //     ),
            //   ],
            // ),
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
                                .save(ref)
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
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    overlayColor: Color(0xFFA8DADD),
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: Color(0xFFA8DADD), width: 1),
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor: Colors.white.withAlpha(76),
                    foregroundColor: Colors.white,
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
                          movieTitle,
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
                  ScenesSelector(movieId: movieId ?? 0),
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
