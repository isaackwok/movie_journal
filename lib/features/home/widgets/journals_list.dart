import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jiffy/jiffy.dart';
import 'package:movie_journal/features/home/widgets/journal_card.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/controllers/journals.dart';

class JournalsList extends ConsumerWidget {
  const JournalsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalsAsync = ref.watch(journalsControllerProvider);

    // Since this widget is only shown when data is loaded (from home.dart),
    // we can safely access the value
    final journals = journalsAsync.value?.journals ?? [];

    // sort & group by month & year
    final grouppedJournals = <String, List<JournalState>>{};
    for (var journal in journals) {
      final month = journal.createdAt.format(pattern: 'yyyy-MM');
      if (!grouppedJournals.containsKey(month)) {
        grouppedJournals[month] = [];
      }
      grouppedJournals[month]!.add(journal);
    }

    // Sort month groups by date (newest first)
    final sortedEntries =
        grouppedJournals.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key));

    return Column(
      children: [
        ...sortedEntries.map((entry) {
          entry.value.sort(
            (a, b) => b.createdAt.dateTime.compareTo(a.createdAt.dateTime),
          );
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
                  //   - 12px top padding
                  //   - Poster: AspectRatio(150/215) so height = innerWidth * 1.433
                  //   - 8px SizedBox
                  //   - Title (Inter 18, height: 1.1) ≈ 22px
                  //   - 4px SizedBox
                  //   - Date (NothingYouCouldDo 12, height: 1.1) ≈ 16px
                  //   - 12px bottom padding
                  // Non-poster vertical total = 12 + 8 + 22 + 4 + 16 + 12 ≈ 74
                  const crossAxisCount = 2;
                  const crossAxisSpacing = 12.0;
                  const horizontalPaddingPerCard = 12.0 * 2;
                  const posterAspectFactor = 215.0 / 150.0;
                  const nonPosterHeight = 74.0;

                  final cellWidth = (constraints.maxWidth -
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
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
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
