import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';
import 'package:movie_journal/features/journal/widgets/emotions_selector.dart';

class JournalContent extends ConsumerWidget {
  final String journalId;
  const JournalContent({super.key, required this.journalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journals = ref.watch(journalsControllerProvider).journals;
    final journal = journals.firstWhere((journal) => journal.id == journalId);

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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    journal.movieTitle,
                    style: GoogleFonts.nothingYouCouldDo(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    journal.updatedAt.format(pattern: 'MMM do yyyy'),
                    style: GoogleFonts.nothingYouCouldDo(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 36),
                  EmotionButton(
                    svgPath: 'assets/images/emotions/${journal.emotion}.svg',
                    isSelected: true,
                    onTap: (e) {},
                  ),
                  SizedBox(height: 24),
                  Text(
                    journal.thoughts,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 24),
                  Column(
                    spacing: 12,
                    children: [
                      ...journal.selectedScenes.map(
                        (scene) => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            'https://image.tmdb.org/t/p/w500$scene',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
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
