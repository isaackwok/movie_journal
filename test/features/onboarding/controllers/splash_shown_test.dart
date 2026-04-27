import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/onboarding/controllers/splash_shown.dart';

void main() {
  group('splashShownProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('defaults to false on a fresh container (cold start)', () {
      expect(container.read(splashShownProvider), false);
    });

    test('markShown() flips state to true', () {
      container.read(splashShownProvider.notifier).markShown();
      expect(container.read(splashShownProvider), true);
    });

    test('markShown() is idempotent', () {
      final notifier = container.read(splashShownProvider.notifier);
      notifier.markShown();
      notifier.markShown();
      expect(container.read(splashShownProvider), true);
    });
  });
}
