import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:movie_journal/features/journal/screens/movie_preview.dart';
import 'package:movie_journal/features/movie/controllers/search_movie_controller.dart';
import 'package:movie_journal/features/movie/data/models/brief_movie.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';

class MovieResultList extends ConsumerWidget {
  final ScrollController scrollController;

  const MovieResultList({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(searchMovieControllerProvider);

    return asyncState.when(
      data:
          (state) => ListView.separated(
            padding: const EdgeInsets.only(bottom: 100),
            controller: scrollController,
            itemCount: state.movies.length,
            itemBuilder: (context, index) {
              if (state.mode == SearchMovieMode.popular && index == 0) {
                return Text(
                  'People watched',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                );
              }
              return MovieResultItem(movie: state.movies[index]);
            },
            separatorBuilder: (context, index) {
              return const SizedBox(height: 12);
            },
          ),
      loading:
          () => Skeletonizer(
            enabled: true,
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 100),
              controller: scrollController,
              itemCount: 5, // Show 5 skeleton items
              itemBuilder: (context, index) {
                return SizedBox(
                  height: 128,
                  child: Row(
                    spacing: 16,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Bone(width: 96, height: 128),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 8,
                          children: [
                            Bone.text(words: 3, fontSize: 20),
                            Bone.text(words: 1, fontSize: 12),
                            Bone.multiText(lines: 3, fontSize: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return const SizedBox(height: 12);
              },
            ),
          ),
      error:
          (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error loading movies',
                  style: TextStyle(
                    color: Color(0xFFFCA311),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(searchMovieControllerProvider),
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
    );
  }
}

class MovieResultItem extends ConsumerWidget {
  const MovieResultItem({super.key, required this.movie});

  final BriefMovie movie;

  void _onTap(BuildContext context, WidgetRef ref) {
    ref
        .read(movieDetailControllerProvider.notifier)
        .fetchMovieDetails(movie.id);
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => MoviePreviewScreen(movieId: movie.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        _onTap(context, ref);
      },
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 128,
        child: Row(
          spacing: 16,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child:
                  movie.posterPath != null
                      ? Image.network(
                        'https://image.tmdb.org/t/p/w154/${movie.posterPath}',
                        width: 96,
                        height: 128,
                        fit: BoxFit.cover,
                      )
                      : Image.asset(
                        'assets/images/avatar.png',
                        width: 96,
                        height: 128,
                        fit: BoxFit.contain,
                      ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      '${movie.title}${movie.originalTitle.isNotEmpty && movie.originalTitle != movie.title ? ' (${movie.originalTitle})' : ''}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      movie.year,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA7A7A7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      movie.overview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFE9E9E9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
