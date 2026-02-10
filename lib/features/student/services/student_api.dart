import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/student_model.dart';

class StudentApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new student
  Future<void> addStudent(StudentModel student) async {
    try {
      await _firestore.collection('students').add(student.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Update student data (including marks)
  Future<void> updateStudent(StudentModel student) async {
    try {
      await _firestore.collection('students').doc(student.id).update(student.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Get students for a specific class/section
  Stream<List<StudentModel>> getStudentsByClass(String classId, String section) {
    return _firestore
        .collection('students')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
            .where((student) => student.section.toLowerCase() == section.toLowerCase())
            .toList());
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
      DocumentSnapshot doc = await _firestore.collection('students').doc(id).get();
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
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
            .toList());
  }
  // Get all students
  Stream<List<StudentModel>> getAllStudents() {
    return _firestore
        .collection('students')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
