import 'package:cloud_firestore/cloud_firestore.dart';

class NoticesApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createNotice(Map<String, dynamic> data) async {
    // Placeholder for notice creation
  }

  Stream<QuerySnapshot> getNotices() {
    return _firestore
        .collection('notices')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
