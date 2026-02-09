import 'package:cloud_firestore/cloud_firestore.dart';

class FeesApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> processPayment(Map<String, dynamic> data) async {
    // Placeholder for fee payment
  }

  Stream<QuerySnapshot> getFees(String studentId) {
    return _firestore.collection('fees').where('studentId', isEqualTo: studentId).snapshots();
  }
}
