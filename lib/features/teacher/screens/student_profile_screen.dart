import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/student_model.dart';
import '../../../core/services/auth_service.dart';
import '../../student/services/student_api.dart';
import '../../teacher/screens/attendance_summary_screen.dart';
import '../../../core/services/attendance_service.dart';
import '../../../core/models/attendance_model.dart';
import 'manage_student_screen.dart';
import 'update_result_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../chat/services/chat_service.dart';

class StudentProfileScreen extends StatefulWidget {
  final StudentModel student;
  const StudentProfileScreen({super.key, required this.student});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _studentApi = StudentApi();
  final _attendanceService = AttendanceService();
  String? _userRole;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _userRole = authService.currentUser?.role;
  }

  // Removed unused _updateMarks helper as logic is moved to UpdateResultScreen

  // Removed _showEditor in favor of UpdateResultScreen

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StudentModel?>(
      stream: _studentApi.streamStudentById(widget.student.id),
      builder: (context, snapshot) {
        final student = snapshot.data ?? widget.student;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(student),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildProfileHeader(student),
                      const SizedBox(height: 32),
                      _buildAttendanceSection(student),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text('Academic Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Select a card below to manage academic records.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      ),
                      const SizedBox(height: 24),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        children: [
                          _buildManagementCard(student, 'Quizzes', Icons.quiz, Colors.blue, student.quizMarks),
                          _buildManagementCard(student, 'Assignments', Icons.assignment, Colors.green, student.assignmentMarks),
                          _buildManagementCard(student, 'Mid-term', Icons.analytics, Colors.orange, student.midTermMarks),
                          _buildManagementCard(student, 'Final-term', Icons.workspace_premium, Colors.purple, student.finalTermMarks),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildAcademicSummary(student),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildAttendanceSection(StudentModel student) {
    return StreamBuilder<List<AttendanceRecord>>(
      stream: _attendanceService.getStudentAttendance(student.id),
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];
        int present = records.where((r) => r.status == 'present').length;
        int absent = records.where((r) => r.status == 'absent').length;
        int total = records.length;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                   Icon(Icons.bar_chart, color: AppColors.primary),
                   SizedBox(width: 8),
                   Text('Attendance Graph', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: CustomPaint(
                      painter: AttendanceChartPainter(
                        present: present.toDouble(),
                        absent: absent.toDouble(),
                        total: total == 0 ? 1 : total.toDouble(),
                        isEmpty: total == 0,
                      ),
                      child: Center(
                        child: Text(
                          total == 0 ? "0%" : "${(present / total * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatLite('Present', present.toString(), Colors.green),
                        const SizedBox(height: 8),
                        _buildStatLite('Absent', absent.toString(), Colors.red),
                        const SizedBox(height: 8),
                        _buildStatLite('Total Days', total.toString(), Colors.blue),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatLite(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildSliverAppBar(StudentModel student) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
    );
  }

  Widget _buildProfileHeader(StudentModel student) {
    return InkWell(
      onTap: () => _showStudentDetails(student),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: student.imageUrl.isNotEmpty ? NetworkImage(student.imageUrl) : null,
                  child: student.imageUrl.isEmpty 
                    ? Text(student.name[0], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary))
                    : null,
                ),
              ),
              if (student.phone.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.phone, size: 14, color: Colors.white),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        student.name, 
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_userRole == 'teacher' || _userRole == 'head_teacher' || _userRole == 'school')
                      Row(
                        children: [
                          _buildSmallChatAction(
                            icon: Icons.message_outlined, 
                            color: AppColors.primary, 
                            onTap: () => _messageUser(context, student.email, student.name, 'Student'),
                          ),
                          const SizedBox(width: 8),
                          _buildSmallChatAction(
                            icon: Icons.family_restroom_outlined, 
                            color: Colors.orange, 
                            onTap: () => _messageUser(context, student.parentEmail, '${student.fatherName} (Parent)', 'Parent'),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: #${student.rollNo}', 
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Class ${student.classId} - ${student.section}', 
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  void _showStudentDetails(StudentModel student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Complete Profile Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildDetailedInfo(student),
                    const SizedBox(height: 32),
                    if (_userRole == 'teacher' || _userRole == 'school' || _userRole == 'head_teacher')
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context); // Close sheet
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ManageStudentScreen(student: student)),
                            );
                          },
                          icon: const Icon(Icons.edit, size: 20),
                          label: const Text('Edit Student Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallChatAction({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildDetailedInfo(StudentModel student) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.email_outlined, 'Student Email', student.email),
          _divider(),
          _buildInfoRow(Icons.person_pin_outlined, 'Father\'s Name', student.fatherName),
          _divider(),
          _buildInfoRow(Icons.phone_outlined, 'Parent Phone', student.phone),
          _divider(),
          _buildInfoRow(Icons.alternate_email, 'Parent Email', student.parentEmail),
          _divider(),
          _buildInfoRow(Icons.lock_outline, 'Parent Password', student.parentPassword),
          _divider(),
          _buildInfoRow(Icons.location_on_outlined, 'Address', student.address),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 32, color: Colors.black.withValues(alpha: 0.05));

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(value.isNotEmpty ? value : 'Not provided', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }

  Widget _buildAcademicSummary(StudentModel student) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Academic Performance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        if (student.remarks.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.comment_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('Teacher Remarks', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(student.remarks, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        _buildSummaryCard('Quizzes', student.quizMarks, Colors.blue),
        const SizedBox(height: 16),
        _buildSummaryCard('Assignments', student.assignmentMarks, Colors.green),
        const SizedBox(height: 16),
        _buildSummaryCard('Mid-term Exams', student.midTermMarks, Colors.orange),
        const SizedBox(height: 16),
        _buildSummaryCard('Final-term Exams', student.finalTermMarks, Colors.purple),
      ],
    );
  }

  Widget _buildSummaryCard(String title, Map<String, dynamic> marks, Color color) {
    if (marks.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              const Spacer(),
              Text('${marks.length} Subjects', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const Divider(height: 24),
          ...marks.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildManagementCard(StudentModel student, String title, IconData icon, Color color, Map<String, dynamic> data) {
    bool canEdit = _userRole == 'teacher' || _userRole == 'school' || _userRole == 'head_teacher';
    
    return InkWell(
      onTap: canEdit ? () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UpdateResultScreen(
            student: student,
            initialCategory: title,
          ),
        ),
      ) : null,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, 
                 textAlign: TextAlign.center,
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
                 style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text('${data.length} Records', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // Message Action Helper
  void _messageUser(BuildContext context, String email, String name, String userType) async {
    final chatService = ChatService();
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Finding $userType account...'), duration: const Duration(seconds: 1)));
    
    final uid = await chatService.getUserIdByEmail(email);
    
    if (uid != null) {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              otherUserId: uid,
              otherUserName: name,
              otherUserImage: '', // Can be fetched if needed
            ),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$userType account not found for email: $email')));
      }
    }
  }
}
