import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jiffy/jiffy.dart';
import 'package:movie_journal/features/home/widgets/journal_card.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';

class JournalsList extends ConsumerWidget {
  const JournalsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Grouping and sorting are memoized in the derived provider, so a
    // rebuild of this widget (scroll, theme change, …) costs no re-sort.
    final sortedEntries = ref.watch(groupedJournalsProvider);

    return Column(
      children: [
        ...sortedEntries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              Text(
                Jiffy.parse(
                  entry.key,
                  pattern: 'yyyy-MM',
                ).format(pattern: 'MMM yyyy'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Compute cell height from cell width so the cell hugs the
                  // card's content with no empty trailing gap on any device.
                  //
                  // Layout inside JournalCard:
                  //   - 8px top padding
                  //   - Poster: AspectRatio(150/215) so height = innerWidth * 1.433
                  //   - 12px SizedBox
                  //   - Title (Inter 14, height: 1.1) → 15.4px, ceil 16
                  //   - 8px SizedBox
                  //   - Date (NothingYouCouldDo 12, height: 1.1) → 13.2px, ceil 14
                  //   - 12px bottom padding
                  // Non-poster vertical total = 8 + 12 + 16 + 8 + 14 + 12 = 70
                  const crossAxisCount = 2;
                  const crossAxisSpacing = 12.0;
                  const horizontalPaddingPerCard = 8.0 * 2;
                  const posterAspectFactor = 215.0 / 150.0;
                  const nonPosterHeight = 70.0;

                  final cellWidth =
                      (constraints.maxWidth -
                          crossAxisSpacing * (crossAxisCount - 1)) /
                      crossAxisCount;
                  final posterHeight =
                      (cellWidth - horizontalPaddingPerCard) *
                      posterAspectFactor;
                  final cellHeight = posterHeight + nonPosterHeight;

                  return GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: crossAxisSpacing,
                      mainAxisSpacing: 16,
                      mainAxisExtent: cellHeight,
                    ),
                    itemCount: entry.value.length,
                    itemBuilder: (context, index) {
                      return JournalCard(journal: entry.value[index]);
                    },
                  );
                },
              ),
            ],
          );
        }),
        const SizedBox(height: 32),
      ],
    );
  }
}
