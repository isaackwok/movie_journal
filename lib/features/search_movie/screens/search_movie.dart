import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/movie/movie_providers.dart';
import 'package:movie_journal/features/search_movie/widgets/movie_result_list.dart';
import 'package:movie_journal/features/search_movie/widgets/movie_search_bar.dart';

class SearchMovieScreen extends ConsumerStatefulWidget {
  const SearchMovieScreen({super.key});

  @override
  ConsumerState<SearchMovieScreen> createState() => _SearchMovieScreenState();
}

class _SearchMovieScreenState extends ConsumerState<SearchMovieScreen> {
  final scrollController = ScrollController();

  void _onScroll() {
    final state = ref.read(searchMovieControllerProvider);
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !state.isLoading) {
      ref.read(searchMovieControllerProvider.notifier).fetchNext();
    }
  }

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(searchMovieControllerProvider.notifier).reset();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Journal'),
          centerTitle: false,
          leadingWidth: 32,
          leading: IconButton(
            iconSize: 32,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            focusColor: Colors.transparent,
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.chevron_left),
          ),
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  MovieSearchBar(),
                  Expanded(
                    child: MovieResultList(scrollController: scrollController),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
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
    );
  }
}
