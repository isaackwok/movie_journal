import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/journal/screens/journaling.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MoviePreviewScreen extends ConsumerWidget {
  final int movieId;

  const MoviePreviewScreen({super.key, required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(movieDetailControllerProvider);

    if (state.isError) {
      return Scaffold(
        key: ValueKey(movieId),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Error loading movies',
              style: TextStyle(
                color: Color(0xFFFCA311),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }
    // if (state.isLoading) {
    //   return Scaffold(
    //     key: ValueKey(movieId),
    //     body: Padding(
    //       padding: EdgeInsets.all(16),
    //       child: Center(child: CircularProgressIndicator()),
    //     ),
    //   );
    // }
    final movie = state.movie;
    if (movie == null) {
      return Text('Movie not found');
    }
    return Skeletonizer(
      enabled: state.isLoading,
      child: Scaffold(
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Skeleton.replace(
                            height: 492,
                            child:
                                movie.posterPath != null
                                    ? Image.network(
                                      'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                                      fit: BoxFit.cover,
                                    )
                                    : Image.asset(
                                      'assets/images/avatar.png',
                                      fit: BoxFit.cover,
                                    ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            spacing: 12,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${movie.title}${movie.originalTitle.isNotEmpty && movie.originalTitle != movie.title ? ' (${movie.originalTitle})' : ''}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${movie.credits.crew.where((e) => e.job == 'Director').firstOrNull?.name ?? 'Unknown'} / ${movie.year} ${movie.originCountry.isNotEmpty ? movie.originCountry.first : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
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
                height: 30,
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
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          shadowColor: Colors.black26,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Color(0xFFD5FC11),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () {
              if (movie.posterPath != null) {
                ref
                    .read(movieImagesControllerProvider.notifier)
                    .getMovieImages(id: movieId);
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
    );
  }
}
