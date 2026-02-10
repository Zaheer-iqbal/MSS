import 'package:flutter/material.dart';
import 'package:mss/features/auth/screens/role_selection_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/student_model.dart';
import '../../../core/services/auth_service.dart';
import '../../student/services/student_api.dart';
import '../../teacher/screens/attendance_summary_screen.dart';
import 'child_progress.dart';

class ParentDashboardScreen extends StatefulWidget {
  final StudentModel student;
  const ParentDashboardScreen({super.key, required this.student});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  
  final _studentApi = StudentApi();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StudentModel?>(
      stream: _studentApi.streamStudentById(widget.student.id),
      builder: (context, snapshot) {
        final student = snapshot.data ?? widget.student;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Parent Portal'),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context, 
                    MaterialPageRoute(builder: (context) => const RoleSelectionScreen()), 
                    (route) => false
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildStudentProfileCard(student),
                const SizedBox(height: 24),
                _buildAttendanceCard(student),
                const SizedBox(height: 24),
                _buildAcademicSection(student),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildStudentProfileCard(StudentModel student) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.parentRole, Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.parentRole.withOpacity(0.3), 
            blurRadius: 10, 
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            backgroundImage: student.imageUrl.isNotEmpty ? NetworkImage(student.imageUrl) : null,
            child: student.imageUrl.isEmpty ? const Icon(Icons.person, size: 36, color: AppColors.parentRole) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Class ${student.classId}-${student.section} | Roll No: ${student.rollNo}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(StudentModel student) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChildProgress(
              studentId: student.id,
              studentName: student.name,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.parentRole),
                SizedBox(width: 8),
                Text('Attendance Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Spacer(),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 24),
            const Text("Tap to view full attendance history", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicSection(StudentModel student) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(24),
         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school, color: AppColors.parentRole),
              SizedBox(width: 8),
              Text("Academic Updates", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          if (student.assignmentMarks.isEmpty && 
              student.quizMarks.isEmpty && 
              student.midTermMarks.isEmpty &&
              student.finalTermMarks.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No academic records yet.", style: TextStyle(color: Colors.grey)),
              )),
          _buildMarksCategory("Assignments", student.assignmentMarks),
          _buildMarksCategory("Quizzes", student.quizMarks),
          _buildMarksCategory("Mid-term", student.midTermMarks),
          _buildMarksCategory("Final-term", student.finalTermMarks),
        ],
      ),
    );
  }

  Widget _buildMarksCategory(String title, Map<String, dynamic> marks) {
    if (marks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        ...marks.entries.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.parentRole.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  e.value.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.parentRole),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 8),
        const Divider(),
      ],
    );
  }
}
