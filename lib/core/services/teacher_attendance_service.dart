import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher_attendance_model.dart';

class TeacherAttendanceService {
  final CollectionReference _attendanceCollection = FirebaseFirestore.instance
      .collection('teacher_attendance');

  String _getDocId(String teacherId, DateTime date) {
    return "${teacherId}_${date.year}-${date.month}-${date.day}";
  }

  Future<void> markAttendance(TeacherAttendanceModel attendance) async {
    final docId = _getDocId(attendance.teacherId, attendance.date);
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

  Stream<TeacherAttendanceModel?> getAttendanceStreamForDate(
    String teacherId,
    DateTime date,
  ) {
    final docId = _getDocId(teacherId, date);
    return _attendanceCollection.doc(docId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return TeacherAttendanceModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    });
  }

  Future<TeacherAttendanceModel?> getAttendanceForDate(
    String teacherId,
    DateTime date,
  ) async {
    final docId = _getDocId(teacherId, date);
    final doc = await _attendanceCollection.doc(docId).get();

    if (doc.exists && doc.data() != null) {
      return TeacherAttendanceModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }
    return null;
  }
}
