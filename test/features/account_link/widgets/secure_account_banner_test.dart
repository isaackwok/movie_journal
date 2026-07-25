import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/account_link/controllers/account_link.dart';
import 'package:movie_journal/features/account_link/widgets/secure_account_banner.dart';

import '../../../helpers/widget_test_setup.dart';

ProviderContainer _container({required bool needsLink, bool promptShown = false}) {
  final container = ProviderContainer(
    overrides: [needsAccountLinkProvider.overrideWithValue(needsLink)],
  );
  if (promptShown) {
    container.read(accountLinkPromptShownProvider.notifier).markShown();
  }
  return container;
}

Future<void> _pumpBanner(
  WidgetTester tester,
  ProviderContainer container, {
  int? journalCount,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: SecureAccountBanner(journalCount: journalCount),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(setUpWidgetTests);
  tearDownAll(tearDownWidgetTests);

  group('SecureAccountBanner', () {
    late ProviderContainer container;

    tearDown(() => container.dispose());

    testWidgets('renders nothing for a normally signed-in user', (
      tester,
    ) async {
      // The common case by a wide margin — nobody who signed in through the
      // login screen holds an anonymous session, so this is what the entire
      // non-bridged user base sees: no banner and no prompt.
      container = _container(needsLink: false);
      await _pumpBanner(tester, container);
      await tester.pumpAndSettle();

      expect(find.byType(SizedBox), findsWidgets);
      expect(find.text('Your account isn\'t secured'), findsNothing);
      expect(find.text('Keep your journals safe'), findsNothing);
      expect(container.read(accountLinkPromptShownProvider), isFalse);
    });

    testWidgets('renders for a bridged user still on an anonymous session', (
      tester,
    ) async {
      container = _container(needsLink: true, promptShown: true);
      await _pumpBanner(tester, container);
      await tester.pumpAndSettle();

      expect(find.text('Your account isn\'t secured'), findsOneWidget);
    });

    testWidgets('opens the sheet once on first build', (tester) async {
      container = _container(needsLink: true);
      await _pumpBanner(tester, container, journalCount: 17);
      await tester.pumpAndSettle();

      expect(find.text('Keep your 17 journals safe'), findsOneWidget);
      expect(container.read(accountLinkPromptShownProvider), isTrue);
    });

    testWidgets('does not re-open the sheet once shown this session', (
      tester,
    ) async {
      // Returning to Home must not re-prompt; the banner carries the message
      // from then on.
      container = _container(needsLink: true, promptShown: true);
      await _pumpBanner(tester, container);
      await tester.pumpAndSettle();

      expect(find.text('Keep your journals safe'), findsNothing);
      expect(find.text('Your account isn\'t secured'), findsOneWidget);
    });

    testWidgets('tapping the banner re-opens the sheet after dismissal', (
      tester,
    ) async {
      // The banner is the persistent route back in, so dismissing the one-time
      // prompt must not be a dead end.
      container = _container(needsLink: true, promptShown: true);
      await _pumpBanner(tester, container, journalCount: 3);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Your account isn\'t secured'));
      await tester.pumpAndSettle();

      expect(find.text('Keep your 3 journals safe'), findsOneWidget);
    });
  });
}
