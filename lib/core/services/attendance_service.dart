import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mark attendance for a single student
  Future<void> markAttendance(AttendanceRecord record) async {
    try {
      // Use date as part of the document ID to prevent duplicate marking for the same student on the same day
      String dateStr = "${record.date.year}-${record.date.month}-${record.date.day}";
      String docId = "${record.studentId}_$dateStr";

      await _firestore
          .collection('attendance')
          .doc(docId)
          .set(record.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Fetch attendance for a specific student (for Parents)
  Stream<List<AttendanceRecord>> getStudentAttendance(String studentId) {
    return _firestore
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Fetch attendance for a class on a specific date (for Teachers)
  Future<List<AttendanceRecord>> getClassAttendance(String classId, DateTime date) async {
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    QuerySnapshot snapshot = await _firestore
        .collection('attendance')
        .where('classId', isEqualTo: classId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    return snapshot.docs
        .map((doc) => AttendanceRecord.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }
}
