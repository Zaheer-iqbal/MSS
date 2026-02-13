import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher_attendance_model.dart';

class TeacherAttendanceService {
  final CollectionReference _attendanceCollection =
      FirebaseFirestore.instance.collection('teacher_attendance');

  Future<void> markAttendance(TeacherAttendanceModel attendance) async {
    // Generate a deterministic ID based on teacherId and date if no ID is provided
    // This prevents the "non-empty string" error and ensures only one record per day
    String docId = attendance.id;
    if (docId.isEmpty) {
      final dateStr = "${attendance.date.year}-${attendance.date.month}-${attendance.date.day}";
      docId = "${attendance.teacherId}_$dateStr";
    }
    await _attendanceCollection.doc(docId).set(attendance.toMap());
  }

  Stream<List<TeacherAttendanceModel>> getTeacherAttendance(String teacherId) {
    return _attendanceCollection
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TeacherAttendanceModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Future<TeacherAttendanceModel?> getAttendanceForDate(String teacherId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final querySnapshot = await _attendanceCollection
        .where('teacherId', isEqualTo: teacherId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return TeacherAttendanceModel.fromMap(
        querySnapshot.docs.first.data() as Map<String, dynamic>,
        querySnapshot.docs.first.id,
      );
    }
    return null;
  }
}
