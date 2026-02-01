import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/quesgen/provider.dart';
import 'package:movie_journal/features/quesgen/review.dart';

class ReviewItem extends StatelessWidget {
  const ReviewItem({
    super.key,
    required this.review,
    required this.isSelected,
    required this.onSelect,
  });

  final Review review;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(76), width: 1),
        ),
        child: Row(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Text(
                    review.text,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white.withAlpha(20),
                    ),
                    child: Text(
                      review.source,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha(153),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              child: Container(
                alignment: Alignment.topCenter,
                padding: EdgeInsets.all(4),
                child: Icon(
                  size: 24,
                  isSelected ? Icons.bookmark : Icons.bookmark_border,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewsBottomSheet extends ConsumerWidget {
  const ReviewsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quesgenState = ref.watch(quesgenControllerProvider);
    final reviews = quesgenState.reviews;
    final isLoading = quesgenState.isLoading;
    final journal = ref.watch(journalControllerProvider);
    final selectedRefs = journal.selectedRefs;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF171717),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: SizedBox(
                      width: 40,
                      child: Divider(
                        radius: BorderRadius.circular(4),
                        thickness: 4,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Text(
                  'Movie Reviews',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'AvenirNext',
                  ),
                ),
                Text(
                  'Save one or more references to your journal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'AvenirNext',
                    color: Colors.white.withAlpha(153),
                  ),
                ),
                SizedBox(height: 16),

                Column(
                  spacing: 12,
                  children: [
                    ...isLoading
                        ? [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ]
                        : reviews.isNotEmpty
                        ? reviews.map(
                          (review) => ReviewItem(
                            review: review,
                            isSelected: selectedRefs.contains(review),
                            onSelect: () {
                              if (selectedRefs.contains(review)) {
                                ref
                                    .read(journalControllerProvider.notifier)
                                    .removeSelectedReview(review);
                              } else {
                                ref
                                    .read(journalControllerProvider.notifier)
                                    .addSelectedReview(review);
                              }
                              Navigator.pop(context);
                            },
                          ),
                        )
                        : [
                          Text(
                            'No reviews generated',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  '*Disclaimer: AI responses may include mistakes.',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withAlpha(153),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 8,
            child: IconButton(
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.close, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
