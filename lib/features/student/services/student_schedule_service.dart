import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/user_model.dart';

class StudentScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, String>>> getStudentSchedule(
    String classId,
    String section,
  ) {
    // We need to find all teachers and filter their schedules for this student's class/section
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .snapshots()
        .map((snapshot) {
          List<Map<String, String>> combinedSchedule = [];

          for (var doc in snapshot.docs) {
            final teacherRecord = UserModel.fromMap(doc.data());
            final teacherSchedule = teacherRecord.schedule;

            // Filter schedule entries matching this student's class and section
            for (var entry in teacherSchedule) {
              if (entry['classId'] == classId && entry['section'] == section) {
                // Add teacher name to the entry so parent knows who teaches it
                final richEntry = Map<String, String>.from(entry);
                richEntry['teacherName'] = teacherRecord.name;
                combinedSchedule.add(richEntry);
              }
            }
          }

          // Sort by Day and then Time (simple string sort for now)
          final dayOrder = {
            'Monday': 1,
            'Tuesday': 2,
            'Wednesday': 3,
            'Thursday': 4,
            'Friday': 5,
            'Saturday': 6,
            'Sunday': 7,
          };

          combinedSchedule.sort((a, b) {
            int dayCompare = (dayOrder[a['day']] ?? 0).compareTo(
              dayOrder[b['day']] ?? 0,
            );
            if (dayCompare != 0) return dayCompare;
            return (a['time'] ?? '').compareTo(b['time'] ?? '');
          });

          return combinedSchedule;
        });
  }
}
