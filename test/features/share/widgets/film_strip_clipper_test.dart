import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/share/widgets/film_strip_clipper.dart';

void main() {
  group('FilmStripClipper', () {
    late FilmStripClipper clipper;

    setUp(() {
      clipper = FilmStripClipper();
    });

    group('default parameters', () {
      test('holeRadius defaults to 8', () {
        expect(clipper.holeRadius, 8);
      });

      test('holeSpacing defaults to 28', () {
        expect(clipper.holeSpacing, 28);
      });

      test('cornerRadius defaults to 0', () {
        expect(clipper.cornerRadius, 0);
      });

      test('cornerHoleRadius defaults to 16', () {
        expect(clipper.cornerHoleRadius, 16);
      });
    });

    group('custom parameters', () {
      test('accepts custom values', () {
        final custom = FilmStripClipper(
          holeRadius: 5,
          holeSpacing: 20,
          cornerRadius: 4,
          cornerHoleRadius: 10,
        );
        expect(custom.holeRadius, 5);
        expect(custom.holeSpacing, 20);
        expect(custom.cornerRadius, 4);
        expect(custom.cornerHoleRadius, 10);
      });
    });

    group('getClip', () {
      test('returns path with evenOdd fill type', () {
        final path = clipper.getClip(const Size(300, 500));
        expect(path.fillType, PathFillType.evenOdd);
      });

      test('center of rectangle is included', () {
        final path = clipper.getClip(const Size(300, 500));
        expect(path.contains(const Offset(150, 250)), isTrue);
      });

      test('interior points away from edges and corners are included', () {
        final path = clipper.getClip(const Size(300, 500));
        expect(path.contains(const Offset(50, 100)), isTrue);
        expect(path.contains(const Offset(250, 400)), isTrue);
        expect(path.contains(const Offset(150, 50)), isTrue);
      });

      test('points outside the rectangle are excluded', () {
        final path = clipper.getClip(const Size(300, 500));
        expect(path.contains(const Offset(-10, 250)), isFalse);
        expect(path.contains(const Offset(150, -10)), isFalse);
        expect(path.contains(const Offset(310, 250)), isFalse);
        expect(path.contains(const Offset(150, 510)), isFalse);
      });
    });

    group('corner holes', () {
      test('top-left corner is excluded', () {
        final path = clipper.getClip(const Size(300, 500));
        // (5, 5) is within cornerHoleRadius=16 of corner (0, 0)
        expect(path.contains(const Offset(5, 5)), isFalse);
      });

      test('top-right corner is excluded', () {
        final path = clipper.getClip(const Size(300, 500));
        expect(path.contains(const Offset(295, 5)), isFalse);
      });

      test('bottom-left corner is excluded', () {
        final path = clipper.getClip(const Size(300, 500));
        expect(path.contains(const Offset(5, 495)), isFalse);
      });

      test('bottom-right corner is excluded', () {
        final path = clipper.getClip(const Size(300, 500));
        expect(path.contains(const Offset(295, 495)), isFalse);
      });

      test('points just outside corner hole radius are included', () {
        // cornerHoleRadius=16, so point at distance > 16 from corner
        // (20, 0.5) is distance ~20 from (0,0), outside the hole
        // but y=0.5 is inside the rect (barely), and far enough from edge holes
        final path = clipper.getClip(const Size(300, 500));
        // Point at (25, 25) is distance ~35.4 from corner — well outside the hole
        expect(path.contains(const Offset(25, 25)), isTrue);
      });
    });

    group('edge perforation holes', () {
      test('top edge hole positions are excluded', () {
        final path = clipper.getClip(const Size(300, 500));
        // holeCount = ((300 - 28) / 28).floor() = 9
        // startX = (300 - 8*28) / 2 = 38
        // Hole at x=150 (center), y=0, radius=8
        // Point (150, 1) is inside the hole oval
        expect(path.contains(const Offset(150, 1)), isFalse);
      });

      test('bottom edge hole positions are excluded', () {
        final path = clipper.getClip(const Size(300, 500));
        // Hole at x=150, y=500, radius=8
        expect(path.contains(const Offset(150, 499)), isFalse);
      });

      test('points between top edge holes are included', () {
        final path = clipper.getClip(const Size(300, 500));
        // Holes at x: 38, 66, 94, ... — midpoint between 38 and 66 is 52
        // Point (52, 3) is between holes, slightly inside the edge
        expect(path.contains(const Offset(52, 3)), isTrue);
      });

      test('top and bottom holes are symmetric', () {
        final path = clipper.getClip(const Size(300, 500));
        // Both edges should have holes at the same x positions
        // At a hole x position, both top and bottom should be excluded
        final topExcluded = path.contains(const Offset(150, 1));
        final bottomExcluded = path.contains(const Offset(150, 499));
        expect(topExcluded, equals(bottomExcluded));
      });
    });

    group('shouldReclip', () {
      test('returns false for identical parameters', () {
        final other = FilmStripClipper();
        expect(clipper.shouldReclip(other), isFalse);
      });

      test('returns true when holeRadius differs', () {
        final other = FilmStripClipper(holeRadius: 10);
        expect(clipper.shouldReclip(other), isTrue);
      });

      test('returns true when holeSpacing differs', () {
        final other = FilmStripClipper(holeSpacing: 32);
        expect(clipper.shouldReclip(other), isTrue);
      });

      test('returns true when cornerRadius differs', () {
        final other = FilmStripClipper(cornerRadius: 8);
        expect(clipper.shouldReclip(other), isTrue);
      });

      test('returns true when cornerHoleRadius differs', () {
        final other = FilmStripClipper(cornerHoleRadius: 12);
        expect(clipper.shouldReclip(other), isTrue);
      });
    });
  });
}
