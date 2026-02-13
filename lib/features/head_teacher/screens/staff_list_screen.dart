import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../teacher/services/teacher_api.dart';
import '../../../core/services/teacher_attendance_service.dart';
import '../../../../core/models/teacher_attendance_model.dart';
import 'manage_teacher_profile_screen.dart';

class StaffListScreen extends StatelessWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final teacherApi = TeacherApi();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('School Staff'),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: teacherApi.getAllTeachers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No staff members found'));
          }

          final teachers = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: teachers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final teacher = teachers[index];
              return _StaffCard(teacher: teacher);
            },
          );
        },
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final UserModel teacher;
  const _StaffCard({required this.teacher});

  @override
  Widget build(BuildContext context) {
    final teacherAttendanceService = TeacherAttendanceService();

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ManageTeacherProfileScreen(teacher: teacher),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.teacherRole.withValues(alpha: 0.1),
              backgroundImage: teacher.imageUrl.isNotEmpty
                  ? (teacher.imageUrl.startsWith('http')
                      ? NetworkImage(teacher.imageUrl)
                      : MemoryImage(base64Decode(teacher.imageUrl)))
                  : null,
              child: teacher.imageUrl.isEmpty
                  ? Text(teacher.name[0],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.teacherRole))
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          teacher.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                      FutureBuilder<TeacherAttendanceModel?>(
                        future: teacherAttendanceService.getAttendanceForDate(teacher.uid, DateTime.now()),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2));
                          }
                          final attendance = snapshot.data;
                          final status = attendance?.status ?? 'Not Marked';
                          Color statusColor = Colors.orange;
                          if (status == 'present') statusColor = Colors.green;
                          if (status == 'absent') statusColor = Colors.red;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Text(
                    teacher.email,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${teacher.assignedClasses.length} Classes Assigned',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
