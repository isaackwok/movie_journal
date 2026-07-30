import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of attaching a provider identity to the *current* user.
///
/// Modelled as an enum rather than a thrown exception because two of the three
/// outcomes are ordinary user choices, not failures: backing out of the system
/// prompt, and picking an Apple/Google account that already belongs to someone
/// else's Fink account. Only genuine faults (network, misconfiguration) throw.
enum IdentityLinkOutcome {
  /// The identity now belongs to this user; they can sign in with it again.
  linked,

  /// The user dismissed the Apple/Google prompt. Nothing changed.
  cancelled,

  /// The chosen Apple/Google account is already an identity on a *different*
  /// Supabase user, so it cannot also be attached here. See
  /// [SupabaseAuthManager.linkAppleIdentity] for why this is not merged
  /// automatically.
  alreadyLinkedToAnotherAccount,
}

/// Authentication, replacing `FirebaseManager`.
///
/// Native-only by decision 9: both providers use `signInWithIdToken`, where
/// Supabase merely *verifies* an Apple/Google-signed token (public JWKS + `aud`
/// match + nonce). No client secret is involved, which is why no Apple Services
/// ID or `.p8` is needed on the Supabase side.
///
/// Note this is a change of *flow*, not just of SDK: the app previously used
/// `FirebaseAuth.signInWithProvider`, Firebase's web OAuth redirect flow, which
/// authenticated through a Services ID. Apple scopes `sub` and private-relay
/// email to the developer *team* (3U9565WWM2), not the client id, so user
/// identifiers carry across unchanged.
class SupabaseAuthManager {
  static SupabaseClient get _client => Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;

  static Session? get currentSession => _client.auth.currentSession;

  /// Mirrors the old `authStateChanges` shape so `home.dart` keeps streaming
  /// `User?` and does not need to learn about Supabase sessions.
  static Stream<User?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((event) => event.session?.user);

  /// Which provider the current user signed in with, for analytics parity with
  /// the old `sign_in_method` property.
  static String? get signInMethod => providerOf(currentUser);

  /// Same, for a `User` already in hand. Auth-state listeners should prefer
  /// this over [signInMethod]: they receive the user with the event, whereas
  /// `currentUser` is read back off the client and can lag the emission.
  static String? providerOf(User? user) {
    final provider = user?.appMetadata['provider'];
    return provider is String ? provider : null;
  }

  // ------------------------------------------------------------------ nonce

  /// Apple and Google bind the returned ID token to a nonce to stop replay.
  /// The *raw* nonce goes to Supabase and the SHA-256 hash goes to Apple;
  /// sending the same value to both defeats the point, so the two are kept
  /// deliberately distinct below.
  static String generateRawNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  static void _assertNative(String provider) {
    if (kIsWeb) {
      throw UnsupportedError(
        '$provider sign-in is native-only (decision 9). Web would need an '
        'Apple Services ID + .p8 and the OAuth redirect flow. Failing loudly '
        'here beats surfacing an opaque provider error at runtime.',
      );
    }
  }

  // ------------------------------------------------------------------ Apple

  /// Drives the native Apple prompt and returns the token pair Supabase needs.
  ///
  /// Shared by [signInWithApple] and [linkAppleIdentity]: both hit the same
  /// `/token?grant_type=id_token` endpoint and both must bind the *raw* nonce
  /// that was hashed into the Apple request, so the acquisition has to be
  /// identical or the nonce check fails on one path and not the other.
  static Future<({String idToken, String rawNonce})> _appleIdToken() async {
    _assertNative('Apple');
    final rawNonce = generateRawNonce();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: _sha256(rawNonce),
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException('Apple did not return an identity token');
    }

    return (idToken: idToken, rawNonce: rawNonce);
  }

  static Future<AuthResponse> signInWithApple() async {
    final apple = await _appleIdToken();
    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: apple.idToken,
      nonce: apple.rawNonce,
    );
  }

  // ----------------------------------------------------------------- Google

  /// `clientId` is the iOS OAuth client, `serverClientId` the web one. Supabase
  /// validates the token's `aud` against the Client IDs configured on the
  /// provider, so both must be listed there.
  ///
  /// Both ids default to `.env`; they stay injectable so the flow can be
  /// exercised in tests without loading dotenv.
  static Future<GoogleSignInAccount> _googleAccount({
    String? iosClientId,
    String? webClientId,
  }) async {
    _assertNative('Google');

    final signIn = GoogleSignIn.instance;
    await signIn.initialize(
      clientId: iosClientId ?? dotenv.env['GOOGLE_IOS_CLIENT_ID']!,
      serverClientId: webClientId ?? dotenv.env['GOOGLE_WEB_CLIENT_ID']!,
    );
    return signIn.authenticate();
  }

  static String _googleIdToken(GoogleSignInAccount account) {
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthException('Google did not return an ID token');
    }
    return idToken;
  }

  static Future<AuthResponse> signInWithGoogle({
    String? iosClientId,
    String? webClientId,
  }) async {
    final account = await _googleAccount(
      iosClientId: iosClientId,
      webClientId: webClientId,
    );

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: _googleIdToken(account),
    );
  }

  // -------------------------------------------------------- identity linking

  /// Whether [user] holds a session with no credential they could ever sign
  /// back in with — i.e. the app is "signed in" but a reinstall would lose the
  /// account for good.
  ///
  /// The only way to reach this state in this app is the pre-migration
  /// anonymous bridge (see `AnonymousBridge`), which mints a Supabase anonymous
  /// session to hang the claimed journals off. `is_anonymous` is the same flag
  /// `migration/bridge_status.ts` counts as
  /// `claimed_still_on_anonymous_session`, so the in-app prompt and the cutover
  /// monitor are reading one source of truth rather than two that can disagree.
  static bool needsIdentityLink(User? user) => user?.isAnonymous ?? false;

  /// True when [error] means "that Apple/Google account is already an identity
  /// on some other Supabase user".
  ///
  /// Classified here rather than at the call site so the UI layer never has to
  /// import gotrue error codes to tell a conflict from a real fault.
  static bool isIdentityConflict(Object error) =>
      error is AuthException &&
      error.code == ErrorCode.identityAlreadyExists.code;

  /// Attaches an Apple identity to the **current** user.
  ///
  /// Uses `linkIdentityWithIdToken`, not the `linkIdentity()` browser flow: the
  /// latter needs an OAuth client secret, which this project deliberately never
  /// provisioned (native-only, see the class doc) and which probing confirms is
  /// absent — `GET /user/identities/authorize?provider=google` answers
  /// `"Unsupported provider: missing OAuth secret"`. The ID-token variant goes
  /// through the same native path as [signInWithApple], so it needs nothing new
  /// on the Supabase side beyond *Allow manual linking*, enabled 2026-07-25.
  ///
  /// Linking attaches to the current session, so `auth.uid()` does not change
  /// and journals stay put — the whole reason this beats a sign-in-and-migrate
  /// flow.
  ///
  /// A conflict is reported, not resolved: merging two accounts would need a
  /// server-side move of journals plus a rule for which profile survives, and
  /// the population that can hit it is small (they must have signed up
  /// separately *and* still hold the old Firebase session). The
  /// `account_link_conflict` analytics event exists to size that population
  /// before anyone builds the merge.
  static Future<IdentityLinkOutcome> linkAppleIdentity() async {
    return _linkIdentity(() async {
      final apple = await _appleIdToken();
      return _client.auth.linkIdentityWithIdToken(
        provider: OAuthProvider.apple,
        idToken: apple.idToken,
        nonce: apple.rawNonce,
      );
    });
  }

  /// Attaches a Google identity to the **current** user. See
  /// [linkAppleIdentity] for why this uses the ID-token variant.
  static Future<IdentityLinkOutcome> linkGoogleIdentity({
    String? iosClientId,
    String? webClientId,
  }) async {
    return _linkIdentity(() async {
      final account = await _googleAccount(
        iosClientId: iosClientId,
        webClientId: webClientId,
      );
      return _client.auth.linkIdentityWithIdToken(
        provider: OAuthProvider.google,
        idToken: _googleIdToken(account),
        accessToken: await _googleAccessToken(account),
      );
    });
  }

  /// Best-effort OAuth access token for the linked Google account.
  ///
  /// `authorizationForScopes` returns null rather than prompting when consent
  /// would be needed, which is what makes this safe to call inline: linking
  /// must not turn into a second, unexplained permission dialog. GoTrue treats
  /// `access_token` as optional on the id_token grant — the existing
  /// [signInWithGoogle] omits it entirely — so a null here still links.
  static Future<String?> _googleAccessToken(GoogleSignInAccount account) async {
    try {
      final authz = await account.authorizationClient.authorizationForScopes(
        const ['email', 'profile'],
      );
      return authz?.accessToken;
    } catch (e) {
      debugPrint('linkGoogleIdentity: no access token available — $e');
      return null;
    }
  }

  static Future<IdentityLinkOutcome> _linkIdentity(
    Future<AuthResponse> Function() link,
  ) async {
    try {
      final response = await cancellable(link);
      return response == null
          ? IdentityLinkOutcome.cancelled
          : IdentityLinkOutcome.linked;
    } catch (e) {
      if (isIdentityConflict(e)) {
        return IdentityLinkOutcome.alreadyLinkedToAnotherAccount;
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------- session

  static Future<void> signOut() => _client.auth.signOut();

  /// Supabase has no `requires-recent-login`, so reauthentication is not
  /// technically required before deletion. It is kept because the confirm-your-
  /// presence UX is the point, and because cancelling must abort the delete —
  /// matching the existing Firebase flow exactly.
  /// Returns `true` if the user re-authenticated, `false` if they backed out
  /// of the provider prompt. Real failures still throw.
  static Future<bool> reauthenticate({
    String? iosClientId,
    String? webClientId,
  }) async {
    final provider = signInMethod;
    if (provider != 'apple' && provider != 'google') {
      // Anonymous/migrated accounts have no provider to re-auth against, so
      // there is nothing to confirm — treat as already confirmed.
      return true;
    }

    final confirmed = await cancellable(
      () => provider == 'apple'
          ? signInWithApple()
          : signInWithGoogle(
              iosClientId: iosClientId,
              webClientId: webClientId,
            ),
    );
    return confirmed != null;
  }

  /// Runs a native provider flow, mapping a dismissed system prompt to `null`.
  ///
  /// Callers get a null rather than having to catch provider exceptions
  /// themselves: the native flow throws SDK-specific types
  /// (`SignInWithAppleAuthorizationException`, `GoogleSignInException`) where
  /// the old Firebase flow threw one `FirebaseAuthException` for both. Widening
  /// that here keeps both SDKs out of the UI layer.
  ///
  /// Public because UI callers need the same cancelled-vs-failed split — e.g.
  /// `LoginScreen` wraps [signInWithApple]/[signInWithGoogle] with this so a
  /// dismissed prompt stays silent while a real fault gets an error toast.
  static Future<T?> cancellable<T>(Future<T?> Function() action) async {
    try {
      return await action();
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  /// Deletes the account server-side. Returns the deleted journal ids so the
  /// caller can log per-journal analytics, preserving the Firebase behaviour.
  ///
  /// The edge function deletes the auth user, which cascades to profiles and
  /// journals and fires the tombstone triggers — so unlike the old client-side
  /// flow there is no window in which data is gone but the account remains.
  static Future<List<String>> deleteAccount() async {
    final res = await _client.functions.invoke('delete-account');
    final data = res.data;
    final ids = (data is Map && data['deletedJournalIds'] is List)
        ? (data['deletedJournalIds'] as List).cast<String>()
        : const <String>[];

    // The function deletes the user server-side, but this device still holds
    // the issued session. Firebase's client-side `currentUser.delete()` used
    // to clear it as a side effect; here it must be explicit, or the app keeps
    // believing it is signed in as a user that no longer exists.
    await signOut();
    return ids;
  }
}
