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

  static const _maroon = Color(0xFF450302);
  static const _darkText = Color(0xFF450302);
  static const _borderColor = Color(0xFF450302);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: FilmStripClipper(),
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row (outside main border)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FINK MOVIE JOURNAL',
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

            // Main bordered content
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                clipBehavior: Clip.antiAlias,
                foregroundDecoration: BoxDecoration(
                  border: Border.all(color: _borderColor, width: 1),
                ),
                decoration: const BoxDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Title',
                                style: GoogleFonts.inriaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _darkText,
                                ),
                              ),
                              Text(
                                '[$year]',
                                style: GoogleFonts.inriaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _darkText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            movieTitle.toUpperCase(),
                            style: GoogleFonts.inriaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _darkText,
                              height: 1.2,
                              letterSpacing: 1.0,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    _buildDivider(),

                    // Details section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      child: Column(
                        children: [
                          _buildDetailRow('Release', releaseDate),
                          const SizedBox(height: 12),
                          _buildDetailRow('Director', director),
                          const SizedBox(height: 12),
                          _buildDetailRow('Cast', cast),
                        ],
                      ),
                    ),
                    _buildDivider(),

                    // Emotion section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emotion',
                            style: GoogleFonts.inriaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _maroon,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              emotions.isEmpty
                                  ? '--'
                                  : emotions.map((e) => e.name).join(', '),
                              style: GoogleFonts.inriaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _darkText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildDivider(),

                    // Date / Time section with vertical divider
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Date',
                                    style: GoogleFonts.inriaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _maroon,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    createdAt.format(pattern: 'MMM dd'),
                                    style: GoogleFonts.inriaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: _darkText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(width: 1, color: _borderColor),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Time',
                                    style: GoogleFonts.inriaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _maroon,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    createdAt.format(pattern: 'HH:mm'),
                                    style: GoogleFonts.inriaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: _darkText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildDivider(),

                    // Scene image (B&W, 16:9, center-cropped)
                    if (scenePath != null)
                      Expanded(
                        child: ClipRect(
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              Colors.grey,
                              BlendMode.saturation,
                            ),
                            child: Image.network(
                              'https://image.tmdb.org/t/p/w500$scenePath',
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: _borderColor);
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 55,
          child: Text(
            label,
            style: GoogleFonts.inriaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _maroon,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inriaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
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
