import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<int> getStudentCount() {
    return _firestore.collection('students').snapshots().map((snapshot) => snapshot.size);
  }

  Stream<int> getTeacherCount() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // Assuming we might have an 'isApproved' field or similar in the future, 
  // currently just returning 0 or checking for a specific status if it exists.
  // For now, let's say 'pending' teachers are those created but not verified? 
  // Or just return 0 if we don't have that logic yet.
  Stream<int> getPendingAppsCount() {
     // Placeholder logic: maybe users with role 'teacher' and status 'pending'
     // If status field doesn't exist, we'll return Stream.value(0)
     return Stream.value(0); 
  }
}
