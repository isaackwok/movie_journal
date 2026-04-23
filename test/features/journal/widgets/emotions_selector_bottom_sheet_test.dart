import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/emotion/emotion.dart';
import 'package:movie_journal/features/journal/widgets/emotions_selector_bottom_sheet.dart';

void main() {
  Widget buildSubject({
    List<Emotion> initialEmotions = const [],
    Function(List<Emotion>)? onSave,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          // Use a full-height body so the bottom sheet has room
          body: Builder(
            builder: (context) {
              // Directly render the bottom sheet content for testing
              return SingleChildScrollView(
                child: EmotionsSelectorBottomSheet(
                  initialEmotions: initialEmotions,
                  onSave: onSave,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  group('EmotionsSelectorBottomSheet', () {
    group('header', () {
      testWidgets('displays question text', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        expect(
          find.text('What are your feelings about this movie?'),
          findsOneWidget,
        );
      });

      testWidgets('displays selection counter starting at 0/3',
          (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        expect(find.text('Select up to 3 (0/3)'), findsOneWidget);
      });

      testWidgets('counter reflects initial emotions count', (tester) async {
        await tester.pumpWidget(buildSubject(
          initialEmotions: [emotionList[EmotionType.joyful]!],
        ));
        await tester.pumpAndSettle();
        expect(find.text('Select up to 3 (1/3)'), findsOneWidget);
      });

      testWidgets('displays close icon button', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.close), findsOneWidget);
      });
    });

    group('first page content', () {
      testWidgets('displays High Energy page title', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        expect(find.text('High Energy'), findsOneWidget);
      });

      testWidgets('displays Uplifting section label', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        expect(find.text('Uplifting'), findsOneWidget);
      });

      testWidgets('displays Intense section label', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        expect(find.text('Intense'), findsOneWidget);
      });

      testWidgets('displays all 6 Uplifting emotion names', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        expect(find.text('Joyful'), findsOneWidget);
        expect(find.text('Funny'), findsOneWidget);
        expect(find.text('Inspired'), findsOneWidget);
        expect(find.text('Mind-blown'), findsOneWidget);
        expect(find.text('Hopeful'), findsOneWidget);
        expect(find.text('Fulfilling'), findsOneWidget);
      });

      testWidgets('displays all 6 Intense emotion names', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        expect(find.text('Shocked'), findsOneWidget);
        expect(find.text('Angry'), findsOneWidget);
        expect(find.text('Terrified'), findsOneWidget);
        expect(find.text('Anxious'), findsOneWidget);
        expect(find.text('Overwhelmed'), findsOneWidget);
        expect(find.text('Disturbed'), findsOneWidget);
      });
    });

    group('selection behavior', () {
      testWidgets('tapping an emotion updates the counter', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Joyful'));
        await tester.pumpAndSettle();

        expect(find.text('Select up to 3 (1/3)'), findsOneWidget);
      });

      testWidgets('tapping a second emotion updates counter to 2',
          (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Joyful'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Angry'));
        await tester.pumpAndSettle();

        expect(find.text('Select up to 3 (2/3)'), findsOneWidget);
      });

      testWidgets('cannot select more than 3 emotions', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Select 3 emotions
        await tester.tap(find.text('Joyful'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Angry'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Shocked'));
        await tester.pumpAndSettle();
        expect(find.text('Select up to 3 (3/3)'), findsOneWidget);

        // Try to select a 4th — counter should stay at 3/3
        await tester.tap(find.text('Funny'));
        await tester.pumpAndSettle();
        expect(find.text('Select up to 3 (3/3)'), findsOneWidget);
      });

      testWidgets('tapping a selected emotion deselects it', (tester) async {
        await tester.pumpWidget(buildSubject(
          initialEmotions: [emotionList[EmotionType.joyful]!],
        ));
        await tester.pumpAndSettle();
        expect(find.text('Select up to 3 (1/3)'), findsOneWidget);

        // Tap Joyful to deselect
        await tester.tap(find.text('Joyful'));
        await tester.pumpAndSettle();

        expect(find.text('Select up to 3 (0/3)'), findsOneWidget);
      });
    });

    group('Done button', () {
      testWidgets('displays Done button', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        expect(find.text('Done'), findsOneWidget);
      });

      testWidgets('Done calls onSave with selected emotions', (tester) async {
        List<Emotion>? savedEmotions;
        await tester.pumpWidget(buildSubject(
          onSave: (emotions) => savedEmotions = emotions,
        ));
        await tester.pumpAndSettle();

        // Select two emotions
        await tester.tap(find.text('Joyful'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Inspired'));
        await tester.pumpAndSettle();

        // Tap Done
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        expect(savedEmotions, isNotNull);
        expect(savedEmotions!.length, 2);
        expect(savedEmotions!.any((e) => e.id == 'joyful'), isTrue);
        expect(savedEmotions!.any((e) => e.id == 'inspired'), isTrue);
      });

      testWidgets('Done with no selection calls onSave with empty list',
          (tester) async {
        List<Emotion>? savedEmotions;
        await tester.pumpWidget(buildSubject(
          onSave: (emotions) => savedEmotions = emotions,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        expect(savedEmotions, isNotNull);
        expect(savedEmotions, isEmpty);
      });
    });

    group('page indicator', () {
      testWidgets('displays 2 page indicator dots', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Find the page indicator containers (6x6 circles)
        final dots = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) =>
                c.decoration is BoxDecoration &&
                (c.decoration as BoxDecoration).shape == BoxShape.circle &&
                c.constraints?.maxWidth == 6)
            .toList();

        expect(dots.length, 2);
      });
    });

    group('divider between sections', () {
      testWidgets('has a Divider between Uplifting and Intense sections',
          (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();
        expect(find.byType(Divider), findsOneWidget);
      });
    });
  });
}
