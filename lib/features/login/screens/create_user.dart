import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:movie_journal/analytics_manager.dart';
import 'package:movie_journal/features/home/screens/home.dart';
import 'package:movie_journal/shared_preferences_manager.dart';
import 'package:movie_journal/supabase_auth_manager.dart';
import 'package:movie_journal/supabase_db_manager.dart';

/// Validate username with the following rules:
/// 1. Only alphabets (a-z), numbers (0-9), underscore (_) and fullstop (.) allowed
/// 2. Cannot contain only (_) and (.)
/// 3. Cannot end with _ or .
/// 4. At most 30 characters
///
/// Rule 4 mirrors the `profiles_username_shape` CHECK constraint. It exists so
/// the ceiling is reported here, with a message, rather than by Postgres as an
/// unhandled 23514 — `createUser()` maps only 23505. The other three rules are
/// deliberately stricter than the constraint: this function owns the product
/// rule, the database only owns the backstop.
///
/// Returns an error message string if invalid, or null if valid.
String? validateUsername(String username) {
  if (username.isEmpty) {
    return 'Username cannot be empty';
  }

  // Rule 1: Only allow a-z, 0-9, _, .
  final validCharactersRegex = RegExp(r'^[a-zA-Z0-9_.]+$');
  if (!validCharactersRegex.hasMatch(username)) {
    return 'Username can only contain letters, numbers, _ and .';
  }

  // Rule 2: Cannot contain only _ and .
  final onlySpecialCharsRegex = RegExp(r'^[_.]+$');
  if (onlySpecialCharsRegex.hasMatch(username)) {
    return 'Username cannot contain only _ and .';
  }

  // Rule 3: Cannot end with _ or .
  if (username.endsWith('.') || username.endsWith('_')) {
    return 'Username cannot end with _ or .';
  }

  // Rule 4: length ceiling — must not exceed profiles_username_shape,
  // or the DB rejects it as an unhandled 23514.
  if (username.length > 30) {
    return 'Username cannot be longer than 30 characters';
  }

  return null; // Valid
}

class CreateUserScreen extends ConsumerStatefulWidget {
  const CreateUserScreen({super.key});

  @override
  ConsumerState<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends ConsumerState<CreateUserScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final SupabaseDbManager _db = SupabaseDbManager();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    AnalyticsManager.logScreenView('CreateUser');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  /// Check whether the username is free.
  ///
  /// RLS stops clients from scanning `profiles`, so this goes through the
  /// `username_available` SECURITY DEFINER RPC, which leaks only a boolean.
  /// It compares case-insensitively, matching the `lower(username)` unique
  /// index — the old Firestore equality query did not, so "Isaac" could pass
  /// this check while "isaac" already existed.
  Future<bool> _checkUsernameAvailable(String username) async {
    try {
      return await _db.usernameAvailable(username);
    } catch (e) {
      throw Exception('Failed to check username availability: $e');
    }
  }

  /// Handle the Start Journaling button press
  Future<void> _handleStartJournaling() async {
    final username = _usernameController.text.trim();

    // Validate username format
    final validationError = validateUsername(username);
    if (validationError != null) {
      Fluttertoast.showToast(
        msg: validationError,
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if username already exists
      final available = await _checkUsernameAvailable(username);
      if (!available) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Username already taken. Please choose another one.',
            backgroundColor: Colors.red,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.TOP,
          );
        }
        return;
      }

      // All checks passed - create user
      final userId = await _createUser(username);
      await _uploadLocalJournals(userId);
      // The provider was evaluated at app startup (before this row existed)
      // and cached the 'User' fallback — invalidate so HomeScreen re-fetches.
      ref.invalidate(currentUsernameProvider);
      // Likewise this cached `false` a moment ago, which is what routed us to
      // this screen. Without invalidating, HomeScreen re-renders straight back
      // to CreateUserScreen and signup appears to do nothing.
      ref.invalidate(hasProfileProvider);
      AnalyticsManager.logSignUp(
        method: SupabaseAuthManager.signInMethod ?? 'unknown',
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error: $e',
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Creates the caller's `profiles` row and returns their user id.
  ///
  /// The row's id must equal `auth.uid()` — the insert policy enforces it — so
  /// unlike the Firestore version there is no way to write a profile for
  /// anyone else, and no separate `userId` field to keep in sync.
  Future<String> _createUser(String username) async {
    final user = SupabaseAuthManager.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }
    await _db.createUser(userId: user.id, username: username);
    return user.id;
  }

  /// Upload journals written before signup (held in SharedPreferences).
  ///
  /// One bulk insert replaces the Firestore `WriteBatch`: same all-or-nothing
  /// guarantee, one round trip instead of N.
  Future<void> _uploadLocalJournals(String userId) async {
    final journals = SharedPreferencesManager.getJournals();
    if (journals.isEmpty) return;
    await _db.addJournalsToCollection(userId, journals);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: 32.0, right: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              const Text(
                'Pick a name.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.5,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'AvenirNext',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Subtitle
              const Text(
                'Tell me more about you.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'AvenirNext',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Username label
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Username',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              // Username input field
              TextField(
                controller: _usernameController,
                enabled: !_isLoading,
                autocorrect: false,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'name or nickname',
                  hintStyle: TextStyle(
                    color: Colors.white.withAlpha(76),
                    fontSize: 16,
                  ),
                  filled: false,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withAlpha(76),
                      width: 1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 76),
              // Start Journaling button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleStartJournaling,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFFB4E4E4,
                    ), // Light blue color
                    disabledBackgroundColor: const Color(
                      0xFFB4E4E4,
                    ).withAlpha(127),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                          : const Text(
                            'Start Journaling',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
