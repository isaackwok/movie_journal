import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/toast/custom_toast.dart';
import 'package:movie_journal/themes.dart';

void main() {
  // Pumps a button that fires `show`, taps it, and returns once the toast
  // overlay has rendered one frame.
  Future<void> showToast(
    WidgetTester tester,
    void Function(BuildContext) show,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                CustomToast.init(context);
                show(context);
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
  }

  // The icon circle is the nearest Container ancestor of the glyph.
  BoxDecoration circleOf(WidgetTester tester, IconData icon) {
    final container = tester.widget<Container>(
      find.ancestor(of: find.byIcon(icon), matching: find.byType(Container)).first,
    );
    return container.decoration as BoxDecoration;
  }

  Future<void> drainToastTimers(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  group('CustomToast status → color mapping', () {
    testWidgets('success uses the primary status color with a black check',
        (tester) async {
      await showToast(tester, (c) => CustomToast.showSuccess(c, 'Saved'));

      expect(find.text('Saved'), findsWidgets);
      expect(tester.widget<Icon>(find.byIcon(Icons.check)).color, Colors.black);
      final deco = circleOf(tester, Icons.check);
      expect(deco.color, StatusColors.success);
      expect(deco.shape, BoxShape.circle);

      await drainToastTimers(tester);
    });

    testWidgets('error uses the error status color with a black cross',
        (tester) async {
      await showToast(tester, (_) => CustomToast.showError('Nope'));

      expect(find.text('Nope'), findsWidgets);
      expect(tester.widget<Icon>(find.byIcon(Icons.close)).color, Colors.black);
      expect(circleOf(tester, Icons.close).color, StatusColors.error);

      await drainToastTimers(tester);
    });

    testWidgets('warning uses the warning status color with a black bang',
        (tester) async {
      await showToast(tester, (_) => CustomToast.showWarning('Careful'));

      expect(find.text('Careful'), findsWidgets);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.priority_high)).color,
        Colors.black,
      );
      expect(circleOf(tester, Icons.priority_high).color, StatusColors.warning);

      await drainToastTimers(tester);
    });
  });
}
