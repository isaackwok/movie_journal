import 'package:flutter_test/flutter_test.dart';
import 'package:movie_journal/anonymous_bridge.dart';

/// `AnonymousBridge.attempt()` itself needs a live Firebase session and a
/// Supabase client, so it is covered by the real-device TestFlight test rather
/// than here. What *is* testable — and worth pinning — is the analytics
/// vocabulary, because it is the only visibility the bridge has in release.
void main() {
  group('BridgeOutcome.wire', () {
    test('pins the exact set of reported outcomes', () {
      // These strings are GA dashboard keys. Renaming one does not error; it
      // silently starts a new metric and orphans the history behind the old
      // name. Changing this list should be a deliberate act with the dashboard
      // updated alongside it — hence the literal expectation.
      expect(BridgeOutcome.values.map((o) => o.wire).toSet(), {
        'claimed',
        'already_claimed',
        'nothing_to_claim',
        'no_firebase_session',
        'not_anonymous',
        'no_id_token',
        'failed',
        'already_signed_in',
      });
    });

    test('every outcome is distinct', () {
      // Two outcomes sharing a wire value would silently merge two branches
      // into one bar on the chart — the exact ambiguity this event exists to
      // remove.
      final wires = BridgeOutcome.values.map((o) => o.wire).toList();
      expect(wires.toSet().length, wires.length);
    });

    test('uses snake_case, matching the other analytics params', () {
      final snake = RegExp(r'^[a-z][a-z0-9_]*$');
      for (final outcome in BridgeOutcome.values) {
        expect(
          snake.hasMatch(outcome.wire),
          isTrue,
          reason: '${outcome.name} -> "${outcome.wire}" is not snake_case',
        );
      }
    });

    test('separates the two success outcomes from the failures', () {
      // 'already_claimed' returning true is load-bearing: it means a previous
      // attempt's response was lost, not the claim. If it were ever grouped
      // with the failures, a recovered user would read as a stranded one.
      const succeeds = {BridgeOutcome.claimed, BridgeOutcome.alreadyClaimed};
      expect(succeeds.map((o) => o.wire), {'claimed', 'already_claimed'});
      expect(
        BridgeOutcome.values.where(succeeds.contains).length,
        2,
        reason: 'a third success outcome needs the home.dart branch revisited',
      );
    });
  });
}
