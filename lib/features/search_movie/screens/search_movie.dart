import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/features/search_movie/movie_providers.dart';
import 'package:movie_journal/features/search_movie/widgets/movie_result_list.dart';
import 'package:movie_journal/features/search_movie/widgets/movie_search_bar.dart';

class SearchMovieScreen extends ConsumerStatefulWidget {
  const SearchMovieScreen({super.key});

  @override
  ConsumerState<SearchMovieScreen> createState() => _SearchMovieScreenState();
}

class _SearchMovieScreenState extends ConsumerState<SearchMovieScreen> {
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      final state = ref.read(movieControllerProvider);
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
          !state.isLoading) {
        ref.read(movieControllerProvider.notifier).fetchNext();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          spacing: 16,
          children: [
            MovieSearchBar(),
            Expanded(
              child: MovieResultList(scrollController: scrollController),
            ),
          ],
        ),
      ),
    );
  }
}
