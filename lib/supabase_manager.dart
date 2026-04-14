import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider ids we speak natively. Values mirror Firebase's provider IDs so
/// callers (e.g. analytics) don't need to change their strings.
class AuthProviderId {
  static const apple = 'apple.com';
  static const google = 'google.com';
  static const anonymous = 'anonymous';
}

/// A framework-agnostic representation of the signed-in user. Used throughout
/// the app in place of Firebase's `User` class.
class AppUser {
  final String id;
  final String providerId;
  final bool isAnonymous;

  const AppUser({
    required this.id,
    required this.providerId,
    required this.isAnonymous,
  });

  factory AppUser.fromSupabase(User user) {
    final provider = mapSupabaseProvider(
      appMetadata: user.appMetadata,
      isAnonymous: user.isAnonymous ?? false,
    );
    return AppUser(
      id: user.id,
      providerId: provider,
      isAnonymous: user.isAnonymous ?? provider == AuthProviderId.anonymous,
    );
  }
}

/// Pure mapping from a Supabase user's `app_metadata` to the app's
/// provider id vocabulary (which mirrors Firebase's `apple.com`/`google.com`
/// strings). Factored out of [AppUser.fromSupabase] so it can be unit-tested
/// without constructing a full Supabase [User] instance.
String mapSupabaseProvider({
  required Map<String, dynamic> appMetadata,
  required bool isAnonymous,
}) {
  final fromMetadata = appMetadata['provider'];
  if (fromMetadata is String && fromMetadata.isNotEmpty) {
    switch (fromMetadata) {
      case 'apple':
        return AuthProviderId.apple;
      case 'google':
        return AuthProviderId.google;
      default:
        return fromMetadata;
    }
  }
  if (isAnonymous) return AuthProviderId.anonymous;
  return 'unknown';
}

/// Raised for predictable auth-flow conditions. Carries a [code] so callers can
/// treat cancellations differently from hard errors without pattern-matching
/// on messages.
class AppAuthException implements Exception {
  final String code;
  final String? message;

  const AppAuthException({required this.code, this.message});

  @override
  String toString() => 'AppAuthException($code): ${message ?? ''}';
}

/// Codes that should be treated as "user cancelled — silently abort" by
/// callers. Matches the set previously handled around Firebase Auth.
const Set<String> cancelledAuthCodes = {
  'canceled',
  'cancelled',
  'sign-in-cancelled',
  'popup-closed-by-user',
  'web-context-canceled',
};

/// Wraps Supabase Auth. Static methods preserve the call-site shape that the
/// prior FirebaseManager had (LoginScreen invokes `signInWithGoogle()` etc.
/// statically); instance methods cover per-user operations (`currentUser`,
/// `reauthenticate`, `deleteAccount`).
class SupabaseManager {
  static SupabaseClient get _client => Supabase.instance.client;

  /// The current signed-in user, or null.
  AppUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return AppUser.fromSupabase(user);
  }

  /// Emits on login, logout, token refresh. Mapped to [AppUser] (or null).
  Stream<AppUser?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((event) {
        final user = event.session?.user;
        return user == null ? null : AppUser.fromSupabase(user);
      });

  /// Sign in with Apple. On native iOS uses the native Apple ID credential
  /// flow (required for Store Review guidelines). On web and Android falls
  /// back to the OAuth redirect flow.
  static Future<void> signInWithApple() async {
    try {
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
        await _client.auth.signInWithOAuth(OAuthProvider.apple);
        return;
      }

      final rawNonce = _generateNonce();
      final hashedNonce =
          sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AppAuthException(
          code: 'invalid-credential',
          message: 'Apple Sign-In did not return an identityToken.',
        );
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AppAuthException(code: 'canceled');
      }
      throw AppAuthException(code: e.code.name, message: e.message);
    } on AuthException catch (e) {
      throw AppAuthException(code: 'auth-error', message: e.message);
    }
  }

  /// Sign in with Google. On web uses the OAuth redirect/popup flow. On
  /// native uses the `google_sign_in` package to fetch an ID token and
  /// exchanges it with Supabase via `signInWithIdToken`.
  static Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        await _client.auth.signInWithOAuth(OAuthProvider.google);
        return;
      }

      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw const AppAuthException(
          code: 'invalid-credential',
          message: 'Google Sign-In did not return an idToken.',
        );
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } on GoogleSignInException catch (e) {
      // The native SDK surfaces a `canceled` code when the user dismisses the
      // system sheet. Normalize it so callers see the same cancellation token
      // as the Apple flow.
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AppAuthException(code: 'canceled');
      }
      throw AppAuthException(code: e.code.name, message: e.description);
    } on AuthException catch (e) {
      throw AppAuthException(code: 'auth-error', message: e.message);
    }
  }

  /// Sign out the current user.
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Re-run the provider-specific sign-in to obtain a fresh session. Supabase
  /// doesn't have Firebase's `requires-recent-login` concept, but the app
  /// still wants a just-confirmed session before destructive actions like
  /// account deletion. Provider cancellations propagate as
  /// [AppAuthException] with a code in [cancelledAuthCodes].
  Future<void> reauthenticate() async {
    final user = currentUser;
    if (user == null) {
      throw const AppAuthException(
        code: 'no-current-user',
        message: 'No user is currently signed in.',
      );
    }
    if (user.isAnonymous) return;

    switch (user.providerId) {
      case AuthProviderId.apple:
        await signInWithApple();
        break;
      case AuthProviderId.google:
        await signInWithGoogle();
        break;
      default:
        throw AppAuthException(
          code: 'unsupported-provider',
          message:
              'Cannot re-authenticate user with provider: ${user.providerId}',
        );
    }
  }

  /// Delete the current user's auth account.
  ///
  /// The Supabase client SDK cannot delete its own user — only the service
  /// role can call `auth.admin.deleteUser`. This method invokes the
  /// `delete-account` edge function (see
  /// `supabase/functions/delete-account/index.ts`) which verifies the caller
  /// via their JWT and performs the delete server-side.
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    final response = await _client.functions.invoke('delete-account');
    if (response.status != 200) {
      throw AppAuthException(
        code: 'delete-failed',
        message: 'delete-account function returned ${response.status}',
      );
    }
    // Clear the local session after the server-side delete so the auth state
    // stream emits null.
    await _client.auth.signOut();
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
