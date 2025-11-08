import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movie_journal/features/journal/controllers/journal.dart';

class FirestoreManager {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<JournalState>> getJournalsCollection(String userId) async {
    var documents =
        (await _db
                .collection('journals')
                .where('userId', isEqualTo: userId)
                .get())
            .docs;
    if (documents.isNotEmpty) {
      return documents.map((doc) {
        final data = doc.data();
        // Remove userId field as JournalState doesn't expect it
        data.remove('userId');
        // Add the Firestore document ID
        data['id'] = doc.id;
        return JournalState.fromJson(jsonEncode(data));
      }).toList();
    }
    return [];
  }

  Future<List<DocumentReference<Map<String, dynamic>>>> addJournalsToCollection(
    String userId,
    List<JournalState> journals,
  ) async {
    final collectionRef = _db.collection('journals');
    final docRefList = [] as List<DocumentReference<Map<String, dynamic>>>;

    for (var journal in journals) {
      final docRef = await collectionRef.add(journal.toMap());
      docRefList.add(docRef);
    }

    return docRefList;
  }

  /// Add a single journal to Firestore
  ///
  /// Parameters:
  /// - [userId]: The user ID to associate with the journal
  /// - [journal]: The journal to save
  ///
  /// Returns the DocumentReference of the created journal
  Future<DocumentReference<Map<String, dynamic>>> addJournal(
    String userId,
    JournalState journal,
  ) async {
    final journalData = journal.toMap();
    journalData['userId'] = userId;
    return await _db.collection('journals').add(journalData);
  }

  /// Create a user document in the users collection
  ///
  /// Parameters:
  /// - [userId]: Firebase user ID (UID)
  /// - [username]: Custom username for the user
  ///
  /// Returns the DocumentReference of the created user document
  ///
  /// Example:
  /// ```dart
  /// final firestoreManager = FirestoreManager();
  /// await firestoreManager.createUser(
  ///   userId: 'firebase_uid_123',
  ///   username: 'moviefan42',
  /// );
  /// ```
  Future<DocumentReference<Map<String, dynamic>>> createUser({
    required String userId,
    required String username,
  }) async {
    final userDoc = _db.collection('users').doc(userId);

    await userDoc.set({
      'userId': userId,
      'username': username,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return userDoc;
  }

  /// Check if a user document exists
  ///
  /// Returns true if the user document exists, false otherwise
  Future<bool> userExists(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    return userDoc.exists;
  }

  /// Get user document data
  ///
  /// Returns a Map with user data or null if user doesn't exist
  Future<Map<String, dynamic>?> getUser(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    return userDoc.data();
  }

  /// Update username for a user
  ///
  /// Updates only the username field in the user document
  Future<void> updateUsername({
    required String userId,
    required String username,
  }) async {
    await _db.collection('users').doc(userId).update({
      'username': username,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
