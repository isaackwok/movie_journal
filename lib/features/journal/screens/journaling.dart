import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jiffy/jiffy.dart';
import 'package:movie_journal/features/journal/widgets/emotions_selector.dart';

class SectionSeperator extends StatelessWidget {
  const SectionSeperator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Container(height: 0.5, color: Colors.white.withAlpha(76)),
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Text(
                  movieTitle,
                  style: GoogleFonts.nothingYouCouldDo(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
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
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close),
              color: Colors.white,
              style: IconButton.styleFrom(
                shape: CircleBorder(),
                side: BorderSide(color: Colors.white.withAlpha(76)),
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SectionSeperator(),
              EmotionsSelector(),
              const SectionSeperator(),
              Placeholder(),
            ],
          ),
        ),
      ),
    );
  }
}
