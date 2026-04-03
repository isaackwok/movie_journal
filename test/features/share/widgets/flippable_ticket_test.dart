import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/share/widgets/flippable_ticket.dart';

void main() {
  Widget buildSubject() {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 500,
          child: FlippableTicket(
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
}
