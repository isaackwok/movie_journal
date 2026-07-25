import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/supabase_auth_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Unit tests for the pure parts of [SupabaseAuthManager].
///
/// The sign-in flows themselves need live Apple/Google SDKs and a Supabase
/// client, so they are covered by the Phase 7 real-device test instead. What
/// is testable here is the logic that has no I/O — and both pieces below are
/// load-bearing enough to be worth pinning.
User makeUser({Map<String, dynamic> appMetadata = const {}}) {
  return User(
    id: '11111111-1111-1111-1111-111111111111',
    appMetadata: appMetadata,
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-07-25T00:00:00Z',
  );
}

void main() {
  group('providerOf', () {
    test('reads the provider out of app_metadata', () {
      expect(
        SupabaseAuthManager.providerOf(
          makeUser(appMetadata: const {'provider': 'apple'}),
        ),
        'apple',
      );
    });

    test('returns null for a signed-out user', () {
      expect(SupabaseAuthManager.providerOf(null), isNull);
    });

    test('returns null when app_metadata carries no provider', () {
      // Real case, not hypothetical: the anonymous accounts created by the
      // migration bridge have no provider at all. Analytics substitutes
      // 'unknown' rather than crashing on a null.
      expect(SupabaseAuthManager.providerOf(makeUser()), isNull);
    });

    test('returns null when provider is not a string', () {
      // app_metadata is untyped JSON from the server, so a non-string here is
      // a type error waiting to happen at the call site.
      expect(
        SupabaseAuthManager.providerOf(
          makeUser(appMetadata: const {'provider': 42}),
        ),
        isNull,
      );
    });
  });

  group('generateRawNonce', () {
    test('defaults to 32 characters', () {
      expect(SupabaseAuthManager.generateRawNonce().length, 32);
    });

    test('honours an explicit length', () {
      expect(SupabaseAuthManager.generateRawNonce(64).length, 64);
    });

    test('emits only characters safe to carry in a JWT claim', () {
      // Apple echoes the nonce back inside the ID token; anything outside this
      // set risks encoding surprises on the round trip.
      final allowed = RegExp(r'^[A-Za-z0-9\-._]+$');
      for (var i = 0; i < 50; i++) {
        expect(allowed.hasMatch(SupabaseAuthManager.generateRawNonce()), isTrue);
      }
    });

    test('does not repeat across calls', () {
      // The nonce is replay protection. A generator that returned a constant
      // would satisfy every other test in this group while defeating the point.
      final seen = <String>{};
      for (var i = 0; i < 200; i++) {
        seen.add(SupabaseAuthManager.generateRawNonce());
      }
      expect(seen.length, 200);
    });
  });
}
