import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/onboarding/controllers/splash_posters.dart';
import 'package:movie_journal/features/onboarding/controllers/splash_shown.dart';
import 'package:movie_journal/features/onboarding/screens/branding_splash.dart';

import '../../../helpers/widget_test_setup.dart';

Widget _wrap({required ProviderContainer container, required Widget child}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: child),
  );
}

void main() {
  setUpAll(setUpWidgetTests);
  tearDownAll(tearDownWidgetTests);

  group('BrandingSplashScreen', () {
    late ProviderContainer container;

    setUp(() {
      // Override the posters provider so the test never makes a network call.
      // Empty list keeps the marquee invisible (AnimatedOpacity stays at 0)
      // without affecting the splash's fade or timing logic.
      container = ProviderContainer(
        overrides: [
          splashPostersProvider.overrideWith((ref) async => const <String>[]),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('renders the tagline (the Fink wordmark is in the SVG)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(container: container, child: const BrandingSplashScreen()),
      );
      // Drive the fade past its initial 0-opacity frame so HitTest-style
      // finders work; opacity itself doesn't gate find.text.
      await tester.pump(const Duration(milliseconds: 100));

      // The "Fink" wordmark lives inside fink_logo.svg, not as a Text widget,
      // so we don't expect a Text "Fink" — only the tagline.
      expect(find.text('Fink'), findsNothing);
      expect(
        find.text('From film to ink,\nBuild your movie journey.'),
        findsOneWidget,
      );

      // Cleanly unmount to dispose the repeating marquee controller.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('marks splash shown after the fade duration completes', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(container: container, child: const BrandingSplashScreen()),
      );

      // At t=0 the fade hasn't completed yet.
      expect(container.read(splashShownProvider), false);

      // Just before the splash duration elapses — still not shown.
      await tester.pump(const Duration(milliseconds: 4900));
      expect(container.read(splashShownProvider), false);

      // After the fade controller's status becomes `completed`, the splash
      // flips the flag.
      await tester.pump(const Duration(milliseconds: 200));
      expect(container.read(splashShownProvider), true);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
