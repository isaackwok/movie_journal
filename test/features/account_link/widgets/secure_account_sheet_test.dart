import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/features/account_link/controllers/account_link.dart';
import 'package:movie_journal/features/account_link/widgets/secure_account_sheet.dart';
import 'package:movie_journal/supabase_auth_manager.dart';

import '../../../helpers/widget_test_setup.dart';

/// Stands in for the real service, which needs a live `Supabase.instance` plus
/// two provider SDKs. Faking it is what makes the conflict branch testable at
/// all — reproducing it for real would take two actual Apple/Google accounts.
class _FakeAccountLinkService implements AccountLinkService {
  _FakeAccountLinkService({this.outcome, this.error});

  final IdentityLinkOutcome? outcome;
  final Object? error;

  int appleCalls = 0;
  int googleCalls = 0;

  Future<IdentityLinkOutcome> _respond() async {
    if (error != null) throw error!;
    return outcome!;
  }

  @override
  Future<IdentityLinkOutcome> linkApple() {
    appleCalls++;
    return _respond();
  }

  @override
  Future<IdentityLinkOutcome> linkGoogle() {
    googleCalls++;
    return _respond();
  }
}

/// Pumps a host screen with a button that opens the sheet, so the sheet sits on
/// a real route and `Navigator.pop` has something to pop.
Future<void> _openSheet(
  WidgetTester tester, {
  required _FakeAccountLinkService service,
  int? journalCount,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [accountLinkServiceProvider.overrideWithValue(service)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  SecureAccountSheet.show(context, journalCount: journalCount),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// The success path fires a toast, and `fluttertoast` chains timers (~2s show
/// plus fade). Without draining them the test fails with "Timer still pending".
Future<void> _drainToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(setUpWidgetTests);
  tearDownAll(tearDownWidgetTests);

  group('copy', () {
    testWidgets('names the journal count when known', (tester) async {
      await _openSheet(
        tester,
        service: _FakeAccountLinkService(outcome: IdentityLinkOutcome.linked),
        journalCount: 17,
      );

      expect(find.text('Keep your 17 journals safe'), findsOneWidget);
    });

    testWidgets('singularises a count of one', (tester) async {
      await _openSheet(
        tester,
        service: _FakeAccountLinkService(outcome: IdentityLinkOutcome.linked),
        journalCount: 1,
      );

      expect(find.text('Keep your 1 journal safe'), findsOneWidget);
    });

    testWidgets('falls back to generic copy without a count', (tester) async {
      await _openSheet(
        tester,
        service: _FakeAccountLinkService(outcome: IdentityLinkOutcome.linked),
      );

      expect(find.text('Keep your journals safe'), findsOneWidget);
    });

    testWidgets('offers both providers', (tester) async {
      await _openSheet(
        tester,
        service: _FakeAccountLinkService(outcome: IdentityLinkOutcome.linked),
      );

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
    });
  });

  group('linking', () {
    testWidgets('Apple button links via the Apple path', (tester) async {
      final service = _FakeAccountLinkService(
        outcome: IdentityLinkOutcome.linked,
      );
      await _openSheet(tester, service: service);

      await tester.tap(find.text('Continue with Apple'));
      await tester.pumpAndSettle();

      expect(service.appleCalls, 1);
      expect(service.googleCalls, 0);
      await _drainToast(tester);
    });

    testWidgets('Google button links via the Google path', (tester) async {
      final service = _FakeAccountLinkService(
        outcome: IdentityLinkOutcome.linked,
      );
      await _openSheet(tester, service: service);

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(service.googleCalls, 1);
      expect(service.appleCalls, 0);
      await _drainToast(tester);
    });

    testWidgets('closes on success', (tester) async {
      await _openSheet(
        tester,
        service: _FakeAccountLinkService(outcome: IdentityLinkOutcome.linked),
      );

      await tester.tap(find.text('Continue with Apple'));
      await tester.pumpAndSettle();

      expect(find.text('Continue with Apple'), findsNothing);
      await _drainToast(tester);
    });

    testWidgets('stays open when the user cancels the system prompt', (
      tester,
    ) async {
      // Backing out of the Apple/Google sheet should leave them exactly where
      // they were; closing would read as the app having done something.
      await _openSheet(
        tester,
        service: _FakeAccountLinkService(
          outcome: IdentityLinkOutcome.cancelled,
        ),
      );

      await tester.tap(find.text('Continue with Apple'));
      await tester.pumpAndSettle();

      expect(find.text('Continue with Apple'), findsOneWidget);
    });

    testWidgets('re-enables the buttons after a cancel', (tester) async {
      // The busy flag is cleared in a `finally`. If it leaked, a single cancel
      // would leave the sheet permanently dead and the user with no way to
      // secure the account.
      final service = _FakeAccountLinkService(
        outcome: IdentityLinkOutcome.cancelled,
      );
      await _openSheet(tester, service: service);

      await tester.tap(find.text('Continue with Apple'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue with Apple'));
      await tester.pumpAndSettle();

      expect(service.appleCalls, 2);
    });

    testWidgets('stays open and explains when the identity is taken', (
      tester,
    ) async {
      await _openSheet(
        tester,
        service: _FakeAccountLinkService(
          outcome: IdentityLinkOutcome.alreadyLinkedToAnotherAccount,
        ),
      );

      await tester.tap(find.text('Continue with Apple'));
      await tester.pumpAndSettle();

      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(
        find.textContaining('already attached to another Fink account'),
        findsOneWidget,
      );
      // Points at the provider they have *not* tried yet.
      expect(find.textContaining('Try Google instead'), findsOneWidget);
    });

    testWidgets('clears a stale conflict notice on the next attempt', (
      tester,
    ) async {
      // Otherwise a Google attempt after an Apple conflict shows a warning
      // about Apple while Google is mid-flight.
      await _openSheet(
        tester,
        service: _FakeAccountLinkService(
          outcome: IdentityLinkOutcome.alreadyLinkedToAnotherAccount,
        ),
      );

      await tester.tap(find.text('Continue with Apple'));
      await tester.pumpAndSettle();
      expect(find.textContaining('That Apple account'), findsOneWidget);

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(find.textContaining('That Apple account'), findsNothing);
      expect(find.textContaining('That Google account'), findsOneWidget);
    });

    testWidgets('survives a thrown error and stays usable', (tester) async {
      final service = _FakeAccountLinkService(error: Exception('network down'));
      await _openSheet(tester, service: service);

      await tester.tap(find.text('Continue with Apple'));
      await tester.pumpAndSettle();
      expect(find.text('Continue with Apple'), findsOneWidget);

      // The error toast is an overlay entry drawn over the sheet, and it sits
      // right on top of the buttons. Letting it expire first is what a real
      // user waits out anyway; skipping it makes the retry tap miss.
      await _drainToast(tester);

      await tester.tap(find.text('Continue with Apple'));
      await tester.pumpAndSettle();
      expect(service.appleCalls, 2);

      await _drainToast(tester);
    });
  });

  testWidgets('"Not now" dismisses without linking', (tester) async {
    final service = _FakeAccountLinkService(
      outcome: IdentityLinkOutcome.linked,
    );
    await _openSheet(tester, service: service);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Continue with Apple'), findsNothing);
    expect(service.appleCalls, 0);
    expect(service.googleCalls, 0);
  });
}
