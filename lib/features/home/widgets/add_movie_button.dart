import 'package:flutter/material.dart';
import 'package:movie_journal/features/search_movie/screens/search_movie.dart';
import 'package:movie_journal/shared_widgets/circled_icon_button.dart';

class AddMovieButton extends StatelessWidget {
  const AddMovieButton({super.key});

  @override
  Widget build(BuildContext context) {
    return CircledIconButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SearchMovieScreen()),
        );
      },
      icon: Icons.add,
      iconSize: 28,
      size: 48,
    );
  }
}
