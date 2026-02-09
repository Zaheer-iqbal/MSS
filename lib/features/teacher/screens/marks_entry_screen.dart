import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/student_model.dart';
import '../../student/services/student_api.dart';

class MarksEntryScreen extends StatefulWidget {
  final String classId;
  final String section;
  final String assessmentType;

  const MarksEntryScreen({
    super.key,
    required this.classId,
    required this.section,
    required this.assessmentType,
  });

  @override
  State<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends State<MarksEntryScreen> {
  final TextEditingController _assessmentNameController = TextEditingController();
  final Map<String, TextEditingController> _marksControllers = {};
  bool _isSaving = false;

  @override
  void dispose() {
    _assessmentNameController.dispose();
    for (var controller in _marksControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveMarks(List<StudentModel> students) async {
    if (_assessmentNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an Assessment Name (e.g., Math Quiz 1)')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final assessmentName = _assessmentNameController.text.trim();

    try {
      final api = StudentApi();
      for (var student in students) {
        final marksStr = _marksControllers[student.id]?.text.trim();
        if (marksStr != null && marksStr.isNotEmpty) {
          final updatedStudent = _updateStudentMarks(student, assessmentName, marksStr);
          await api.updateStudent(updatedStudent);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marks saved successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
        Navigator.pop(context); // Go back to dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving marks: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  StudentModel _updateStudentMarks(StudentModel student, String name, String marks) {
    // Create copies of maps
    final quizMarks = Map<String, dynamic>.from(student.quizMarks);
    final assignmentMarks = Map<String, dynamic>.from(student.assignmentMarks);
    final midTermMarks = Map<String, dynamic>.from(student.midTermMarks);
    final finalTermMarks = Map<String, dynamic>.from(student.finalTermMarks);

    // Update specific map based on type
    if (widget.assessmentType == 'Assignments') {
      assignmentMarks[name] = marks;
    } else if (widget.assessmentType == 'Quizzes') {
      quizMarks[name] = marks;
    } else if (widget.assessmentType == 'Exams') {
      // Simple logic: if name contains 'Mid', put in mid-term, else final
      if (name.toLowerCase().contains('mid')) {
        midTermMarks[name] = marks;
      } else {
        finalTermMarks[name] = marks;
      }
    }

    return StudentModel(
      id: student.id,
      name: student.name,
      rollNo: student.rollNo,
      classId: student.classId,
      section: student.section,
      parentEmail: student.parentEmail,
      fatherName: student.fatherName,
      phone: student.phone,
      address: student.address,
      imageUrl: student.imageUrl,
      createdAt: student.createdAt,
      quizMarks: quizMarks,
      assignmentMarks: assignmentMarks,
      midTermMarks: midTermMarks,
      finalTermMarks: finalTermMarks,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Enter ${widget.assessmentType} Marks'),
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _assessmentNameController,
              decoration: const InputDecoration(
                labelText: 'Assessment Name (e.g., Math Test 1)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<StudentModel>>(
              stream: StudentApi().getStudentsByClass(widget.classId, widget.section),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No students found in this class.'));
                }

                final students = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    // Initialize controller if needed
                    if (!_marksControllers.containsKey(student.id)) {
                      _marksControllers[student.id] = TextEditingController();
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              student.rollNo,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Roll No: ${student.rollNo}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _marksControllers[student.id],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Marks',
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving
            ? null
            : () async {
                final api = StudentApi();
                // We need to fetch current list to iterate
                // Ideally we shouldn't fetch again but for simplicity finding from stream source
                final students = await api.getStudentsByClass(widget.classId, widget.section).first;
                _saveMarks(students);
              },
        label: const Text('Save All Marks'),
        icon: const Icon(Icons.save),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
