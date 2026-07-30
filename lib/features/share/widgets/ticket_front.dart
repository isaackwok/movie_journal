import 'package:flutter/material.dart';
import 'package:movie_journal/features/share/widgets/film_strip_clipper.dart';
import 'package:movie_journal/core/utils/tmdb_image_url.dart';

class TicketFront extends StatelessWidget {
  final String posterPath;

  const TicketFront({super.key, required this.posterPath});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: FilmStripClipper(),
      child: Image.network(
        tmdbImageUrl(posterPath, TmdbImageSize.w780),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder:
            (context, error, stackTrace) => Container(
              color: const Color(0xFF2C2C2E),
              child: const Center(
                child: Icon(Icons.movie, color: Colors.white54, size: 64),
              ),
            ),
      ),
    );
  }
}
