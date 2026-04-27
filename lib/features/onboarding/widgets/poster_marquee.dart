import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/onboarding/controllers/splash_posters.dart';
import 'package:movie_journal/features/onboarding/widgets/marquee_row.dart';

/// Renders two blurred, tilted rows of posters anchored to the bottom-right of
/// its parent. The parent is expected to bound the marquee's height
/// (e.g. via a `Positioned(bottom: 0, height: 380, ...)`); this widget then
/// computes an explicit viewport width so both rows stay visible while each
/// [MarqueeRow] repeats enough tiles to scroll seamlessly through that window.
class PosterMarquee extends ConsumerWidget {
  final Animation<double> progress;
  final double tileWidth;
  final double tileHeight;
  final double rowGap;
  final double rotationRadians;

  const PosterMarquee({
    super.key,
    required this.progress,
    this.tileWidth = 91,
    this.tileHeight = 120,
    this.rowGap = 14,
    this.rotationRadians = -0.2,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postersAsync = ref.watch(splashPostersProvider);
    final posters = postersAsync.maybeWhen(
      data: (urls) => urls,
      orElse: () => const <String>[],
    );
    final hasPosters = posters.isNotEmpty;
    // Stagger the second row so the two rows don't render the same tile at
    // the same x position.
    final row2 =
        hasPosters
            ? [...posters.skip(1), ...posters.take(1)]
            : const <String>[];

    return AnimatedOpacity(
      opacity: hasPosters ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const bottomPadding = 24.0;
          final marqueeHeight = (tileHeight * 2) + rowGap;
          final rotationCompensation =
              math.sin(rotationRadians.abs()) * marqueeHeight;
          final horizontalBleed = tileWidth + rotationCompensation;
          final viewportWidth =
              constraints.maxWidth + tileWidth * 1.5 + (horizontalBleed * 2);

          return Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: bottomPadding),
              child: Transform.translate(
                // Rotating around the bottom-right tucks the upper part of the
                // marquee slightly left, so nudge it back to keep the visible
                // rows visually pinned to the screen edge.
                offset: Offset(rotationCompensation, 0),
                child: Transform.rotate(
                  // Keep the bottom-right corner stable while the rows tilt
                  // away from the brand mark.
                  angle: rotationRadians,
                  alignment: Alignment.bottomRight,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: SizedBox(
                      width: viewportWidth,
                      height: marqueeHeight,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          MarqueeRow(
                          posters: posters,
                          progress: progress,
                          viewportWidth: viewportWidth,
                          leadingBleed: horizontalBleed,
                          tileWidth: tileWidth,
                          tileHeight: tileHeight,
                        ),
                          SizedBox(height: rowGap),
                          MarqueeRow(
                          posters: row2,
                          progress: progress,
                          viewportWidth: viewportWidth,
                          leadingBleed: horizontalBleed,
                          tileWidth: tileWidth,
                          tileHeight: tileHeight,
                          reverse: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
