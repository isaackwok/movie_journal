import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/login/screens/create_user.dart';

import '../../../helpers/widget_test_setup.dart';

// Note: create_user.dart includes AnalyticsManager calls (screen view + sign_up event)
// and is now a ConsumerStatefulWidget so it can invalidate currentUsernameProvider
// after onboarding writes the user doc. AnalyticsManager is a no-op without Firebase,
// and the Firestore calls in _handleStartJournaling only fire on button press, so the
// rendering tests below mount the screen safely.

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

  group('CreateUserScreen rendering', () {
    setUpAll(() => setUpWidgetTests());
    tearDownAll(() => tearDownWidgetTests());

    Widget buildSubject() {
      return const ProviderScope(
        child: MaterialApp(home: CreateUserScreen()),
      );
    }

    testWidgets('mounts inside a ProviderScope without throwing',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(CreateUserScreen), findsOneWidget);
    });

    testWidgets('renders the Pick a name title', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('Pick a name.'), findsOneWidget);
    });

    testWidgets('renders the username input field', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders the Start Journaling button', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(
        find.widgetWithText(ElevatedButton, 'Start Journaling'),
        findsOneWidget,
      );
    });
  });
}
