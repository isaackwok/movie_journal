import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/login/screens/create_user.dart';

// Note: create_user.dart now includes AnalyticsManager calls (screen view + sign_up event).
// These are no-ops without Firebase and don't affect validateUsername() tests below.

void main() {
  group('validateUsername', () {
    group('valid usernames', () {
      test('accepts lowercase letters', () {
        expect(validateUsername('john'), isNull);
      });

      test('accepts uppercase letters', () {
        expect(validateUsername('John'), isNull);
      });

      test('accepts numbers', () {
        expect(validateUsername('user123'), isNull);
      });

      test('accepts underscores in the middle', () {
        expect(validateUsername('john_doe'), isNull);
      });

      test('accepts dots in the middle', () {
        expect(validateUsername('john.doe'), isNull);
      });

      test('accepts mix of all valid characters', () {
        expect(validateUsername('John_doe.123'), isNull);
      });

      test('accepts single character', () {
        expect(validateUsername('a'), isNull);
      });
    });

    group('empty username', () {
      test('rejects empty string', () {
        expect(validateUsername(''), 'Username cannot be empty');
      });
    });

    group('invalid characters', () {
      test('rejects spaces', () {
        expect(
          validateUsername('john doe'),
          'Username can only contain letters, numbers, _ and .',
        );
      });

      test('rejects hyphens', () {
        expect(
          validateUsername('john-doe'),
          'Username can only contain letters, numbers, _ and .',
        );
      });

      test('rejects special characters', () {
        expect(
          validateUsername('john@doe'),
          'Username can only contain letters, numbers, _ and .',
        );
      });

      test('rejects unicode characters', () {
        expect(
          validateUsername('用戶名'),
          'Username can only contain letters, numbers, _ and .',
        );
      });
    });

    group('only special characters', () {
      test('rejects only underscores', () {
        expect(
          validateUsername('___'),
          'Username cannot contain only _ and .',
        );
      });

      test('rejects only dots', () {
        expect(
          validateUsername('...'),
          'Username cannot contain only _ and .',
        );
      });

      test('rejects mix of only underscores and dots', () {
        expect(
          validateUsername('_._'),
          'Username cannot contain only _ and .',
        );
      });

      test('rejects single underscore', () {
        expect(
          validateUsername('_'),
          'Username cannot contain only _ and .',
        );
      });

      test('rejects single dot', () {
        expect(
          validateUsername('.'),
          'Username cannot contain only _ and .',
        );
      });
    });

    group('trailing special characters', () {
      test('rejects trailing dot', () {
        expect(
          validateUsername('john.'),
          'Username cannot end with _ or .',
        );
      });

      test('rejects trailing underscore', () {
        expect(
          validateUsername('john_'),
          'Username cannot end with _ or .',
        );
      });

      test('allows leading dot', () {
        expect(validateUsername('.john'), isNull);
      });

      test('allows leading underscore', () {
        expect(validateUsername('_john'), isNull);
      });
    });
  });
}
