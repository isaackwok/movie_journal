import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/widgets/review_item.dart';
import 'package:movie_journal/features/quesgen/provider.dart';
import 'package:movie_journal/themes.dart';

class ReviewsBottomSheet extends ConsumerWidget {
  const ReviewsBottomSheet({super.key});

  /// The one way to open this sheet — ThoughtsScreen and ReviewsFloatingButton
  /// used to carry byte-identical copies of this call.
  static void show(BuildContext context) {
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      backgroundColor: DarkSurfaces.sheet,
      builder: (context) => const Wrap(children: [ReviewsBottomSheet()]),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quesgenState = ref.watch(quesgenControllerProvider);
    final reviews = quesgenState.reviews;
    final isLoading = quesgenState.isLoading;
    final journal = ref.watch(journalControllerProvider);
    final selectedRefs = journal.selectedRefs;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.95,
      ),
      decoration: const BoxDecoration(
        color: DarkSurfaces.sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Movie Reviews',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                fontFamily: 'AvenirNext',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'We summarized reviews from Letterboxd and Reddit with AI, add these insights to your notes!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'AvenirNext',
                color: Colors.white.withAlpha(153),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
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
                          showAction: true,
                          onPress: () {
                            if (selectedRefs.contains(review)) {
                              ref
                                  .read(journalControllerProvider.notifier)
                                  .removeSelectedReview(review);
                            } else {
                              ref
                                  .read(journalControllerProvider.notifier)
                                  .addSelectedReview(review);
                            }
                          },
                        ),
                      )
                      : [
                        const Text(
                          'No reviews generated',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
