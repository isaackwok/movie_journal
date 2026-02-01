import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/journal/widgets/reviews_bottom_sheet.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';
import 'package:movie_journal/features/quesgen/provider.dart';

class ReviewsFloatingButton extends ConsumerStatefulWidget {
  const ReviewsFloatingButton({super.key});

  @override
  ConsumerState<ReviewsFloatingButton> createState() =>
      _ReviewsFloatingButtonState();
}

class _ReviewsFloatingButtonState extends ConsumerState<ReviewsFloatingButton> {
  bool _pendingOpen = false;
  final _buttonFocusNode = FocusNode(canRequestFocus: false);

  @override
  void dispose() {
    _buttonFocusNode.dispose();
    super.dispose();
  }

  void _openBottomSheet() {
    if (!mounted) return;
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      backgroundColor: const Color(0xFF171717),
      builder: (context) => const Wrap(children: [ReviewsBottomSheet()]),
    );
  }

  void _onPressed() {
    final movieAsync = ref.read(movieDetailControllerProvider);
    final movie = movieAsync.hasValue ? movieAsync.value : null;
    final quesgenState = ref.read(quesgenControllerProvider);

    if (movie != null &&
        quesgenState.reviews.isEmpty &&
        !quesgenState.isLoading) {
      _pendingOpen = true;
      ref
          .read(quesgenControllerProvider.notifier)
          .generateReviews(movieId: movie.id);
    } else if (!quesgenState.isLoading) {
      _openBottomSheet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
      quesgenControllerProvider.select((s) => s.isLoading),
    );

    ref.listen(quesgenControllerProvider.select((s) => s.isLoading), (
      previous,
      next,
    ) {
      if (previous == true && next == false && _pendingOpen) {
        _pendingOpen = false;
        _openBottomSheet();
      }
    });

    return ElevatedButton.icon(
      focusNode: _buttonFocusNode,
      icon:
          isLoading
              ? SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF11FCEC),
                      backgroundColor: Color(0xFF11FCEC).withAlpha(50),
                    ),
                  ),
                ),
              )
              : SizedBox(
                width: 44,
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/reddit_icon.png',
                      width: 24,
                      height: 24,
                      filterQuality: FilterQuality.high,
                    ),
                    Positioned(
                      left: 20,
                      child: Image.asset(
                        'assets/images/letterboxd_icon.png',
                        width: 24,
                        height: 24,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ],
                ),
              ),
      label: Text(
        'Reviews',
        style: const TextStyle(color: Colors.white, fontFamily: 'AvenirNext'),
      ),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        overlayColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.black,
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1,
        ),
      ),
      onPressed: _onPressed,
    );
  }
}
