import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  static String? get signInMethod {
    final meta = currentUser?.appMetadata;
    final provider = meta?['provider'];
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

  static Future<AuthResponse> signInWithApple() async {
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

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  // ----------------------------------------------------------------- Google

  /// `clientId` is the iOS OAuth client, `serverClientId` the web one. Supabase
  /// validates the token's `aud` against the Client IDs configured on the
  /// provider, so both must be listed there.
  static Future<AuthResponse> signInWithGoogle({
    required String iosClientId,
    required String webClientId,
  }) async {
    _assertNative('Google');

    final signIn = GoogleSignIn.instance;
    await signIn.initialize(clientId: iosClientId, serverClientId: webClientId);
    final account = await signIn.authenticate();

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthException('Google did not return an ID token');
    }

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  // ---------------------------------------------------------------- session

  static Future<void> signOut() => _client.auth.signOut();

  /// Supabase has no `requires-recent-login`, so reauthentication is not
  /// technically required before deletion. It is kept because the confirm-your-
  /// presence UX is the point, and because cancelling must abort the delete —
  /// matching the existing Firebase flow exactly.
  static Future<void> reauthenticate({
    required String iosClientId,
    required String webClientId,
  }) async {
    final provider = signInMethod;
    switch (provider) {
      case 'apple':
        await signInWithApple();
      case 'google':
        await signInWithGoogle(
          iosClientId: iosClientId,
          webClientId: webClientId,
        );
      default:
        // Anonymous/migrated accounts have no provider to re-auth against.
        return;
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
    if (data is Map && data['deletedJournalIds'] is List) {
      return (data['deletedJournalIds'] as List).cast<String>();
    }
    return const [];
  }
}
