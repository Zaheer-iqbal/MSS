import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../teacher/services/teacher_api.dart';
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
              return _buildStaffCard(context, teacher);
            },
          );
        },
      ),
    );
  }

  Widget _buildStaffCard(BuildContext context, UserModel teacher) {
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
              backgroundImage: teacher.imageUrl.isNotEmpty ? NetworkImage(teacher.imageUrl) : null,
              child: teacher.imageUrl.isEmpty 
                ? Text(teacher.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.teacherRole))
                : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
