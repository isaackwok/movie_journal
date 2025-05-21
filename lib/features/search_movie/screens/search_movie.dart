import 'package:flutter/material.dart';
import 'package:movie_journal/features/search_movie/widgets/movie_search_bar.dart';

class SearchMovieScreen extends StatelessWidget {
  const SearchMovieScreen({super.key});

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
        child: const MovieSearchBar(),
      ),
    );
  }
}
