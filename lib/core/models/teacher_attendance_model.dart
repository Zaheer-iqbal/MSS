import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherAttendanceModel {
  final String id;
  final String teacherId;
  final String teacherName;
  final DateTime date;
  final String status; // 'Present', 'Absent'
  final DateTime timestamp;

  TeacherAttendanceModel({
    this.id = '',
    required this.teacherId,
    required this.teacherName,
    required this.date,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'teacherName': teacherName,
      'date': Timestamp.fromDate(date),
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory TeacherAttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return TeacherAttendanceModel(
      id: id,
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      status: map['status'] ?? 'Absent',
      timestamp: (map['timestamp'] as Timestamp? ?? map['date'] as Timestamp).toDate(),
    );
  }
}
