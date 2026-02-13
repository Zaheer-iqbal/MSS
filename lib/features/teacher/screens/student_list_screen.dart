import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/student_model.dart';
import '../../../core/services/auth_service.dart';
import '../../student/services/student_api.dart';
import 'student_profile_screen.dart';

class StudentListScreen extends StatefulWidget {
  final String? classId;
  final String? section;

  const StudentListScreen({super.key, this.classId, this.section});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final StudentApi _studentApi = StudentApi();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.classId != null
              ? 'Students: ${widget.classId}-${widget.section}'
              : 'Student Directory',
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by student name...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
          ),
          Expanded(
            child: Consumer<AuthService>(
              builder: (context, auth, _) {
                final user = auth.currentUser;
                final bool isTeacher =
                    user?.role == 'teacher' || user?.role == 'head_teacher';
                final List<Map<String, String>> assigned =
                    user?.assignedClasses ?? [];

                return StreamBuilder<List<StudentModel>>(
                  stream: _searchQuery.isEmpty
                      ? (widget.classId != null
                            ? _studentApi.getStudentsByClass(
                                widget.classId!,
                                widget.section!,
                              )
                            : (isTeacher
                                  ? _studentApi.getStudentsByMultipleClasses(
                                      assigned,
                                    )
                                  : _studentApi.getAllStudents()))
                      : _studentApi.searchStudents(_searchQuery),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    var students = snapshot.data ?? [];

                    // Filter search results if teacher
                    if (_searchQuery.isNotEmpty && isTeacher) {
                      students = students
                          .where(
                            (s) => assigned.any(
                              (c) =>
                                  c['classId'] == s.classId &&
                                  c['section'] == s.section,
                            ),
                          )
                          .toList();
                    }

                    if (students.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.group_off_outlined,
                              size: 60,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isTeacher && assigned.isEmpty
                                  ? 'No classes assigned to you.'
                                  : 'No students found.',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: students.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return _buildStudentCard(student);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // floatingActionButton removed as per request
    );
  }

  Widget _buildStudentCard(StudentModel student) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudentProfileScreen(student: student),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: student.imageUrl.isNotEmpty
                  ? (student.imageUrl.startsWith('http')
                            ? NetworkImage(student.imageUrl)
                            : MemoryImage(base64Decode(student.imageUrl)))
                        as ImageProvider
                  : null,
              child: student.imageUrl.isEmpty
                  ? Text(
                      student.name[0],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Roll No: ${student.rollNo}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
