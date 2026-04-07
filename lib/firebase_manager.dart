import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// A class providing Firebase method wrappers for authentication
class FirebaseManager {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Apple using Firebase Auth
  ///
  /// Returns the [UserCredential] on successful sign-in
  /// Throws [FirebaseAuthException] on error
  ///
  /// TEMPORARY: Currently using anonymous sign-in for development.
  /// To enable real Apple Sign-In:
  /// 1. Go to Firebase Console > Authentication > Sign-in method
  /// 2. Enable Apple as a sign-in provider
  /// 3. In Xcode: Select Runner target > Signing & Capabilities > + Capability > Sign in with Apple
  /// 4. Ensure your Apple Developer account is configured
  /// 5. Uncomment the Apple Sign-In code below and remove anonymous auth
  ///
  /// Example Usage:
  /// final firebaseManager = FirebaseManager();
  /// try {
  ///  UserCredential userCredential = await firebaseManager.signInWithApple();
  ///  // Handle successful sign-in
  /// } on FirebaseAuthException catch (e) {
  ///  // Handle Firebase auth errors
  /// } catch (e) {
  ///  // Handle other errors
  /// }
  static Future<UserCredential> signInWithApple() async {
    try {
      // TEMPORARY: Using anonymous auth for development
      // Remove this and uncomment the Apple auth code below when ready
      // return await _auth.signInAnonymously();

      // UNCOMMENT THIS FOR REAL APPLE SIGN-IN:
      final appleProvider = AppleAuthProvider();
      if (kIsWeb) {
        return await _auth.signInWithPopup(appleProvider);
      } else {
        return await _auth.signInWithProvider(appleProvider);
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific error codes if needed
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw FirebaseAuthException(
            code: e.code,
            message:
                'An account already exists with the same email address but different sign-in credentials.',
          );
        case 'invalid-credential':
          throw FirebaseAuthException(
            code: e.code,
            message: 'The credential is malformed or has expired.',
          );
        case 'operation-not-allowed':
          throw FirebaseAuthException(
            code: e.code,
            message:
                'Anonymous/Apple sign-in is not enabled. Please enable it in the Firebase Console.',
          );
        case 'user-disabled':
          throw FirebaseAuthException(
            code: e.code,
            message: 'This user account has been disabled.',
          );
        default:
          rethrow;
      }
    } catch (e) {
      // Handle other errors
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Sign in with Google using Firebase Auth
  ///
  /// Returns the [UserCredential] on successful sign-in
  /// Throws [FirebaseAuthException] on error
  ///
  /// To enable Google Sign-In:
  /// 1. Go to Firebase Console > Authentication > Sign-in method
  /// 2. Enable Google as a sign-in provider
  /// 3. Add your SHA-1 fingerprint for Android (if needed)
  /// 4. Configure OAuth consent screen in Google Cloud Console
  ///
  /// Example Usage:
  /// ```dart
  /// final firebaseManager = FirebaseManager();
  /// try {
  ///   UserCredential userCredential = await firebaseManager.signInWithGoogle();
  ///   // Handle successful sign-in
  /// } on FirebaseAuthException catch (e) {
  ///   // Handle Firebase auth errors
  /// } catch (e) {
  ///   // Handle other errors
  /// }
  /// ```
  static Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web flow using popup
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // Native mobile flow using google_sign_in package
        // Trigger the authentication flow
        final GoogleSignInAccount googleUser =
            await GoogleSignIn.instance.authenticate();

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        // Once signed in, return the UserCredential
        return await FirebaseAuth.instance.signInWithCredential(credential);
        //
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific error codes
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw FirebaseAuthException(
            code: e.code,
            message:
                'An account already exists with the same email address but different sign-in credentials.',
          );
        case 'invalid-credential':
          throw FirebaseAuthException(
            code: e.code,
            message: 'The credential is malformed or has expired.',
          );
        case 'operation-not-allowed':
          throw FirebaseAuthException(
            code: e.code,
            message:
                'Google sign-in is not enabled. Please enable it in the Firebase Console.',
          );
        case 'user-disabled':
          throw FirebaseAuthException(
            code: e.code,
            message: 'This user account has been disabled.',
          );
        case 'popup-closed-by-user':
        case 'sign-in-cancelled':
          rethrow;
        default:
          rethrow;
      }
    } catch (e) {
      // Handle other errors (like network issues or google_sign_in errors)
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  /// Sign out the current user
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Delete the current user account
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user != null) {
      await user.delete();
    }
  }

  /// Re-authenticate the current user using their original sign-in provider.
  ///
  /// Required before destructive actions like account deletion when the user's
  /// last sign-in is too old (Firebase throws `requires-recent-login`).
  ///
  /// Detects the provider from `currentUser.providerData` and runs the
  /// corresponding interactive flow:
  /// - `apple.com` → AppleAuthProvider via `reauthenticateWithProvider` /
  ///   `reauthenticateWithPopup`
  /// - `google.com` → fresh `GoogleSignIn` credential via
  ///   `reauthenticateWithCredential`, or `reauthenticateWithPopup` on web
  ///
  /// Anonymous users are a no-op (no provider to re-auth against).
  ///
  /// Throws [FirebaseAuthException] with code `no-current-user` if no user is
  /// signed in, or `unsupported-provider` if the linked provider is neither
  /// Apple nor Google. Provider-level cancellation propagates from the SDK
  /// (e.g. Apple `canceled`, popup `popup-closed-by-user`, or
  /// `GoogleSignInException` for the Google native flow). Callers must treat
  /// any thrown error as "abort, do not destroy data".
  Future<void> reauthenticate() async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No user is currently signed in.',
      );
    }

    if (user.isAnonymous) return;

    final providerId =
        user.providerData.isNotEmpty
            ? user.providerData.first.providerId
            : null;

    switch (providerId) {
      case 'apple.com':
        final appleProvider = AppleAuthProvider();
        if (kIsWeb) {
          await user.reauthenticateWithPopup(appleProvider);
        } else {
          await user.reauthenticateWithProvider(appleProvider);
        }
        break;
      case 'google.com':
        if (kIsWeb) {
          final googleProvider = GoogleAuthProvider();
          googleProvider.addScope('email');
          googleProvider.addScope('profile');
          await user.reauthenticateWithPopup(googleProvider);
        } else {
          final googleUser = await GoogleSignIn.instance.authenticate();
          final googleAuth = googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            idToken: googleAuth.idToken,
          );
          await user.reauthenticateWithCredential(credential);
        }
        break;
      default:
        throw FirebaseAuthException(
          code: 'unsupported-provider',
          message:
              'Cannot re-authenticate user with provider: ${providerId ?? 'none'}',
        );
    }
  }
}
