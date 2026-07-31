import 'package:flutter/material.dart';
import 'package:movie_journal/features/share/widgets/film_strip_clipper.dart';
import 'package:movie_journal/core/utils/tmdb_image_url.dart';
import 'package:movie_journal/themes.dart';
import 'package:movie_journal/shared_widgets/tmdb_image.dart';

class TicketFront extends StatelessWidget {
  final String posterPath;

  const TicketFront({super.key, required this.posterPath});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: FilmStripClipper(),
      child: TmdbImage(
        path: posterPath,
        size: TmdbImageSize.w780,
        width: double.infinity,
        height: double.infinity,
        // Rasterised into a PNG by ShareTicketScreen's RepaintBoundary; a fade
        // still in flight at capture time would be baked into the saved image.
        fadeInDuration: Duration.zero,
        errorWidget: Container(
          color: DarkSurfaces.imagePlaceholder,
          child: const Center(
            child: Icon(Icons.movie, color: Colors.white54, size: 64),
          ),
        ),
      ),
    );
  }
}
