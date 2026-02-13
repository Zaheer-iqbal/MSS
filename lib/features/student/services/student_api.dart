import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/student_model.dart';

class StudentApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new student
  Future<String> addStudent(StudentModel student) async {
    try {
      final docRef = await _firestore
          .collection('students')
          .add(student.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Update student data (including marks)
  Future<void> updateStudent(StudentModel student) async {
    try {
      await _firestore
          .collection('students')
          .doc(student.id)
          .update(student.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Get students for a specific class/section
  Stream<List<StudentModel>> getStudentsByClass(
    String classId,
    String section,
  ) {
    return _firestore
        .collection('students')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
              .where(
                (student) =>
                    student.section.toLowerCase() == section.toLowerCase(),
              )
              .toList(),
        );
  }

  // Get students for multiple classes/sections (for teachers)
  Stream<List<StudentModel>> getStudentsByMultipleClasses(
    List<Map<String, String>> assigned,
  ) {
    if (assigned.isEmpty) return Stream.value([]);

    return _firestore.collection('students').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
          .where(
            (student) => assigned.any(
              (c) =>
                  c['classId'] == student.classId &&
                  c['section'].toString().toLowerCase() ==
                      student.section.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  // Get a single student by ID as a stream
  Stream<StudentModel?> streamStudentById(String id) {
    return _firestore.collection('students').doc(id).snapshots().map((doc) {
      if (doc.exists) {
        return StudentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  // Get a single student by ID
  Future<StudentModel?> getStudentById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('students')
          .doc(id)
          .get();
      if (doc.exists) {
        return StudentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Search students by name
  Stream<List<StudentModel>> searchStudents(String query) {
    return _firestore
        .collection('students')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get all students
  Stream<List<StudentModel>> getAllStudents() {
    return _firestore
        .collection('students')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Delete student and all associated data
  Future<void> deleteStudent(String studentId) async {
    try {
      final batch = _firestore.batch();

      // 1. Delete student record
      batch.delete(_firestore.collection('students').doc(studentId));

      // 2. Delete linked parent record in 'users' collection
      batch.delete(_firestore.collection('users').doc(studentId));

      // 3. Delete attendance records
      final attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .get();

      for (var doc in attendanceSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}
