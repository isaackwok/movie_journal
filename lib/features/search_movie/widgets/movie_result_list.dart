import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/journal/screens/movie_preview.dart';
import 'package:movie_journal/features/movie/controllers/search_movie_controller.dart';
import 'package:movie_journal/features/movie/data/models/brief_movie.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';

class MovieResultList extends ConsumerWidget {
  final ScrollController scrollController;

  const MovieResultList({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchMovieControllerProvider);
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 100),
      controller: scrollController,
      itemCount: state.movies.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (state.mode == SearchMovieMode.popular && index == 0) {
          return Text(
            'People watched',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          );
        }
        if (index < state.movies.length) {
          return MovieResultItem(movie: state.movies[index]);
        }
        if (state.isError) {
          return Padding(
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
          );
        }
        return Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      },
      separatorBuilder: (context, index) {
        return const SizedBox(height: 12);
      },
    );
  }
}

class MovieResultItem extends StatelessWidget {
  const MovieResultItem({super.key, required this.movie});

  final BriefMovie movie;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MoviePreviewScreen(movie: movie),
          ),
        );
        // TODO: Handle movie selection
      },
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 95,
        child: Row(
          spacing: 16,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child:
                  movie.posterPath != null
                      ? Image.network(
                        'https://image.tmdb.org/t/p/w500/${movie.posterPath}',
                        width: 72,
                        height: 95,
                        fit: BoxFit.cover,
                      )
                      : Image.asset(
                        'assets/images/avatar.png',
                        width: 72,
                        height: 95,
                        fit: BoxFit.contain,
                      ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  right: 16,
                  top: 2.5,
                  bottom: 2.5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      movie.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      movie.year,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFA7A7A7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      movie.overview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
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
