import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movie_journal/features/home/screens/home.dart';
import 'package:movie_journal/firebase_manager.dart';
import 'package:movie_journal/shared_preferences_manager.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  /// Validate username with the following rules:
  /// 1. Only alphabets (a-z), numbers (0-9), underscore (_) and fullstop (.) allowed
  /// 2. Cannot contain only (_) and (.)
  /// 3. Cannot end with (.)
  String? _validateUsername(String username) {
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

    // Rule 3: Cannot end with "."
    if (username.endsWith('.')) {
      return 'Username cannot end with _ or .';
    }

    return null; // Valid
  }

  /// Check if username already exists in Firestore
  Future<bool> _checkUsernameExists(String username) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .limit(1)
              .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check username availability: $e');
    }
  }

  /// Handle the Start Journaling button press
  Future<void> _handleStartJournaling() async {
    final username = _usernameController.text.trim();

    // Validate username format
    final validationError = _validateUsername(username);
    if (validationError != null) {
      Fluttertoast.showToast(
        msg: validationError,
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if username already exists
      final exists = await _checkUsernameExists(username);
      if (exists) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Username already taken. Please choose another one.',
            backgroundColor: Colors.red,
            toastLength: Toast.LENGTH_LONG,
          );
        }
        return;
      }

      // All checks passed - create user
      var newUserDoc = await _createUser(username);
      await _uploadLocalJournals(newUserDoc);
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
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Create user function (to be implemented)
  Future<DocumentReference<Map<String, dynamic>>> _createUser(
    String username,
  ) async {
    var firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw Exception('No authenticated Firebase user found.');
    }
    // create user in Firestore
    var newUserDoc = _firestore.collection('users').doc(firebaseUser.uid);
    await newUserDoc.set({
      'username': username,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return newUserDoc;

    // Fluttertoast.showToast(
    //   msg: 'Username "$username" is available! Creating user...',
    //   backgroundColor: Colors.green,
    // );
  }

  Future<void> _uploadLocalJournals(
    DocumentReference<Map<String, dynamic>> userDoc,
  ) async {
    // upload existing journals in SharedPreferences to Firestore under this user
    var journals = SharedPreferencesManager.getJournals();
    WriteBatch batch = _firestore.batch();
    for (var journal in journals) {
      Map<String, dynamic> newJournalData = journal.toMap();
      newJournalData['userId'] = userDoc.id;
      batch.set(_firestore.collection('journals').doc(), newJournalData);
    }
    await batch.commit();
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
                  'user name',
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
