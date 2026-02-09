import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final String? id;
  final String studentId;
  final String studentName;
  final DateTime date;
  final String status; // 'present', 'absent', 'late'
  final String markedBy; // Teacher UID
  final String classId;

  AttendanceRecord({
    this.id,
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.status,
    required this.markedBy,
    required this.classId,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'date': Timestamp.fromDate(date),
      'status': status,
      'markedBy': markedBy,
      'classId': classId,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceRecord(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      status: map['status'] ?? 'present',
      markedBy: map['markedBy'] ?? '',
      classId: map['classId'] ?? '',
    );
  }
}
