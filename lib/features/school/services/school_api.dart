import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/student_model.dart';
import '../../../core/models/school_event_model.dart';
import '../../../core/services/notification_service.dart';

class SchoolApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<int> getStudentCount() {
    return _firestore
        .collection('students')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Stream<List<StudentModel>> getAllStudents() {
    return _firestore.collection('students').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<int> getTeacherCount() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Stream<Map<String, int>> getTodayOverallStudentAttendance() {
    final today = DateTime.now();

    return _firestore.collection('attendance').snapshots().map((snapshot) {
      int present = 0;
      int absent = 0;
      int late = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        if (date.year == today.year &&
            date.month == today.month &&
            date.day == today.day) {
          final status = data['status']?.toString().toLowerCase();
          if (status == 'present') {
            present++;
          } else if (status == 'absent') {
            absent++;
          } else if (status == 'late') {
            late++;
          }
        }
      }

      return {
        'present': present,
        'absent': absent,
        'late': late,
        'total': present + absent + late,
      };
    });
  }

  Stream<Map<String, int>> getOverallCumulativeStudentAttendance() {
    return _firestore.collection('attendance').snapshots().map((snapshot) {
      int present = 0;
      int absent = 0;
      int late = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase();
        if (status == 'present') {
          present++;
        } else if (status == 'absent') {
          absent++;
        } else if (status == 'late') {
          late++;
        }
      }

      return {
        'present': present,
        'absent': absent,
        'late': late,
        'total': present + absent + late,
      };
    });
  }

  Stream<Map<String, int>> getTodayOverallTeacherAttendance() {
    final today = DateTime.now();
    return _firestore.collection('teacher_attendance').snapshots().map((
      snapshot,
    ) {
      int present = 0;
      int absent = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        if (date.year == today.year &&
            date.month == today.month &&
            date.day == today.day) {
          final status = data['status']?.toString().toLowerCase();
          if (status == 'present') {
            present++;
          } else if (status == 'absent') {
            absent++;
          }
        }
      }

      return {'present': present, 'absent': absent, 'total': present + absent};
    });
  }

  Stream<Map<String, int>> getOverallCumulativeTeacherAttendance() {
    return _firestore.collection('teacher_attendance').snapshots().map((snapshot) {
      int present = 0;
      int absent = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase();
        if (status == 'present') {
          present++;
        } else if (status == 'absent') {
          absent++;
        }
      }

      return {
        'present': present,
        'absent': absent,
        'total': present + absent,
      };
    });
  }

  Stream<Map<String, double>> getOverallAcademicStats() {
    return _firestore.collection('students').snapshots().map((snapshot) {
      int count = 0;
      Map<String, int> gradeCounts = {'A': 0, 'B': 0, 'C': 0, 'D': 0, 'F': 0};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final finalMarks = data['finalTermMarks'] as Map?;
        if (finalMarks != null && finalMarks.isNotEmpty) {
          double sum = 0;
          for (var v in finalMarks.values) {
            sum += (v is num ? v.toDouble() : 0);
          }
          double avg = sum / finalMarks.length;
          count++;

          if (avg >= 80) {
            gradeCounts['A'] = (gradeCounts['A']!) + 1;
          } else if (avg >= 70) {
            gradeCounts['B'] = (gradeCounts['B']!) + 1;
          } else if (avg >= 60) {
            gradeCounts['C'] = (gradeCounts['C']!) + 1;
          } else if (avg >= 50) {
            gradeCounts['D'] = (gradeCounts['D']!) + 1;
          } else {
            gradeCounts['F'] = (gradeCounts['F']!) + 1;
          }
        }
      }

      return gradeCounts.map(
        (k, v) => MapEntry(k, count == 0 ? 0.0 : (v / count) * 100),
      );
    });
  }

  Stream<List<SchoolEventModel>> getEvents() {
    return _firestore
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SchoolEventModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> addEvent(SchoolEventModel event) async {
    await _firestore.collection('events').add(event.toMap());

    // Notify All
    await NotificationService().sendTopicNotification(
      topic: 'all',
      title: 'New School Event: ${event.title}',
      body: 'A new event has been scheduled for ${event.date.toString().split(' ')[0]}. Check the events tab for details!',
      data: {
        'type': 'event',
        'eventId': event.id,
      },
    );
  }

  Future<void> deleteEvent(String id) {
    return _firestore.collection('events').doc(id).delete();
  }

  Stream<int> getPendingAppsCount() {
    return Stream.value(0);
  }
}
