import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final String? id;
  final String studentId;
  final String studentName;
  final DateTime date;
  final String status; // 'present', 'absent', 'late'
  final String markedBy; // Teacher UID
  final String classId;
  final String subject;

  AttendanceRecord({
    this.id,
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.status,
    required this.markedBy,
    required this.classId,
    required this.subject,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'date': Timestamp.fromDate(date),
      'status': status,
      'markedBy': markedBy,
      'classId': classId,
      'subject': subject,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDate;
    try {
      if (map['date'] is Timestamp) {
        parsedDate = (map['date'] as Timestamp).toDate();
      } else if (map['date'] is String) {
        parsedDate = DateTime.parse(map['date']);
      } else {
        parsedDate = DateTime.now();
      }
    } catch (e) {
      parsedDate = DateTime.now();
    }

    return AttendanceRecord(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      date: parsedDate,
      status: map['status'] ?? 'present',
      markedBy: map['markedBy'] ?? '',
      classId: map['classId'] ?? '',
      subject: map['subject'] ?? '',
    );
  }
}
