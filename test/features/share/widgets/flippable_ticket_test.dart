import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/share/widgets/flippable_ticket.dart';

void main() {
  Widget buildSubject({bool hintOnMount = false}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 500,
          child: FlippableTicket(
            hintOnMount: hintOnMount,
            front: const Text('FRONT'),
            back: const Text('BACK'),
          ),
        ),
      ),
    );
  }

  group('FlippableTicket', () {
    testWidgets('shows front widget initially', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('FRONT'), findsOneWidget);
      expect(find.text('BACK'), findsNothing);
    });

    testWidgets('wraps content in GestureDetector for tap', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('shows back widget after tap and animation completes',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      // Tap to trigger flip
      await tester.tap(find.byType(GestureDetector));
      // Let the 600ms animation complete
      await tester.pumpAndSettle();

      expect(find.text('BACK'), findsOneWidget);
      expect(find.text('FRONT'), findsNothing);
    });

    testWidgets('flips back to front on second tap', (tester) async {
      await tester.pumpWidget(buildSubject());

      // First tap: flip to back
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();
      expect(find.text('BACK'), findsOneWidget);

      // Second tap: flip back to front
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();
      expect(find.text('FRONT'), findsOneWidget);
    });

    testWidgets('still shows front before animation reaches midpoint',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      // Tap to start flip
      await tester.tap(find.byType(GestureDetector));
      // Advance only 200ms out of 600ms — should still show front
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('FRONT'), findsOneWidget);
      expect(find.text('BACK'), findsNothing);
    });

    testWidgets('switches to back after animation passes midpoint',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      // Tap to start flip
      await tester.tap(find.byType(GestureDetector));
      // First pump starts the animation
      await tester.pump();
      // Advance well past the 0.5 threshold (easeInOut midpoint = 300ms)
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('BACK'), findsOneWidget);
      expect(find.text('FRONT'), findsNothing);
    });

    testWidgets('wraps child in Transform for 3D rotation', (tester) async {
      await tester.pumpWidget(buildSubject());
      // Find Transform that is a descendant of the FlippableTicket
      final transform = find.descendant(
        of: find.byType(FlippableTicket),
        matching: find.byType(Transform),
      );
      expect(transform, findsOneWidget);
    });
  });

  group('peek hint animation', () {
    testWidgets('does not play hint animation when hintOnMount is false',
        (tester) async {
      await tester.pumpWidget(buildSubject(hintOnMount: false));
      // Advance past the 500ms delay + 700ms animation
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('FRONT'), findsOneWidget);
      expect(find.text('BACK'), findsNothing);
    });

    testWidgets('keeps front visible during peek hint animation',
        (tester) async {
      await tester.pumpWidget(buildSubject(hintOnMount: true));
      // Advance past the 500ms delay into the peek phase
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('FRONT'), findsOneWidget);
      expect(find.text('BACK'), findsNothing);
    });

    testWidgets('completes peek and returns to rest position', (tester) async {
      await tester.pumpWidget(buildSubject(hintOnMount: true));
      // Advance past the 500ms delay to trigger the peek
      await tester.pump(const Duration(milliseconds: 500));
      // Let the peek animation complete (350ms out + 350ms back)
      await tester.pumpAndSettle();

      expect(find.text('FRONT'), findsOneWidget);
      expect(find.text('BACK'), findsNothing);
    });

    testWidgets('tap to flip works normally after peek animation completes',
        (tester) async {
      await tester.pumpWidget(buildSubject(hintOnMount: true));
      // Advance past delay + both peek phases: 500 + 350 + 350 = 1200ms
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Tap to flip
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(find.text('BACK'), findsOneWidget);
      expect(find.text('FRONT'), findsNothing);
    });

    testWidgets('ignores tap during peek animation', (tester) async {
      await tester.pumpWidget(buildSubject(hintOnMount: true));
      // Advance into the peek animation
      await tester.pump(const Duration(milliseconds: 600));

      // Tap during animation — should be ignored by _flip() guard
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      // Peek completes back to rest, tap was ignored
      expect(find.text('FRONT'), findsOneWidget);
    });

    testWidgets('double flip after peek animation works correctly',
        (tester) async {
      await tester.pumpWidget(buildSubject(hintOnMount: true));
      // Advance past delay + both peek phases
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // First tap: flip to back
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();
      expect(find.text('BACK'), findsOneWidget);

      // Second tap: flip back to front
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();
      expect(find.text('FRONT'), findsOneWidget);
    });
  });

  group('swipe gesture', () {
    testWidgets('swipe left flips to back', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.drag(
        find.byType(FlippableTicket),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('BACK'), findsOneWidget);
      expect(find.text('FRONT'), findsNothing);
    });

    testWidgets('swipe right from back returns to front', (tester) async {
      await tester.pumpWidget(buildSubject());

      // First flip to back via tap
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();
      expect(find.text('BACK'), findsOneWidget);

      // Swipe right to return to front
      await tester.drag(
        find.byType(FlippableTicket),
        const Offset(300, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('FRONT'), findsOneWidget);
      expect(find.text('BACK'), findsNothing);
    });

    testWidgets('partial drag before midpoint snaps back to front',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      // Drag left only ~30% of width — not past midpoint
      await tester.drag(
        find.byType(FlippableTicket),
        const Offset(-90, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('FRONT'), findsOneWidget);
      expect(find.text('BACK'), findsNothing);
    });

    testWidgets('partial drag past midpoint snaps to back', (tester) async {
      await tester.pumpWidget(buildSubject());

      // Drag left ~60% of width — past midpoint
      await tester.drag(
        find.byType(FlippableTicket),
        const Offset(-180, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('BACK'), findsOneWidget);
      expect(find.text('FRONT'), findsNothing);
    });

    testWidgets('swipe right from front also flips to back', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.drag(
        find.byType(FlippableTicket),
        const Offset(300, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('BACK'), findsOneWidget);
      expect(find.text('FRONT'), findsNothing);
    });

    testWidgets('fling left flips to back', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.fling(
        find.byType(FlippableTicket),
        const Offset(-100, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('BACK'), findsOneWidget);
      expect(find.text('FRONT'), findsNothing);
    });

    testWidgets('fling right from back flips to front', (tester) async {
      await tester.pumpWidget(buildSubject());

      // First flip to back
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      // Fling right
      await tester.fling(
        find.byType(FlippableTicket),
        const Offset(100, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('FRONT'), findsOneWidget);
      expect(find.text('BACK'), findsNothing);
    });

    testWidgets('tap still works after a drag', (tester) async {
      await tester.pumpWidget(buildSubject());

      // Partial drag that snaps back
      await tester.drag(
        find.byType(FlippableTicket),
        const Offset(-60, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('FRONT'), findsOneWidget);

      // Tap should still flip
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(find.text('BACK'), findsOneWidget);
      expect(find.text('FRONT'), findsNothing);
    });
  });
}
