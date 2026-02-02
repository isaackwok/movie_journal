import 'package:flutter/rendering.dart';

class FilmStripClipper extends CustomClipper<Path> {
  final double holeRadius;
  final double holeSpacing;
  final double cornerRadius;

  FilmStripClipper({
    this.holeRadius = 8,
    this.holeSpacing = 28,
    this.cornerRadius = 16,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    // Outer rounded rectangle
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(cornerRadius),
      ),
    );

    // Perforation holes along top and bottom edges
    final holeCount = ((size.width - holeSpacing) / holeSpacing).floor();
    final startX = (size.width - (holeCount - 1) * holeSpacing) / 2;

    for (int i = 0; i < holeCount; i++) {
      final x = startX + i * holeSpacing;
      // Top edge holes
      path.addOval(
        Rect.fromCircle(center: Offset(x, 0), radius: holeRadius),
      );
      // Bottom edge holes
      path.addOval(
        Rect.fromCircle(center: Offset(x, size.height), radius: holeRadius),
      );
    }

    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(FilmStripClipper oldClipper) =>
      holeRadius != oldClipper.holeRadius ||
      holeSpacing != oldClipper.holeSpacing ||
      cornerRadius != oldClipper.cornerRadius;
}
