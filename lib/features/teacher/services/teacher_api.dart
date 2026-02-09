import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/user_model.dart';

class TeacherApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all teachers
  Stream<List<UserModel>> getAllTeachers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  // Update teacher data (schedule, image, etc.)
  Future<void> updateTeacherProfile(UserModel teacher) async {
    try {
      await _firestore.collection('users').doc(teacher.uid).update(teacher.toMap());
    } catch (e) {
      rethrow;
    }
  }
}
