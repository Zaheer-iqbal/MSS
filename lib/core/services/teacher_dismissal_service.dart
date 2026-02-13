import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherDismissalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save a dismissed session for a specific day
  Future<void> saveDismissedSession(String teacherId, String sessionKey) async {
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month}-${now.day}";
    final docId = "${teacherId}_$dateStr";

    await _firestore.collection('teacher_dismissed_sessions').doc(docId).set({
      'teacherId': teacherId,
      'date': dateStr,
      'dismissedKeys': FieldValue.arrayUnion([sessionKey]),
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get all dismissed session keys for a teacher today
  Future<Set<String>> getDismissedSessions(String teacherId) async {
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month}-${now.day}";
    final docId = "${teacherId}_$dateStr";

    final doc = await _firestore
        .collection('teacher_dismissed_sessions')
        .doc(docId)
        .get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['dismissedKeys'] != null) {
        return Set<String>.from(data['dismissedKeys']);
      }
    }
    return {};
  }
}
