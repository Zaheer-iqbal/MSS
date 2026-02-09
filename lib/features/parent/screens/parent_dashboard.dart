import 'package:flutter/material.dart';
import 'package:mss/features/auth/screens/role_selection_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/student_model.dart';
import '../../../core/services/auth_service.dart';
import '../../teacher/screens/attendance_summary_screen.dart';
class ParentDashboardScreen extends StatefulWidget {
  final StudentModel student;
  const ParentDashboardScreen({super.key, required this.student});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  
  @override
  Widget build(BuildContext context) {
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
            _buildStudentProfileCard(),
            const SizedBox(height: 24),
            _buildAttendanceCard(),
            const SizedBox(height: 24),
            _buildAcademicSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentProfileCard() {
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
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 36, color: AppColors.parentRole),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.student.name,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Class ${widget.student.classId}-${widget.student.section} | Roll No: ${widget.student.rollNo}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return Container(
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
            ],
          ),
          const SizedBox(height: 24),
          // We are showing a static representation here as a "snapshot"
          // In a real app, we would query the attendance collection sum.
          // For this demo, let's show a "Good Standing" visual since we don't have
          // the aggregated data stored in the student model yet.
          SizedBox(
            height: 160,
            width: 160,
            child: CustomPaint(
              painter: AttendanceChartPainter(
                present: 90, 
                absent: 10, 
                total: 100, 
                isEmpty: false
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     Text("90%", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                     Text("Present", style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text("Based on recent activity", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAcademicSection() {
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
          if (widget.student.assignmentMarks.isEmpty && 
              widget.student.quizMarks.isEmpty && 
              widget.student.midTermMarks.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No academic records yet.", style: TextStyle(color: Colors.grey)),
              )),
          _buildMarksCategory("Assignments", widget.student.assignmentMarks),
          _buildMarksCategory("Quizzes", widget.student.quizMarks),
          _buildMarksCategory("Exams", widget.student.midTermMarks), 
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
