import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import 'attendance_summary_screen.dart';
import 'marks_entry_screen.dart';
import 'attendance_screen.dart';

class ClassSelectionScreen extends StatelessWidget {
  final String assessmentType; // 'Assignment', 'Quiz', 'Exam'

  const ClassSelectionScreen({super.key, required this.assessmentType});

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building ClassSelectionScreen for $assessmentType'); // Debug print
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final classes = user?.assignedClasses ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Select Class for $assessmentType'),
        backgroundColor: AppColors.background,
      ),
      body: classes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.class_outlined, size: 60, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No classes found.',
                    style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: classes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final cls = classes[index];
                return _buildClassTile(context, cls['classId']!, cls['section']!);
              },
            ),
    );
  }

  Widget _buildClassTile(BuildContext context, String classId, String section) {
    return ListTile(
      onTap: () {
        if (assessmentType == 'Attendance') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceSummaryScreen(
                classId: classId,
                section: section,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MarksEntryScreen(
                classId: classId,
                section: section,
                assessmentType: assessmentType,
              ),
            ),
          );
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.school, color: AppColors.primary),
      ),
      title: Text(
        'Class $classId-$section',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
    );
  }
}
