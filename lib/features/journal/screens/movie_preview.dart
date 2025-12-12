import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';
import 'package:movie_journal/features/journal/screens/journaling.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MoviePreviewScreen extends ConsumerWidget {
  final int movieId;

  const MoviePreviewScreen({super.key, required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(movieDetailControllerProvider);

    return asyncState.when(
      data:
          (movie) => Scaffold(
            key: ValueKey(movieId),
            body: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 50),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (movie.posterPath != null)
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    'https://image.tmdb.org/t/p/original${movie.posterPath}',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    frameBuilder: (
                                      context,
                                      child,
                                      frame,
                                      wasSynchronouslyLoaded,
                                    ) {
                                      if (wasSynchronouslyLoaded) {
                                        return child;
                                      }
                                      // Show skeleton while loading
                                      if (frame == null) {
                                        return Skeleton.replace(
                                          height: 492,
                                          width: double.infinity,
                                          child: Container(),
                                        );
                                      }
                                      // Show actual image at its natural aspect ratio
                                      return child;
                                    },
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Column(
                                spacing: 12,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${movie.title}${movie.originalTitle.isNotEmpty && movie.originalTitle != movie.title ? ' (${movie.originalTitle})' : ''}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${movie.credits.crew.where((e) => e.job == 'Director').firstOrNull?.name ?? 'Unknown'} | ${movie.year} |  ${movie.originCountry.isNotEmpty ? movie.originCountry.first : ''}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFC5C5C5),
                                    ),
                                  ),
                                  Text(
                                    movie.overview,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFFC5C5C5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 60,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Theme.of(context).colorScheme.surface,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 12,
                    right: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(128),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        style: IconButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                        padding: const EdgeInsets.all(8),
                        // constraints: const BoxConstraints(
                        //   minWidth: 36,
                        //   minHeight: 36,
                        // ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BottomAppBar(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              shadowColor: Colors.black26,
              child: TextButton(
                style: TextButton.styleFrom(
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'AvenirNext',
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () {
                  if (movie.posterPath != null) {
                    ref
                        .read(movieImagesControllerProvider.notifier)
                        .getMovieImages(id: movieId);
                    ref
                        .read(journalControllerProvider.notifier)
                        .setMovie(movieId, movie.title, movie.posterPath!);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => JournalingScreen(
                              movieTitle: movie.title,
                              moviePosterUrl: movie.posterPath!,
                            ),
                      ),
                    );
                  }
                },
                child: const Text('Start Journaling'),
              ),
            ),
          ),
      loading:
          () => Scaffold(
            key: ValueKey(movieId),
            body: SafeArea(
              child: Skeletonizer(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 50),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Bone.square(size: 492),
                              ),
                              const SizedBox(height: 24),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Column(
                                  spacing: 12,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Bone.text(words: 3, fontSize: 28),
                                    Bone.text(words: 5, fontSize: 14),
                                    Bone.multiText(lines: 4, fontSize: 14),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(128),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          style: IconButton.styleFrom(padding: EdgeInsets.zero),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28,
                          ),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: BottomAppBar(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              shadowColor: Colors.black26,
              child: Bone.button(
                width: double.infinity,
                height: 48,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
      error:
          (error, stackTrace) => Scaffold(
            key: ValueKey(movieId),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading movie',
                    style: TextStyle(
                      color: Color(0xFFFCA311),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(movieDetailControllerProvider),
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
