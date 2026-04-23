import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/emotion/emotion.dart';
import 'package:movie_journal/features/journal/widgets/emotions_selector_button.dart';

void main() {
  Widget buildSubject({
    List<Emotion> emotions = const [],
    Function(List<Emotion>)? onSave,
    bool readonly = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: EmotionsSelectorButton(
          emotions: emotions,
          onSave: onSave,
          readonly: readonly,
        ),
      ),
    );
  }

  group('EmotionsSelectorButton', () {
    group('empty state', () {
      testWidgets('displays prompt text when no emotions selected',
          (tester) async {
        await tester.pumpWidget(buildSubject());
        expect(
          find.text('What are your feelings about this movie?'),
          findsOneWidget,
        );
      });

      testWidgets('shows forward arrow icon when empty', (tester) async {
        await tester.pumpWidget(buildSubject());
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      });

      testWidgets('gradient is solid gray when empty', (tester) async {
        await tester.pumpWidget(buildSubject());
        // Find the gradient container (the 40x40 circle)
        final containers = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) =>
                c.decoration is BoxDecoration &&
                (c.decoration as BoxDecoration).gradient is LinearGradient &&
                (c.decoration as BoxDecoration).shape == BoxShape.circle)
            .toList();

        expect(containers, isNotEmpty);
        final gradient =
            (containers.first.decoration as BoxDecoration).gradient
                as LinearGradient;
        // Both stops are the same gray
        expect(gradient.colors[0], const Color(0xFF545454));
        expect(gradient.colors[1], const Color(0xFF545454));
      });
    });

    group('text formatting', () {
      testWidgets('single emotion shows "You felt X by this movie."',
          (tester) async {
        await tester.pumpWidget(buildSubject(
          emotions: [emotionList[EmotionType.joyful]!],
        ));
        expect(find.textContaining('You felt'), findsOneWidget);
        expect(find.textContaining('joyful'), findsOneWidget);
      });

      testWidgets('two emotions shows "X and Y"', (tester) async {
        await tester.pumpWidget(buildSubject(
          emotions: [
            emotionList[EmotionType.joyful]!,
            emotionList[EmotionType.inspired]!,
          ],
        ));
        expect(find.textContaining('joyful'), findsOneWidget);
        expect(find.textContaining('inspired'), findsOneWidget);
      });

      testWidgets('three emotions shows "X, Y and Z"', (tester) async {
        await tester.pumpWidget(buildSubject(
          emotions: [
            emotionList[EmotionType.joyful]!,
            emotionList[EmotionType.inspired]!,
            emotionList[EmotionType.hopeful]!,
          ],
        ));
        expect(find.textContaining('joyful'), findsOneWidget);
        expect(find.textContaining('inspired'), findsOneWidget);
        expect(find.textContaining('hopeful'), findsOneWidget);
      });
    });

    group('typography', () {
      TextSpan? findSpanByText(InlineSpan span, String target) {
        if (span is TextSpan) {
          if (span.text == target) return span;
          for (final child in span.children ?? const <InlineSpan>[]) {
            final hit = findSpanByText(child, target);
            if (hit != null) return hit;
          }
        }
        return null;
      }

      TextSpan? findEmotionSpan(WidgetTester tester, String emotionName) {
        for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
          final hit = findSpanByText(rt.text, emotionName);
          if (hit != null) return hit;
        }
        return null;
      }

      testWidgets('emotion name renders in AvenirNext at w600',
          (tester) async {
        await tester.pumpWidget(buildSubject(
          emotions: [emotionList[EmotionType.joyful]!],
        ));

        final span = findEmotionSpan(tester, 'joyful');
        expect(span, isNotNull);
        expect(span!.style?.fontWeight, FontWeight.w600);
        expect(span.style?.fontFamily, 'AvenirNext');
      });

      testWidgets('all emotion names share the same typography when multiple',
          (tester) async {
        await tester.pumpWidget(buildSubject(
          emotions: [
            emotionList[EmotionType.joyful]!,
            emotionList[EmotionType.inspired]!,
            emotionList[EmotionType.hopeful]!,
          ],
        ));

        for (final name in ['joyful', 'inspired', 'hopeful']) {
          final span = findEmotionSpan(tester, name);
          expect(span, isNotNull, reason: 'missing span for $name');
          expect(span!.style?.fontWeight, FontWeight.w600);
          expect(span.style?.fontFamily, 'AvenirNext');
        }
      });
    });

    group('selected state', () {
      testWidgets('shows edit icon when emotions are selected',
          (tester) async {
        await tester.pumpWidget(buildSubject(
          emotions: [emotionList[EmotionType.joyful]!],
        ));
        expect(find.byIcon(Icons.edit), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward), findsNothing);
      });
    });

    group('energy-based gradient', () {
      testWidgets('all high energy emotions produce warm gradient',
          (tester) async {
        await tester.pumpWidget(buildSubject(
          emotions: [
            emotionList[EmotionType.joyful]!, // high energy
            emotionList[EmotionType.angry]!, // high energy
          ],
        ));

        final containers = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) =>
                c.decoration is BoxDecoration &&
                (c.decoration as BoxDecoration).gradient is LinearGradient &&
                (c.decoration as BoxDecoration).shape == BoxShape.circle)
            .toList();

        final gradient =
            (containers.first.decoration as BoxDecoration).gradient
                as LinearGradient;
        expect(gradient.colors.length, 2);
        expect(gradient.colors[0], const Color(0xFFFADD9E)); // gold
        expect(gradient.colors[1], const Color(0xFFFF8784)); // red
      });

      testWidgets('all low energy emotions produce cool gradient',
          (tester) async {
        await tester.pumpWidget(buildSubject(
          emotions: [
            emotionList[EmotionType.peaceful]!, // low energy
            emotionList[EmotionType.nostalgic]!, // low energy
          ],
        ));

        final containers = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) =>
                c.decoration is BoxDecoration &&
                (c.decoration as BoxDecoration).gradient is LinearGradient &&
                (c.decoration as BoxDecoration).shape == BoxShape.circle)
            .toList();

        final gradient =
            (containers.first.decoration as BoxDecoration).gradient
                as LinearGradient;
        expect(gradient.colors.length, 2);
        expect(gradient.colors[0], const Color(0xFF87C997)); // green
        expect(gradient.colors[1], const Color(0xFF9ADCFF)); // blue
      });

      testWidgets('mixed energy emotions produce rainbow gradient',
          (tester) async {
        await tester.pumpWidget(buildSubject(
          emotions: [
            emotionList[EmotionType.joyful]!, // high energy
            emotionList[EmotionType.peaceful]!, // low energy
          ],
        ));

        final containers = tester
            .widgetList<Container>(find.byType(Container))
            .where((c) =>
                c.decoration is BoxDecoration &&
                (c.decoration as BoxDecoration).gradient is LinearGradient &&
                (c.decoration as BoxDecoration).shape == BoxShape.circle)
            .toList();

        final gradient =
            (containers.first.decoration as BoxDecoration).gradient
                as LinearGradient;
        expect(gradient.colors.length, 5); // 5-stop rainbow
      });
    });

    group('readonly mode', () {
      testWidgets('hides action icon when readonly', (tester) async {
        await tester.pumpWidget(buildSubject(
          emotions: [emotionList[EmotionType.joyful]!],
          readonly: true,
        ));
        expect(find.byIcon(Icons.edit), findsNothing);
        expect(find.byIcon(Icons.arrow_forward), findsNothing);
      });

      testWidgets('still displays emotion text when readonly', (tester) async {
        await tester.pumpWidget(buildSubject(
          emotions: [emotionList[EmotionType.joyful]!],
          readonly: true,
        ));
        expect(find.textContaining('joyful'), findsOneWidget);
      });
    });

    group('interaction', () {
      testWidgets('is wrapped in InkWell for tap', (tester) async {
        await tester.pumpWidget(buildSubject());
        expect(find.byType(InkWell), findsOneWidget);
      });
    });
  });
}
