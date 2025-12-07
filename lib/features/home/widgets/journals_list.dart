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
      final month = journal.updatedAt.format(pattern: 'yyyy-MM');
      if (!grouppedJournals.containsKey(month)) {
        grouppedJournals[month] = [];
      }
      grouppedJournals[month]!.add(journal);
    }

    // Sort month groups by date (newest first)
    final sortedEntries =
        grouppedJournals.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key));

    return SingleChildScrollView(
      child: Column(
        children:
            sortedEntries.map((entry) {
              entry.value.sort(
                (a, b) => b.updatedAt.dateTime.compareTo(a.updatedAt.dateTime),
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
                  GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio:
                          0.59, // Width:Height ratio (adjust based on your content)
                    ),
                    itemCount: entry.value.length,
                    itemBuilder: (context, index) {
                      return JournalCard(journal: entry.value[index]);
                    },
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}
