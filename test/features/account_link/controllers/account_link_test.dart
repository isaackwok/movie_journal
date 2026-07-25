import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/account_link/controllers/account_link.dart';
import 'package:movie_journal/features/home/screens/home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User _user({bool isAnonymous = false}) => User(
  id: '11111111-1111-1111-1111-111111111111',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: '2026-07-25T00:00:00Z',
  isAnonymous: isAnonymous,
);

/// Builds a container fed by [authState], with both providers kept alive.
///
/// The `listen` calls are load-bearing, not decoration: Riverpod 3 auto-
/// disposes by default, so a bare `container.read(authStateProvider.future)`
/// tears the element down in the same microtask and the future never completes
/// — the test then hangs to its 30s timeout rather than failing. Widgets keep
/// these alive by watching them, so this only shows up in container tests.
ProviderContainer _containerFor(Stream<User?> authState) {
  final container = ProviderContainer(
    overrides: [authStateProvider.overrideWith((ref) => authState)],
  );
  container.listen(authStateProvider, (_, _) {});
  container.listen(needsAccountLinkProvider, (_, _) {});
  return container;
}

void main() {
  group('needsAccountLinkProvider', () {
    late ProviderContainer container;

    tearDown(() => container.dispose());

    test('true for a bridged user still on an anonymous session', () async {
      container = _containerFor(Stream.value(_user(isAnonymous: true)));
      await container.read(authStateProvider.future);

      expect(container.read(needsAccountLinkProvider), isTrue);
    });

    test('false for a normal Apple/Google sign-in', () async {
      container = _containerFor(Stream.value(_user()));
      await container.read(authStateProvider.future);

      expect(container.read(needsAccountLinkProvider), isFalse);
    });

    test('false when signed out', () async {
      container = _containerFor(Stream<User?>.value(null));
      await container.read(authStateProvider.future);

      expect(container.read(needsAccountLinkProvider), isFalse);
    });

    test('false while auth state is still loading', () async {
      // A `true` here would flash the banner on for a frame during every cold
      // start, before the session is known.
      final controller = StreamController<User?>();
      addTearDown(controller.close);
      container = _containerFor(controller.stream);

      expect(container.read(needsAccountLinkProvider), isFalse);

      // Let it settle so the provider is not torn down mid-load.
      controller.add(_user(isAnonymous: true));
      await container.read(authStateProvider.future);
    });

    test('flips to false when the session stops being anonymous', () async {
      // What a successful link looks like from this provider's side: gotrue
      // emits `userUpdated` with is_anonymous false, and the banner clears
      // with no invalidation anywhere.
      final controller = StreamController<User?>();
      addTearDown(controller.close);
      container = _containerFor(controller.stream);

      controller.add(_user(isAnonymous: true));
      await container.read(authStateProvider.future);
      expect(container.read(needsAccountLinkProvider), isTrue);

      controller.add(_user());
      await Future<void>.delayed(Duration.zero);
      expect(container.read(needsAccountLinkProvider), isFalse);
    });
  });

  group('accountLinkPromptShownProvider', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('defaults to false on a fresh container (cold start)', () {
      expect(container.read(accountLinkPromptShownProvider), false);
    });

    test('markShown() flips state to true', () {
      container.read(accountLinkPromptShownProvider.notifier).markShown();
      expect(container.read(accountLinkPromptShownProvider), true);
    });

    test('markShown() is idempotent', () {
      final notifier = container.read(accountLinkPromptShownProvider.notifier);
      notifier.markShown();
      notifier.markShown();
      expect(container.read(accountLinkPromptShownProvider), true);
    });
  });
}
