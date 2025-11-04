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
        return JournalState.fromJson(doc.data().toString());
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
}
