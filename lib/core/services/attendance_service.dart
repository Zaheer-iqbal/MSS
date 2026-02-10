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
        .snapshots()
        .map((snapshot) {
          final records = snapshot.docs
            .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
            .toList();
          // Sort in memory to avoid needing a Firestore index for equality + orderBy
          records.sort((a, b) => b.date.compareTo(a.date));
          return records;
        });
  }

  // Fetch attendance for a class on a specific date (for Teachers)
  Future<List<AttendanceRecord>> getClassAttendance(String classId, DateTime date) async {
    try {
      // We fetch by classId only to avoid the composite index error for (classId + date range)
      // This is a temporary fix to make the app work immediately for the user.
      QuerySnapshot snapshot = await _firestore
          .collection('attendance')
          .where('classId', isEqualTo: classId)
          .get();

      final allRecords = snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Filter by date in memory
      return allRecords.where((record) {
        return record.date.year == date.year &&
               record.date.month == date.month &&
               record.date.day == date.day;
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}
