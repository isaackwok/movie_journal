import 'package:flutter/material.dart';
import 'package:movie_journal/features/search_movie/widgets/movie_search_bar.dart';

class SearchMovieScreen extends StatelessWidget {
  const SearchMovieScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Journal',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        leadingWidth: 32,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.chevron_left, size: 32),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const MovieSearchBar(),
      ),
    );
  }
}
