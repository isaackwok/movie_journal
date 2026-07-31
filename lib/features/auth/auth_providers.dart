import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_journal/anonymous_bridge.dart';
import 'package:movie_journal/supabase_auth_manager.dart';
import 'package:movie_journal/supabase_db_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider that streams Supabase authentication state changes
/// Returns the current User or null if not authenticated
final authStateProvider = StreamProvider<User?>((ref) {
  return SupabaseAuthManager.authStateChanges;
});

/// Provider that fetches the current user's username from `profiles`
final currentUsernameProvider = FutureProvider<String>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) {
    return 'Guest';
  }

  final userData = await SupabaseDbManager().getUser(authState.id);
  return userData?['username'] ?? 'User';
});

/// Runs the pre-migration anonymous-account bridge once per app start, before
/// a signed-out user is offered the login screen. See [AnonymousBridge].
///
/// Returns `false` fast (no network) for the common case of a device with no
/// Firebase anonymous session.
final anonymousBridgeProvider = FutureProvider<bool>((ref) async {
  return AnonymousBridge.attempt();
});

/// Whether the signed-in user already has a `profiles` row — i.e. whether to
/// show HomeScreen or CreateUserScreen.
///
/// A missing profile is ambiguous during the migration window. It means either
/// a genuinely new user, OR a migrated user whose sign-in did not attach to
/// their pre-created account (their provider email changed since the export,
/// so Supabase's email auto-linking had nothing to match on). The second case
/// is why `claim_migrated_data()` exists: it matches on the provider `sub` via
/// `firebase_identity_map` and re-points the pre-created profile + journals to
/// the caller.
///
/// This lives in a provider, not in the `FutureBuilder` it replaced, because
/// `FutureBuilder(future: <inline expression>)` re-evaluates on every rebuild.
/// The claim RPC must run at most once per sign-in; Riverpod's caching is what
/// makes that true.
final hasProfileProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return false;

  final db = SupabaseDbManager();
  if (await db.userExists(user.id)) return true;

  // No profile row. Attempt the claim, then re-check: `claimMigratedData`
  // returns 'no_mapping' for a genuinely new user (not an error), and
  // 'claimed' after re-pointing a migrated user's data to this account.
  // Fail CLOSED, deliberately. Swallowing this and returning false would send
  // the user to CreateUserScreen, and a migrated user who creates a second
  // profile there strands their imported journals under the pre-created
  // account — recoverable only by hand. A surfaced error is retryable; a
  // duplicate profile is not, so the error is the better failure.
  await db.claimMigratedData();
  return db.userExists(user.id);
});
