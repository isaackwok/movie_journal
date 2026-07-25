import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    if (client.auth.currentUser != null) return false;

    // Local-only check, so the overwhelmingly common case (no Firebase session
    // on this device) costs nothing and issues no network call.
    final fbUser = fb.FirebaseAuth.instance.currentUser;
    if (fbUser == null || !fbUser.isAnonymous) return false;

    try {
      final idToken = await fbUser.getIdToken();
      if (idToken == null || idToken.isEmpty) return false;

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
      if (status == 'claimed' || status == 'already_claimed') return true;

      debugPrint('AnonymousBridge: nothing to claim (status=$status)');
    } catch (e) {
      debugPrint('AnonymousBridge: claim failed, falling back to login — $e');
    }

    // Nothing was claimed, so this anonymous session owns no data. Leaving it
    // signed in would send the user to CreateUserScreen and let them build a
    // profile on an account that cannot be signed back into after a reinstall.
    await _signOutQuietly(client);
    return false;
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
