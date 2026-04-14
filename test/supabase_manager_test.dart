import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/supabase_manager.dart';

void main() {
  group('mapSupabaseProvider', () {
    test('maps "google" app_metadata to google.com', () {
      expect(
        mapSupabaseProvider(
          appMetadata: {'provider': 'google'},
          isAnonymous: false,
        ),
        AuthProviderId.google,
      );
    });

    test('maps "apple" app_metadata to apple.com', () {
      expect(
        mapSupabaseProvider(
          appMetadata: {'provider': 'apple'},
          isAnonymous: false,
        ),
        AuthProviderId.apple,
      );
    });

    test('passes through unknown provider strings verbatim', () {
      expect(
        mapSupabaseProvider(
          appMetadata: {'provider': 'github'},
          isAnonymous: false,
        ),
        'github',
      );
    });

    test('returns anonymous when metadata empty and user is anonymous', () {
      expect(
        mapSupabaseProvider(appMetadata: const {}, isAnonymous: true),
        AuthProviderId.anonymous,
      );
    });

    test('returns "unknown" when metadata empty and not anonymous', () {
      expect(
        mapSupabaseProvider(appMetadata: const {}, isAnonymous: false),
        'unknown',
      );
    });

    test('ignores empty provider string and falls through', () {
      expect(
        mapSupabaseProvider(
          appMetadata: const {'provider': ''},
          isAnonymous: true,
        ),
        AuthProviderId.anonymous,
      );
    });
  });

  group('cancelledAuthCodes', () {
    test('contains every code that settings treats as silent abort', () {
      expect(cancelledAuthCodes, containsAll(<String>{
        'canceled',
        'cancelled',
        'sign-in-cancelled',
        'popup-closed-by-user',
        'web-context-canceled',
      }));
    });
  });

  group('AppAuthException', () {
    test('exposes code and message', () {
      const e = AppAuthException(code: 'canceled', message: 'user bailed');
      expect(e.code, 'canceled');
      expect(e.message, 'user bailed');
      expect(e.toString(), contains('canceled'));
      expect(e.toString(), contains('user bailed'));
    });
  });
}
