import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jiffy/jiffy.dart';
import 'package:movie_journal/features/emotion/emotion.dart';
import 'package:movie_journal/features/share/widgets/film_strip_clipper.dart';

class TicketBack extends StatelessWidget {
  final String movieTitle;
  final String year;
  final String releaseDate;
  final String director;
  final String cast;
  final List<Emotion> emotions;
  final String? scenePath;
  final Jiffy createdAt;
  final int ticketNumber;

  const TicketBack({
    super.key,
    required this.movieTitle,
    required this.year,
    required this.releaseDate,
    required this.director,
    required this.cast,
    required this.emotions,
    required this.scenePath,
    required this.createdAt,
    required this.ticketNumber,
  });

  static const _cream = Color(0xFFF5F0E8);
  static const _maroon = Color(0xFF8B1A1A);
  static const _darkText = Color(0xFF3B2415);

  // Desaturation matrix with slight warm tint
  static const _grayscaleMatrix = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 10, // red
    0.2126, 0.7152, 0.0722, 0, 0, // green
    0.2126, 0.7152, 0.0722, 0, 0, // blue
    0, 0, 0, 1, 0, // alpha
  ]);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: FilmStripClipper(),
      child: Container(
        color: _cream,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top header row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ORIGINAL MOVIE TICKET',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _maroon,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'NO. $ticketNumber',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _maroon,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // Bordered title section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _maroon, width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    Text(
                      'Title [$year]',
                      style: GoogleFonts.inriaSerif(
                        fontSize: 11,
                        color: _maroon.withAlpha(179),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movieTitle,
                      style: GoogleFonts.inriaSerif(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _darkText,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Details rows
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildDetailRow('Release', releaseDate),
                  const SizedBox(height: 6),
                  _buildDetailRow('Director', director),
                  const SizedBox(height: 6),
                  _buildDetailRow('Cast', cast),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Emotion row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emotion  ',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 11,
                      color: _maroon.withAlpha(179),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      emotions.map((e) => e.name).join(', '),
                      style: GoogleFonts.inriaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _darkText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Date band
            Container(
              color: _maroon,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    createdAt.format(pattern: 'MMM dd, yyyy'),
                    style: GoogleFonts.inriaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _cream,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    createdAt.format(pattern: 'hh:mm a'),
                    style: GoogleFonts.inriaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _cream,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Scene image at bottom (16:9, center-cropped)
            if (scenePath != null)
              Expanded(
                child: ClipRect(
                  child: ColorFiltered(
                    colorFilter: _grayscaleMatrix,
                    child: SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 500,
                          height: 500 / (16 / 9),
                          child: Image.network(
                            'https://image.tmdb.org/t/p/w500$scenePath',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: GoogleFonts.inriaSerif(
              fontSize: 11,
              color: _maroon.withAlpha(179),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inriaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _darkText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
