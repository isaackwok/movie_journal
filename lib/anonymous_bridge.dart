import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:movie_journal/analytics_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Every way [AnonymousBridge.attempt] can end, reported to analytics as the
/// `outcome` param of `anonymous_bridge`.
///
/// The bridge runs on a device we cannot inspect and previously only
/// `debugPrint`ed, which is invisible in release — so a failure surfaced only
/// when someone said their journals were gone. These are the counters that make
/// the remaining unclaimed accounts a number instead of an anecdote.
///
/// [wire] is stated explicitly rather than derived from `name`: these strings
/// are dashboard keys, and a Dart-side rename must not silently split a metric.
enum BridgeOutcome {
  /// Journals recovered. Should total at most the size of the anonymous cohort.
  claimed('claimed'),

  /// Also success — a previous attempt's response was lost, not the claim.
  alreadyClaimed('already_claimed'),

  /// Reached the Edge Function; it had nothing for this uid.
  nothingToClaim('nothing_to_claim'),

  /// No Firebase session on the device. Expected for every genuinely new user,
  /// and *indistinguishable from* a bridged user whose session was destroyed by
  /// a reinstall — which is exactly why it is counted: a rise here around a
  /// build rollout is the signal that people are being stranded.
  noFirebaseSession('no_firebase_session'),

  /// A Firebase session exists but is federated, so the old app's data is not
  /// reachable this way. Should be ~0; anything else means the cohort was
  /// mis-modelled.
  notAnonymous('not_anonymous'),

  /// Firebase refused to mint an ID token — usually a dead refresh token.
  noIdToken('no_id_token'),

  /// Network, Edge Function, or Supabase failure. Retryable next launch.
  failed('failed'),

  /// A Supabase session already existed, so there was nothing to bridge.
  alreadySignedIn('already_signed_in');

  const BridgeOutcome(this.wire);

  final String wire;
}

/// Recovers journals belonging to pre-migration Firebase **anonymous** accounts
/// (plan decision 10).
///
/// 14 accounts were created by the old `signInAnonymously()` call and own 54
/// journals — 46% of production data. They have no email and no provider, so
/// the migration's two normal linking paths cannot identify them: email
/// auto-linking has nothing to match, and `claim_migrated_data()` joins on
/// `auth.identities`, which an anonymous user has none of.
///
/// The one credential that still proves ownership is the Firebase anonymous
/// session sitting on the device. This exchanges it, via the `claim-anonymous`
/// Edge Function, for the pre-created placeholder row's data.
///
/// This is the sole reason `firebase_auth` outlives the rest of the Firebase
/// data layer; it can be dropped at the Firestore freeze.
///
/// Inherent limit, unchanged by the migration: a user who reinstalled the app
/// lost that anonymous account before any of this existed.
class AnonymousBridge {
  /// Returns `true` if a claim succeeded and the caller now holds a Supabase
  /// session owning the migrated data.
  ///
  /// Never throws: a failure here must not block a normal sign-in. Callers
  /// fall through to the login screen when this returns `false`.
  static Future<bool> attempt() async {
    final client = Supabase.instance.client;

    // Already signed in — nothing to bridge, and signing in anonymously again
    // would strand this session behind a second, empty one.
    if (client.auth.currentUser != null) {
      return _report(BridgeOutcome.alreadySignedIn, claimed: false);
    }

    // Local-only check, so the overwhelmingly common case (no Firebase session
    // on this device) costs nothing and issues no network call.
    final fbUser = fb.FirebaseAuth.instance.currentUser;
    if (fbUser == null) {
      return _report(BridgeOutcome.noFirebaseSession, claimed: false);
    }
    if (!fbUser.isAnonymous) {
      return _report(BridgeOutcome.notAnonymous, claimed: false);
    }

    BridgeOutcome outcome;
    try {
      final idToken = await fbUser.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        // Nothing was signed in yet, so there is no session to clean up here.
        return _report(BridgeOutcome.noIdToken, claimed: false);
      }

      // A real auth.users row must exist before any journal can point at it:
      // journals.user_id is a FK to auth.users. Requires anonymous sign-ins to
      // be enabled on the project.
      await client.auth.signInAnonymously();

      final res = await client.functions.invoke(
        'claim-anonymous',
        body: {'firebaseIdToken': idToken},
      );
      final data = res.data;
      final status = data is Map ? data['status'] : null;

      // 'already_claimed' is a success: the previous attempt's response was
      // lost in transit, not the claim itself.
      if (status == 'claimed') {
        return _report(BridgeOutcome.claimed, claimed: true);
      }
      if (status == 'already_claimed') {
        return _report(BridgeOutcome.alreadyClaimed, claimed: true);
      }

      outcome = BridgeOutcome.nothingToClaim;
      debugPrint('AnonymousBridge: nothing to claim (status=$status)');
    } catch (e) {
      outcome = BridgeOutcome.failed;
      debugPrint('AnonymousBridge: claim failed, falling back to login — $e');
    }

    // Nothing was claimed, so this anonymous session owns no data. Leaving it
    // signed in would send the user to CreateUserScreen and let them build a
    // profile on an account that cannot be signed back into after a reinstall.
    await _signOutQuietly(client);
    return _report(outcome, claimed: false);
  }

  /// Single exit point for reporting, so no branch can be added without one.
  ///
  /// Returns [claimed] purely so call sites read as `return _report(...)` —
  /// which is what makes an unreported early return visually obvious.
  static bool _report(BridgeOutcome outcome, {required bool claimed}) {
    debugPrint('AnonymousBridge: ${outcome.wire}');
    AnalyticsManager.logAnonymousBridge(outcome: outcome.wire);
    return claimed;
  }

  static Future<void> _signOutQuietly(SupabaseClient client) async {
    if (client.auth.currentUser == null) return;
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('AnonymousBridge: sign-out after failed claim failed — $e');
    }
  }
}
