import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../teacher/services/teacher_api.dart';
import '../../../core/services/teacher_attendance_service.dart';
import '../../../../core/models/teacher_attendance_model.dart';
import 'manage_teacher_profile_screen.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  final teacherApi = TeacherApi();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.searchStaffHint,
        border: InputBorder.none,
        hintStyle: const TextStyle(color: Colors.white70),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
              _searchQuery = '';
            });
          },
        ),
      ];
    }

    return [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          setState(() {
            _isSearching = true;
          });
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSearching ? _buildSearchField() : Text(AppLocalizations.of(context)!.schoolStaff),
        actions: _buildAppBarActions(),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: teacherApi.getAllTeachers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.noStaffFound));
          }

          final teachers = snapshot.data!.where((teacher) {
            final nameMatch = teacher.name.toLowerCase().contains(_searchQuery.toLowerCase());
            return nameMatch;
          }).toList();

          if (teachers.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.noMatchingStaffFound));
          }

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
                      StreamBuilder<TeacherAttendanceModel?>(
                        stream: teacherAttendanceService.getAttendanceStreamForDate(teacher.uid, DateTime.now()),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2));
                          }
                          final attendance = snapshot.data;
                          final status = attendance?.status ?? 'Not Marked';
                          final isPresent = status == 'present';
                          final isAbsent = status == 'absent';
                          final statusColor = isPresent ? Colors.green : (isAbsent ? Colors.red : Colors.orange);
                          final statusIcon = isPresent ? Icons.check_circle_rounded : (isAbsent ? Icons.cancel_rounded : Icons.help_outline_rounded);

                          return Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(statusIcon, size: 24, color: statusColor),
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
                    AppLocalizations.of(context)!.classesAssigned(teacher.assignedClasses.length),
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
