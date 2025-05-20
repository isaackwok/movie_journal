import 'package:flutter/material.dart';
import 'package:movie_journal/features/search_movie/screens/search_movie.dart';

class AddMovieButton extends StatelessWidget {
  const AddMovieButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SearchMovieScreen()),
        );
      },
      icon: const Icon(Icons.add, size: 20),
      style: IconButton.styleFrom(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        backgroundColor: Colors.white.withAlpha(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
